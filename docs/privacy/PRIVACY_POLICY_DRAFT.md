# SleeperLive Privacy Policy — unpublished draft

**Not ready for publication.** Prepared November 2, 2026 from the local iOS and server source and the owner's confirmation that Railway hosts production and no analytics or crash-reporting service is used. Confirm the deployed server matches this source. Resolve the publication blockers below before setting an effective date or adding a public policy link.

## Who to contact

SleeperLive is an independent companion app for following Sleeper fantasy football matchups. Contact: zimryquinonez@gmail.com.

## Information used by the app

SleeperLive uses the Sleeper username you enter to request public account and league information from Sleeper. It does not ask for your Sleeper password. Requests to Sleeper include account, league, roster, and week identifiers as needed to load your matchup. Network providers receive the network information needed to serve those requests.

The app saves your last username, selected league, and a cached matchup on your device to restore the dashboard. Device access credentials and pending background-update work are stored in this device's Keychain. The app uses Apple App Attest to verify its device registration with the SleeperLive server.

## Background-update service

The SleeperLive server is hosted on Railway. Registration sends an App Attest key identifier, verification proof, challenge information, and a hash of a device access credential. The server stores a device identifier, credential hash, registration time, attestation key identifier, public key, and attestation environment for verified devices.

Matchup requests send the selected league identifier, roster identifier, and week. Starting a Live Activity also registers its activity identifier, push token, Apple push environment, and start time. The server stores the selected matchup, team and league names, scores, available estimates, update times, and delivery status to deliver and manage updates.

Apple's push notification service receives the Live Activity token and score-update payloads. The server requests league and matchup information from Sleeper. These services are used to verify registrations, obtain scores, host the service, and deliver updates.

The server processes IP addresses and device identifiers to limit abuse. The reviewed application code keeps rate-limit counters in memory in one-minute windows. This does not determine how long Railway or other infrastructure retains network logs.

## Analytics and advertising

The operator reports that SleeperLive does not use an analytics or crash-reporting service. The reviewed app and server contain no advertising or cross-app tracking integration. Hosting and security operations still process service and network information as described above.

## Retention and removal

Local dashboard information remains until replaced or cleared using Change username. Changing username does not delete a Sleeper account or server device registration.

Active Live Activity registrations have an eight-hour lifetime. Ended registrations have their push token cleared and are removed during a later running poll once more than 24 hours have elapsed after ending. Outages and pending end-delivery retries can delay cleanup. Eight hours is an activity lifetime, not a promise to delete all associated information at that time.

The current server does not automatically expire active device records. Revoking a device removes its credential hash and stored attestation public key from the logical database record, and queues active activities to end. The device identifier, attestation key identifier, registration information, environment, and revocation status remain to prevent reuse. This is access revocation, not complete erasure. Older SQLite pages, journal files, and backups can retain previous values.

Contact zimryquinonez@gmail.com for privacy questions or to request access to or removal of your information. Never email passwords, push tokens, or device access credentials. We may need to verify which registration belongs to your device without asking you to disclose those secrets.

**Publication blocker:** establish and disclose actual retention periods and deletion procedures for device records, abuse-prevention records, Railway logs, database backups, and support emails. Confirm how pending deletion requests are tracked and completed. Do not describe revocation or an email-only support process as compliant account deletion without assessing and implementing Apple's applicable requirements.

## Changes

The final published policy will display its effective date and describe how material changes are communicated.

## Remaining publication blockers (internal only)

- Confirm operator identity for the policy and that deployed server behavior matches the reviewed local source.
- Identify whether backups are Railway volume backups, manual SQLite backups, or both; confirm schedule, retention, access, and deletion handling. The owner believes backups exist; this has not been verified.
- Verify Railway request/application log settings and retention. Do not send secrets or log contents into chat.
- Choose and implement retention for persistent device and replay-prevention records; decide whether full in-app deletion is required and implement it if applicable.
- Decide support-email retention and the process for verifying data requests.
- Verify the relevant third-party data protections and any hosting/subprocessor details before finalizing the recipient disclosures.
- Review OS backup behavior for local preferences; Keychain items use ThisDeviceOnly, while that does not establish backup behavior for cached preferences.
- After these are resolved, remove internal notes, set an effective date, publish at a public HTTPS URL, and connect that URL in AppInfo.plist and App Store Connect.

## Implementation references (internal only)

- iOS: ContentView.swift (lookup, AppStorage, dashboard cache); AutomaticEnrollment.swift (App Attest); IntegrationStore.swift (Keychain); ServerClient.swift (registration and snapshot payloads).
- Server: app.js (routes and ingress counters); enrollment.js (device fields and challenges); registrations.js (SQLite and revoked-record minimization); poller.js (activity lifecycle); revoke-device.js (revocation); backup.js (manual backup with no pruning schedule).
- Apple: https://developer.apple.com/app-store/review/guidelines/ section 5.1.1; https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/
