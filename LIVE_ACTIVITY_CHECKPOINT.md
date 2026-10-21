# Live Activity preview checkpoint

This milestone adds a local Live Activity for the selected Sleeper matchup. It uses the actual loaded scores and team names. It does not send notifications, contact the companion server, or update automatically while the app is closed.

## Included

- Shared ActivityKit model matching the server's score field names and Unix-second timestamp.
- Embedded WidgetKit extension with Lock Screen, compact, expanded, and minimal Dynamic Island layouts.
- Start, manually refresh, and stop a preview; one activity at a time.
- Restore an existing activity when reopening the app; observe dismissal/end.
- Freshness warning after six minutes without a score refresh.
- Optional projected scores displayed as `Proj. —` until a real source is connected.
- iOS 17 minimum deployment target for both targets.

## Run and verify

1. Open SleeperLive.xcodeproj and choose the SleeperLive app scheme.
2. Use an iPhone simulator, or set your signing team for **both** SleeperLive and SleeperLiveWidget before running on a physical iPhone. Both bundle IDs must belong to the same team. This local preview does not require APNs credentials.
3. Enter a Sleeper username, select a league, then select **Preview Live Activity**.
4. Lock the device and check both team names and scores. On a Dynamic Island device, long-press the Island to expand it.
5. Reopen the app and select **Refresh scores**. Only the same league/week/roster activity is updated. Choosing another league does not replace an existing activity; stop it first.
6. Stop the activity and verify it disappears. Start another, dismiss it from the Lock Screen, then verify the app permits a new preview.
7. Leave an activity without refresh for six minutes. Verify the expanded/Lock Screen view warns that scores may be outdated.
8. Terminate and reopen the app while a preview is active. The manager should find it rather than create a duplicate.
9. Try a long team name, large text, dark mode, offline refresh, and Live Activities disabled in Settings. Offline failures must retain the last score timestamp.

Apple controls activity lifetime and availability. This feature intentionally labels every local activity as a preview without automatic background updates.

## Next milestone (not part of this commit)

Connect the existing server: private tester enrollment, Keychain credentials, authoritative matchup snapshots, APNs token registration/rotation, retry handling, remote updates, and server cleanup on stop. Use `Proj.` in the UI, but explain experimental projections accurately. Do not enable paid hosting until usage and budget controls are checked.

## Verified for this checkpoint

Xcode's native build succeeded with no issues on October 21, 2026. On the iPhone 18 Pro / iOS 27 simulator, account/league lookup, starting the activity, Lock Screen presentation, compact and expanded Dynamic Island, manual refresh timestamp, and stop/removal were checked. Physical-device signing, six-minute stale transition, relaunch restoration, and disabled-permission behavior remain on the manual checklist above. The command-line build was blocked by this session's preview-macro sandbox; verification used Xcode's native build instead.
