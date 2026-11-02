# App Store submission work

Inspected November 2, 2026. This is a client-code review, not an approval guarantee. The local iOS and server sources have been inspected; App Store Connect and production hosting settings have not been verified. Existing uncommitted changes were preserved.

1. **Privacy & Help — started.** Added an always-accessible screen with client data-flow information and troubleshooting. Before release, publish a complete privacy policy and add `SleeperLivePrivacyPolicyURL` with its HTTPS URL to `AppInfo.plist`. The owner-approved support address, zimryquinonez@gmail.com, is configured in `AppInfo.plist`. Links are omitted until real values are supplied; this state is not submission-ready. Confirm both links on a device and use the same policy URL in App Store Connect.
2. **Public support page — implemented.** Support website: https://sleeperlive-support.goldenghost7.chatgpt.site . Includes contact email, troubleshooting, and data-request guidance; linked from Privacy & Help. Enter this URL in App Store Connect’s Support URL field. The privacy-policy URL remains a separate pending requirement.
3. **Server privacy verification — needed before final policy.** Verify operator/contact, hosting and subprocessors, stored device identifiers, App Attest records, matchup selections, push tokens, request/IP logs, retention periods, backups, deletion procedure, and security/abuse exceptions. Do not claim no collection or eight-hour deletion of all data based on client code.
4. **Privacy labels and manifests — verify.** A UserDefaults required-reason manifest already exists (CA92.1). Review the archive's privacy report, dependencies, all required-reason APIs, and actual backend collection before completing App Store privacy answers.
5. **Device disconnection and active-database deletion — implemented; deployment and retention policy pending.** The Delete device data action uses the new DELETE /v1/devices/me/data server route. Deploy the server first. A confirmed deletion removes device/attestation records and all owned activity records; it does not purge historic SQLite pages, logs, support mail, or backups. Privacy & Help now includes a confirmed disconnect-and-clear action, durable opt-out, pending network retry, and explicit re-enable. The client uses DELETE /v1/devices/me to revoke server access; this is not complete erasure. Username lookup does not itself create a SleeperLive login, but automatic enrollment creates a persistent server-side device record. Confirm whether it constitutes account creation and implement deletion if required. Change username only clears the local selection and cached matchup; ending an activity is not full server-data deletion.
6. **Sample matchup and review instructions — implemented; production verification pending.** The welcome screen and Help & Preview menu offer a clearly labeled fictional matchup, a local-only Live Activity, and a manual simulated score update. See APP_REVIEW_NOTES.md. No sample selection or scores are registered with the server. New installations require an explicit background-update opt-in before device enrollment. Previously connected installations retain existing access. Explain username lookup, background registration, Live Activity start/stop, projections, and data dependencies. Supply a reliable review path outside live NFL games; any demo must be clearly identified and disclosed. Keep the production service available.
7. **Production archive and device verification — needed.** Validate archive signing, production push delivery and App Attest, entitlement resolution, fresh install, denied/disabled Live Activities, network loss, stale scores, stop/cleanup, large text, VoiceOver, and supported device layouts. The source entitlement uses development APNs; verify the distribution archive's resolved entitlement rather than changing it blindly.
8. **Listing and content rights — verify.** Prepare accurate screenshots, description, age rating, support/privacy URLs, export-compliance answers, and content-rights declarations. Confirm rights to names, logos, icons and data; avoid suggesting an official Sleeper affiliation without authorization.

## Policy preparation

The in-app overview is not a complete privacy policy. Final publication needs verified server facts and the operator's contact details. Cover data collected and why; direct Sleeper requests; SleeperLive server requests; Apple App Attest and push delivery; local preferences and Keychain storage; hosting/other recipients; retention and deletion; user requests and consent controls; and policy updates. Do not invent retention durations or state that changing username deletes backend records.

## Sources

- https://developer.apple.com/app-store/review/guidelines/ (2.1, 2.3, 4.2, 5.1.1, 5.2)
- https://developer.apple.com/app-store/review/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/

## Background-update opt-in

Implemented an explanation and explicit enable action before new device enrollment. Skipping leaves public Sleeper lookup, manual refresh, and sample mode available. The choice is saved in Keychain; device disconnection revokes the opt-in. Existing connected installations keep their established access. This is not a substitute for a published privacy policy, final privacy disclosures, or full data deletion.

## Accessibility improvements

Added team names and actual-score descriptions to compact and minimal Dynamic Island VoiceOver output. Preview and stale status are announced, and actual scores are distinguished from estimates. Sample score rows stack when horizontal space is insufficient. Increased contrast of the decorative VS label and hid it from VoiceOver. Build validation does not replace physical-device checks: verify VoiceOver reading order, all Dynamic Type sizes, long team names, display zoom, and system Live Activity height constraints before submission.

## Device-data deletion release checks

Push/deploy the server update before using the new app deletion action. Verify on a physical device using a disposable registration: delete succeeds, device access fails afterward, other devices remain intact, and re-enable creates a fresh registration. Offline deletion must remain pending with automatic enrollment blocked. A 401 after a lost response is ambiguous and intentionally remains unconfirmed; support must verify the outcome without requesting bearer tokens. The existing disconnect action still revokes access without erasing replay records. Backup/log retention and restoration reconciliation remain unresolved; this feature alone does not establish complete account-deletion compliance.
