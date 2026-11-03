"""Offline release checks. Passing does not certify App Store approval."""
import argparse
import ipaddress
import plistlib
from pathlib import Path
import re
import subprocess
from urllib.parse import urlsplit


def public_https(value):
    if not isinstance(value, str) or any(c.isspace() for c in value):
        return False
    try:
        url = urlsplit(value)
        host = (url.hostname or "").lower().rstrip(".")
        if url.scheme != "https" or not host or url.username or url.password:
            return False
        if url.port not in (None, 443):
            return False
        if host == "localhost" or host.endswith((".localhost", ".local", ".invalid", ".test")):
            return False
        if host in ("example.com", "example.org", "example.net") or host.endswith((".example.com", ".example.org", ".example.net")):
            return False
        try:
            return ipaddress.ip_address(host).is_global
        except ValueError:
            return "." in host
    except ValueError:
        return False


def contact_issues(info):
    issues = []
    for key, label in (("SleeperLivePrivacyPolicyURL", "Privacy-policy URL"), ("SleeperLiveSupportURL", "Support URL")):
        if not public_https(info.get(key)):
            issues.append(f"{label} is missing or is not a public HTTPS destination.")
    email = info.get("SleeperLiveSupportEmail", "")
    if not isinstance(email, str) or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        issues.append("Support email is missing or malformed.")
    return issues


def manifest_issues(manifest):
    issues = []
    if manifest.get("NSPrivacyTracking") is not False:
        issues.append("Tracking declaration differs from the reviewed no-tracking configuration.")
    rows = manifest.get("NSPrivacyCollectedDataTypes", [])
    if not isinstance(rows, list):
        return issues + ["Collected-data declarations must be an array."]
    required = {"NSPrivacyCollectedDataType" + name for name in ("UserID", "DeviceID", "OtherUserContent", "GameplayContent", "ProductInteraction")}
    actual = set()
    for row in rows:
        if not isinstance(row, dict):
            issues.append("Malformed collected-data declaration.")
            continue
        category = row.get("NSPrivacyCollectedDataType")
        if not isinstance(category, str):
            issues.append("Collected-data declaration has no category.")
            continue
        if category in actual:
            issues.append("Duplicate collected-data category: " + category)
        actual.add(category)
        if row.get("NSPrivacyCollectedDataTypeTracking") is not False:
            issues.append("A category is missing the reviewed no-tracking declaration.")
        if not isinstance(row.get("NSPrivacyCollectedDataTypeLinked"), bool):
            issues.append("A category has no linked-data Boolean.")
        purposes = row.get("NSPrivacyCollectedDataTypePurposes")
        if not isinstance(purposes, list) or not purposes:
            issues.append("A category has no collection purpose.")
    if not required.issubset(actual):
        issues.append("Known retained-data categories are missing from the manifest.")
    reasons = manifest.get("NSPrivacyAccessedAPITypes", [])
    if not isinstance(reasons, list) or not any(isinstance(row, dict) and row.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults" and "CA92.1" in row.get("NSPrivacyAccessedAPITypeReasons", []) for row in reasons):
        issues.append("UserDefaults reason CA92.1 is missing.")
    return issues


def distribution_issues(entitlements):
    issues = []
    if entitlements.get("aps-environment") != "production":
        issues.append("Distribution app does not have production push entitlement.")
    if entitlements.get("com.apple.developer.devicecheck.appattest-environment") != "production":
        issues.append("Distribution app does not have production App Attest entitlement.")
    if entitlements.get("get-task-allow") is True:
        issues.append("Distribution app allows debugger attachment.")
    return issues


def entitlement_issues(data):
    try:
        entitlements = plistlib.loads(data)
        if not isinstance(entitlements, dict):
            raise ValueError("Expected signing dictionary")
        return distribution_issues(entitlements)
    except (ValueError, plistlib.InvalidFileException, TypeError):
        return ["Signing tool returned no readable entitlements; verify signing-tool access before assessing distribution signing."]


def read_plist(path):
    with path.open("rb") as stream:
        value = plistlib.load(stream)
    if not isinstance(value, dict):
        raise ValueError("Property list must contain a dictionary: " + str(path))
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--archive", type=Path, help="Optional distribution .xcarchive to inspect offline")
    parser.add_argument("--require-distribution-signing", action="store_true", help="Treat development signing as a blocker; use only when checking a distribution-signed archive")
    args = parser.parse_args()
    if args.require_distribution_signing and not args.archive:
        parser.error("--require-distribution-signing requires --archive")
    try:
        source_info = read_plist(args.project / "AppInfo.plist")
        source_manifest = read_plist(args.project / "SleeperLive/PrivacyInfo.xcprivacy")
        issues = contact_issues(source_info) + manifest_issues(source_manifest)
        if args.archive:
            apps = list((args.archive / "Products/Applications").glob("*.app"))
            if len(apps) != 1:
                raise ValueError("Archive must contain exactly one top-level app.")
            app = apps[0]
            info = read_plist(app / "Info.plist")
            issues += contact_issues(info) + manifest_issues(read_plist(app / "PrivacyInfo.xcprivacy"))
            if info.get("NSSupportsLiveActivities") is not True:
                issues.append("Archived app does not enable Live Activities.")
            for key in ("SleeperLivePrivacyPolicyURL", "SleeperLiveSupportURL", "SleeperLiveSupportEmail"):
                if source_info.get(key) != info.get(key):
                    issues.append("Archive differs from source configuration: " + key)
            signed = subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], capture_output=True)
            if signed.returncode:
                issues.append("Archive code-signature verification failed.")
            result = subprocess.run(["codesign", "--display", "--entitlements", ":-", str(app)], capture_output=True)
            if result.returncode:
                issues.append("Could not inspect archive signing entitlements.")
            else:
                signing = entitlement_issues(result.stdout)
                if args.require_distribution_signing or not result.stdout or any("no readable entitlements" in finding for finding in signing):
                    issues += signing
                else:
                    for finding in signing:
                        print("SIGNING NOTE:", finding)
                    if signing:
                        print("Development-signed archives may be re-signed during App Store export; these notes do not alone mean archive creation failed.")
    except (OSError, ValueError, plistlib.InvalidFileException, TypeError) as error:
        print("CHECK FAILED:", error)
        return 1
    for issue in dict.fromkeys(issues):
        print("BLOCKER:", issue)
    print("Not checked: public URL availability/content, Railway configuration, privacy-answer accuracy, physical-device behavior, screenshots, or content rights.")
    if not args.archive:
        print("No distribution archive supplied; signing and archive checks remain pending.")
    print("Release checks need attention." if issues else "Selected checks passed; this is not App Store approval.")
    return 1 if issues else 0


if __name__ == "__main__":
    raise SystemExit(main())
