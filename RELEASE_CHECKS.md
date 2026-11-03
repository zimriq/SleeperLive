# Local App Store checks

Run from the iOS repository:

```bash
python3 scripts/check_release.py
```

This performs offline checks of the configured privacy/support destinations, support email, and the privacy manifest. It returns exit code 1 for blockers. The current missing privacy-policy URL is an expected blocker; do not insert a placeholder to silence it.

After creating a distribution archive in Xcode, inspect it with:

```bash
python3 scripts/check_release.py --archive "/absolute/path/to/SleeperLive.xcarchive"
```

Archive mode checks bundled metadata/manifest, contact configuration, Live Activity support and code signature. It also reports development push/App Attest or debugger entitlements as signing notes. A normal local archive may be development-signed before Xcode re-signs it during App Store distribution; development signing is not itself a failed archive.

To make development-signing findings blockers when inspecting an archive you expect to already be distribution-signed, add `--require-distribution-signing`. This option requires --archive. Do not change the source development push entitlement merely to silence signing notes. Verify the final distribution export/TestFlight path in Xcode and on a physical device. An unreadable signing response is always reported as a check failure rather than parsed as an empty property list.

Run the checker's tests:

```bash
python3 -m unittest discover -s scripts -p 'test_release_checks.py'
```

The checker does not contact the website or server, read deployment secrets, or modify any configuration. Passing only confirms the selected checks. It does not prove that a policy page is reachable or accurate, all SDK declarations are complete, the widget signature is accepted by App Store validation, push delivery works, or the submission will be approved. Review Xcode's archive privacy report and perform physical-device and live-service checks separately.

The server-side change ledger and Railway verification plan are in `PRE_APP_STORE_SERVER_REVIEW.md` in the server repository, on develop. Revisit that file before production deployment and App Store submission.
