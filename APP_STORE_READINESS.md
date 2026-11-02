# App Store submission work

Inspected November 2, 2026. This is a client-code review, not an approval guarantee. Server source and App Store Connect were not available. Existing uncommitted changes were preserved.

1. **Privacy & Help — started.** Added an always-accessible screen with client data-flow information and troubleshooting. Before release, publish a complete privacy policy and add `SleeperLivePrivacyPolicyURL` with its HTTPS URL to `AppInfo.plist`. The owner-approved support address, zimryquinonez@gmail.com, is configured in `AppInfo.plist`. Links are omitted until real values are supplied; this state is not submission-ready. Confirm both links on a device and use the same policy URL in App Store Connect.
2. **Public support page — implemented.** Support website: https://sleeperlive-support.goldenghost7.chatgpt.site . Includes contact email, troubleshooting, and data-request guidance; linked from Privacy & Help. Enter this URL in App Store Connect’s Support URL field. The privacy-policy URL remains a separate pending requirement.
3. **Server privacy verification — needed before final policy.** Verify operator/contact, hosting and subprocessors, stored device identifiers, App Attest records, matchup selections, push tokens, request/IP logs, retention periods, backups, deletion procedure, and security/abuse exceptions. Do not claim no collection or eight-hour deletion of all data based on client code.
4. **Privacy labels and manifests — verify.** A UserDefaults required-reason manifest already exists (CA92.1). Review the archive's privacy report, dependencies, all required-reason APIs, and actual backend collection before completing App Store privacy answers.
5. **Device-data removal and account assessment — investigate.** Username lookup does not itself create a SleeperLive login, but automatic enrollment creates a persistent server-side device record. Confirm whether it constitutes account creation and implement deletion if required. Change username only clears the local selection and cached matchup; ending an activity is not full server-data deletion.
6. **Review instructions and test access — needed.** Explain username lookup, background registration, Live Activity start/stop, projections, and data dependencies. Supply a reliable review path outside live NFL games; any demo must be clearly identified and disclosed. Keep the production service available.
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
