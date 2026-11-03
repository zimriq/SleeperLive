# App Review notes

Suggested review instructions. Confirm production claims on a signed physical iPhone before submission.

SleeperLive is an independent companion for viewing Sleeper fantasy football matchups on the Lock Screen and Dynamic Island. It looks up a public Sleeper username without requesting a password. The Matchup and Settings tabs remain available before and after username lookup.

## Real matchup and background updates

1. On the first eligible launch, new installations see the in-app explanation Allow background matchup updates? before username lookup. Enable background updates starts App Attest device enrollment; Not now or dismissing the sheet leaves background registration off.
2. On Matchup, enter a Sleeper username, select a league and load its current matchup.
3. This is an in-app consent explanation, not an iOS permission dialog. The explanation is shown automatically only once. It does not repeat after logout, deletion, a prior opt-out, subsequent app launches or matchup refreshes. Existing connected users are not prompted again. Users may explicitly enable updates later from Settings or the matchup controls.
4. Once connected, start a Live Activity. The service must be reachable and production App Attest/push signing must be valid. Score delivery may be delayed. Proj. values are experimental estimates, not official Sleeper live projections.

## Sample without a Sleeper username

Tap Try a sample matchup on the welcome screen or in Settings. Sample Home and Sample Away are fictional, labeled sample data. Start sample Live Activity and lock the phone to inspect the preview; Simulate score update changes the sample locally and Reset sample scores reverses it. Stop the sample before starting a real activity. Closing its sheet does not stop the activity. No sample scores are registered with the server. The simulator cannot verify real App Attest/push enrollment, but local sample presentation remains available.

## Settings, logout, and deletion

Settings shows the current username/league, Change league, background-registration status and retry/enable controls, system Settings shortcut, Privacy & Help, and the sample.

- Log out requires confirmation, stops local activities and queues their cleanup, pauses the session, and clears the saved username/matchup. It retains device credentials and prior background-update consent. Relaunch alone does not resume the session; explicitly entering a valid username can reuse the registration and previous choice without another automatic prompt. If the paused state cannot be saved securely, the app does not pretend logout completed. Offline activity cleanup remains queued without revoking the registration.
- Delete SleeperLive data separately confirms removal of the current device registration and activity records from the active server database, plus local matchup cleanup. Neither action deletes the external Sleeper account or other devices. Historical backups/logs and previously disconnected registrations may remain. The matching server deletion endpoint must be deployed first.
- Pending deletion or older-version disconnection can be retried in Settings or the welcome screen. A retry preserves a pending deletion instead of silently downgrading it to revocation.
- Privacy & Help contains privacy information, public support contact/link and troubleshooting; device actions are now directly in Settings.

The privacy-policy URL, final privacy answers, actual review account/league if needed, production-device validation and screenshots remain submission prerequisites. Never put passwords, bearer credentials or push tokens in review notes.
