# Private iPhone server integration

This checkpoint connects SleeperLive to the existing Node server. It does not deploy a service, purchase hosting, or configure an Apple account.

## What is implemented

- Server setup with a bare HTTPS address and tester invitation.
- Device credentials and pending activity registrations stored in the device Keychain.
- Server-authoritative scores and optional experimental projections, labeled **Proj.** Missing projections remain a dash.
- Live Activity push-token registration, token rotation, retry delays, and durable stop cleanup.
- Foreground refresh approximately every 75 seconds. Background Lock Screen updates come from APNs, not an app timer.
- Local preview remains available before connecting a server.

A successful registration means the server accepted the token; it does not prove a push reached the phone. Delivery timing can vary. Scores become marked stale after six minutes without fresh data. Activities are limited to eight hours; start another afterward.

## Configure the server

Use the server project's deployment instructions and persistent SQLite storage. Run one instance with `DB_PATH` pointing to the persistent volume (for example `/data/server.sqlite`). Preserve that database across redeploys so device credentials and registrations survive.

Set these server environment variables through the host's secret settings:

- `INVITE_CODE`: a random secret of at least 24 characters.
- `POLL_SECONDS=75`.
- `APNS_MODE=live` only after configuring APNs.
- `APNS_BUNDLE_ID`: exactly the app's signed bundle identifier.
- `APNS_TEAM_ID` and `APNS_KEY_ID`: the Apple team and APNs key identifiers.
- `APNS_KEY_P8`, or `APNS_KEY_FILE` pointing to the private `.p8` file.
- `ENABLE_ESTIMATES=false` initially. Setting it to `true` enables the server's experimental projection calculation; these are not official Sleeper projections.

Never put the APNs private key in the iPhone app or commit secrets. The app requires a valid HTTPS certificate and refuses redirects for API requests. `dry-run` is useful for server testing but cannot deliver background updates.

## Configure Xcode and the phone

1. Select your paid Apple Developer team for the app and widget targets. Keep their bundle identifiers unique and consistent with the server configuration.
2. Verify **Push Notifications** is enabled on the app target and its provisioning profile. The entitlement is included in this checkpoint.
3. Build and run on your physical iPhone. Allow Live Activities in the app's iOS settings if disabled.
4. Open **Server setup**, enter the HTTPS server address and tester invitation, and connect.
5. Find your account, choose a league, load the matchup, and start its Live Activity. Keep the app open until registration succeeds, then lock the phone.

The implementation derives sandbox/production APNs routing from the embedded provisioning profile. This supports the current private device-testing scope. Distribution without an embedded profile fails closed and needs additional work before App Store release. Simulator remote start is intentionally blocked; use the local preview before connecting a server.

## Recovery behavior

Pending registrations, rotated tokens, and deletions survive app relaunch. Requests retry while the app can execute; suspension can defer retries until it resumes. Stopping ends the local activity immediately after cleanup is saved, then the server deletion retries as necessary. The server's expiry and invalid-token handling provide additional cleanup when the app cannot run.

Stop the current activity and let pending cleanup finish before reconnecting. If credentials are revoked, reconnect with valid server access after cleanup. An unavailable server does not silently replace server scores with a different source.

## Validation and remaining checks

The 12 Xcode integration tests passed, covering URL validation, snapshot decoding/validation, APNs profile parsing, token rotation, queued stop ordering, retry delays, durable records, enrollment, and authenticated registration. The native Xcode build also passed.

The server's latest local run passed 17 tests. Four HTTP-listener tests were blocked by this execution environment's `listen EPERM` restriction; rerun `npm test` from the server directory in a normal terminal.

Before relying on the app during a game, verify on a signed physical phone with the deployed server:

- A real APNs update arrives while the phone is locked and the app is backgrounded.
- Names, actual scores, timestamps, and available projections match the server response.
- Stale data is visibly marked during a server/network outage.
- Stopping, dismissing, reopening, and restarting do not leave duplicate registrations.
- Restarting the server preserves device access and active records.
- Offline stop cleanup completes after the app reconnects.

No live APNs delivery or hosting-cost measurement has been completed in this checkpoint. Measure memory, CPU, storage, and network usage with the intended game-day workload and configure the host's spending controls before treating a $10/month budget as verified.
