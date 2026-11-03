# SleeperLive Privacy Policy

Effective November 3, 2026.

## Who operates SleeperLive

SleeperLive is operated by Zimri Quinonez. It is an independent companion app and is not affiliated with or endorsed by Sleeper. For support or privacy requests, email zimryquinonez@gmail.com.

## Information on your device

The app uses the Sleeper username you enter to look up public account, league, roster, and matchup information. It does not request your Sleeper password or create a Sleeper account. The app saves your username, league selection, cached matchup, and preferences on your device. Device access credentials and pending background-update work are stored in the device Keychain. Some local preferences may be included in operating-system backups; device access credentials use device-only Keychain storage.

## Optional background updates

You can allow or decline background updates and change your choice in Settings. Registration sends Apple App Attest verification information and a hash of a device access credential to the SleeperLive service. The server stores device and attestation identifiers, a credential hash, verification public key, registration information, and attestation environment to verify access and prevent abuse. Without enabling this service, you can use username lookup, manual score refreshes, and the sample matchup.

## Matchups and Live Activities

When you request a matchup through the service, it receives the league identifier, roster identifier, and week. A Live Activity also sends its identifier, push token, Apple push environment, and start time. The service stores the selected matchup, team and league names, scores, available estimates, update times, and delivery status to manage updates. Apple receives the Live Activity token and score-update payloads through its push notification service.

## Service providers and connection information

Railway hosts the SleeperLive server. Sleeper supplies public account and fantasy matchup information, and Apple provides App Attest verification and push delivery. Network requests expose connection information, including IP addresses, to the services handling them. The server uses IP addresses and device identifiers for abuse prevention, including short-lived in-memory rate limits. Railway built-in logging records service operation and network request information such as request paths, timestamps, status codes, and activity identifiers in paths. We do not forward these logs to an external monitoring service.

## Analytics, advertising, and tracking

SleeperLive does not use an added analytics or crash-reporting service, advertising integrations, or cross-app tracking. Operational hosting and security information is still processed as described in this policy.

## Logout and deleting SleeperLive data

In Settings, Log out clears the saved username and matchup, stops local Live Activities, and pauses the session. It preserves this device’s server registration and your previous background-update choice, so a later login can reuse them. Delete SleeperLive data requests removal of the current device registration and its associated activity records from the active server database, clears local access and selection, and turns background updates off. Keep an internet connection available and wait for the app to confirm success; failed or pending requests may need a retry. This does not delete your external Sleeper account, other devices’ registrations, or registrations left by older installations that this installation can no longer authenticate.

## How long information remains

Local dashboard information remains until replaced or cleared, including by logout or deletion. Device registrations do not automatically expire; they remain until deleted or otherwise removed. Revoking a registration through older disconnect or administrative tools may retain registration and replay-prevention identifiers while removing authentication material. Active Live Activities have an eight-hour lifetime. Ended activity tokens are cleared, and ended records are removed during a later running cleanup once more than 24 hours have passed after ending; outages and delivery retries may delay cleanup.

## Logs, storage copies, and support emails

Deleting an active database record does not erase historical SQLite pages, journals, hosting logs, or separate historical copies. As of this policy date, no scheduled production database backups or Railway volume snapshots are configured; a manual backup was tested in the separate development environment. Railway controls its own infrastructure retention. Its documented seven-day log visibility for Trial and Hobby is not a guarantee of permanent deletion after seven days. Support emails remain in the support mailbox until manually deleted; there is no automatic deletion schedule. Email-provider storage and recovery copies are managed by that provider.

## Privacy requests

Email zimryquinonez@gmail.com to ask about access, correction, or deletion of information associated with your use of SleeperLive. Depending on where you live, you may have additional privacy rights. We may need to verify the relevant device registration safely before acting. Do not email passwords, push tokens, or device access credentials. In-app deletion is the direct way to remove the registration authenticated by your current installation; contact support for help with other records.

## Changes to this policy

We will update this page and its effective date when our practices change. Material changes will be described on this page and, where appropriate, in the app.
