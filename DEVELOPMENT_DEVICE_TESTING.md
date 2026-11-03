# Physical iPhone development testing

Use the shared **SleeperLive Dev** Xcode scheme. It uses the Develop build configuration and the built-in server https://sleeperlive-server-develop.up.railway.app . No manual URL/invitation screen is exposed. The ordinary SleeperLive scheme's Debug and Release configurations still select production.

## Isolation

- App bundle ID: com.zimri.SleeperLive.Develop
- Widget bundle ID: com.zimri.SleeperLive.Develop.MatchupWidget
- Display name: SleeperLive Dev; the app toolbar also shows Development.
- Keychain storage uses the app bundle identifier, so this app has separate credentials and pending work from production. UserDefaults are also scoped to the separate app.
- Install alongside the normal app. Do not submit the Dev scheme's archive to the App Store. App Attest and signing still require the paid Apple team and appropriate capabilities for these identifiers.

## Railway setup — development environment only

1. Confirm the selected environment is develop and the service has its own /data volume with DB_PATH=/data/server.sqlite.
2. Set APNS_BUNDLE_ID=com.zimri.SleeperLive.Develop on that environment. App Attest validates this app identity even while APNS_MODE=dry-run. Keep the production service's bundle ID unchanged.
3. Keep APP_ATTEST_ENABLED=true. Use the correct existing app identifier prefix for the signing team. Do not enable invitation enrollment or add a verification bypass to get past an attestation error.
4. Keep APNS_MODE=dry-run initially. No new Apple push key is needed just to test registration/deletion in this mode. Existing copied keys must still be valid if their configuration is present; never paste them into chat.
5. Apply/deploy the development variable change. Verify the health endpoint still reports dry-run.

## Run on the phone

1. Connect your iPhone to Xcode and open SleeperLive.xcodeproj.
2. Select **SleeperLive Dev** from the scheme picker and your physical iPhone as the destination.
3. Check Signing & Capabilities for the app/widget using your paid team. Xcode may need to register the new identifiers or create matching profiles. Resolve any signing errors without changing production identifiers.
4. Run. Confirm the home-screen name says SleeperLive Dev and the toolbar says Development.
5. Tap Enable background updates, read the disclosure, and confirm. After setup closes, look for Device registration saved on the welcome/matchup screen, or open Settings → Background updates. Test mode is shown when the current session has confirmed the dry-run health response. This means local registration credentials were saved; compare server records before declaring end-to-end registration verified. Do not share device credentials or tokens.
6. Username lookup/manual refresh and the local sample are available. The server deliberately refuses real remote Live Activity start in dry-run; that is not an enrollment failure. Real APNs delivery and owned activity-record deletion require a later controlled live-mode test.

## Verify device deletion next

Use only the Dev app. In Settings, choose Delete SleeperLive data and confirm. Expect the success message about deletion from the active server database. The saved selection should clear and background updates should remain off after relaunch. A server error or unconfirmed result is not a passing test. We will compare development database record counts using a safe read-only check; never copy the database or raw credentials into chat. A later re-enable should create a fresh device registration.

## Infrastructure results supplied so far

The user confirmed the deployed develop revision. The public development health response was independently checked as ok=true, mode=dry-run. User terminal output confirmed RAILWAY_ENVIRONMENT_NAME=develop and DB_PATH=/data/server.sqlite. A marker beside the database survived a service restart. Backup creation/integrity checks succeeded after setting BACKUP_DIR=/data/backups; retention was explicitly disabled for that run. These observations do not independently establish unique volume IDs, actual device-record persistence, scheduled backups, restoration reconciliation, log retention, or real APNs delivery.

## Retest the Settings redesign

Confirm Matchup and Settings remain reachable, Change league returns to selection, Privacy & Help opens from Settings, and both destructive actions require confirmation. Verify Log out leaves updates off after relaunch, including after selecting a username again; verify deletion/retry preserves the deletion intent. A genuinely new eligible installation should see the explanation only after a successful real matchup loads. Not now, dismissal and subsequent refreshes must not cause repeat prompts. Existing connected or previously opted-out installations should use Settings to enable manually and may correctly never see an automatic prompt.

## Revised logout / prompt retest

The current flow prompts once on first eligible launch, not after the first matchup. Not now, Done, and swipe dismissal must not repeat automatically. Existing registered devices correctly skip it. Logout must keep the device record (count stays 1), stop/clean up activities, and clear the username/matchup. Relaunch must remain logged out. Entering a valid username again reuses the same registration (count stays 1) and prior update choice. Delete SleeperLive data still removes the current record (count becomes 0). After deletion, another launch must not silently create one. Earlier revocation-based logout instructions in this file are superseded by this section.

## Compact alert verification

The first-launch choice is now a compact native alert, not a scrollable sheet. On a fresh eligible installation expect Allow background matchup updates? with Allow and Don’t Allow. The latter must leave registration off across relaunches. Open Settings → Enable background updates to see the alert again only on explicit request. Existing registered users correctly skip the automatic alert. Detailed data-flow text is in Settings → Privacy & Help. Simulator registration is unsupported; use the simulator for the alert’s appearance and the physical Dev app for enrollment.
