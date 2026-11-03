import unittest
from check_release import contact_issues, distribution_issues, manifest_issues, public_https, entitlement_issues


class ReleaseChecks(unittest.TestCase):
    def test_real_https_destinations_are_accepted(self):
        self.assertTrue(public_https("https://sleeperlive-support.goldenghost7.chatgpt.site/privacy"))

    def test_placeholders_and_private_destinations_are_rejected(self):
        for value in (None, "", "http://public.site", "https://localhost", "https://127.0.0.1", "https://192.168.1.2", "https://[::1]", "https://example.com/privacy", "https://user:password@public.site", "https://public.site:8000", "https://public.site/with space", "https://public.site:invalid"):
            with self.subTest(value=value):
                self.assertFalse(public_https(value))

    def test_missing_policy_is_a_blocker_even_with_support_configured(self):
        issues = contact_issues({"SleeperLiveSupportURL": "https://support.sleeperlive.site", "SleeperLiveSupportEmail": "support@sleeperlive.site"})
        self.assertEqual(len(issues), 1)
        self.assertIn("Privacy-policy", issues[0])

    def test_development_signing_is_not_distribution_ready(self):
        issues = distribution_issues({"aps-environment": "development", "com.apple.developer.devicecheck.appattest-environment": "development", "get-task-allow": True})
        self.assertEqual(len(issues), 3)

    def test_production_entitlements_pass_selected_checks(self):
        self.assertEqual(distribution_issues({"aps-environment": "production", "com.apple.developer.devicecheck.appattest-environment": "production", "get-task-allow": False}), [])

    def test_unreadable_entitlements_produce_an_actionable_finding(self):
        import plistlib
        for value in (b"", b"not a plist", plistlib.dumps([])):
            self.assertIn("Signing tool", entitlement_issues(value)[0])

    def test_empty_and_malformed_manifest_is_not_accepted(self):
        self.assertGreaterEqual(len(manifest_issues({})), 3)
        self.assertTrue(manifest_issues({"NSPrivacyTracking": False, "NSPrivacyCollectedDataTypes": [None, {"NSPrivacyCollectedDataType": 1}]}))


if __name__ == "__main__":
    unittest.main()
