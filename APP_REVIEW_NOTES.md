# App Review notes

Suggested App Store Connect review notes. Confirm all production claims on a signed physical iPhone before submission.

SleeperLive is an independent companion for viewing Sleeper fantasy football matchups on the iPhone Lock Screen and Dynamic Island. It looks up a public Sleeper username without asking for a password. Real background updates use a hosted service, Apple App Attest device registration, and Apple push notifications.

## Sample mode — available without a Sleeper username

1. From the welcome screen, tap **Try a sample matchup**. From any main screen, the question-mark **Help & Preview** menu also offers it.
2. The sample displays fictional teams, **Sample Home** and **Sample Away**, with fixed sample scores. It is explicitly labeled and is available outside NFL games and without a Sleeper account.
3. Tap **Start sample Live Activity**, then lock the iPhone to inspect the Lock Screen. Dynamic Island presentation is available on supported devices. Live Activities must be allowed in iPhone Settings.
4. Reopen the sample and tap **Simulate score update** to change Sample Home's score. This is a manual local update, not a real game or background push. **Reset sample scores** reverses it.
5. Tap **Stop sample Live Activity** before starting a real matchup. Closing the sample screen does not stop an activity already started. Samples never replace an existing real activity.

The sample's league label is Sample matchup, and the Live Activity is labeled Preview. Sample selections and scores are not registered with the background service. On new installs, real device enrollment starts only after the user opens Enable background updates, reads the data-use explanation, and taps Enable background updates. Previously connected installations retain their existing access. The simulator cannot complete the real App Attest/push enrollment flow; local sample activities do not require it.

## Real matchup flow

Enter a public Sleeper username, select a league with a current assigned matchup, and load it. Choose Enable background updates and confirm the explanation. Once the device connects, start the Live Activity. Manual score lookup remains available without background enrollment. The hosted service must be reachable and production signing/push configuration must be valid. Sample mode demonstrates presentation and manual local updates; it does not substitute for testing real server updates.

Review submission still needs a verified review username/league if necessary, the published privacy-policy link, final privacy disclosures, and production-device validation. Do not include passwords, access credentials, or push tokens in review notes.

## Privacy and device controls

Open the question-mark menu and choose **Privacy & Help** for the support website, contact email, and device-disconnection control. Disconnection clears the local selection and revokes this device's access, with retry if offline. It is not complete erasure of retained server security records or backups.
