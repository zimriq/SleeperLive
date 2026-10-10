# SleeperLive

A SwiftUI learning project for a Sleeper fantasy football companion.

## Current checkpoint

- Look up a Sleeper account by username.
- Fetch NFL leagues using the current league season.
- Select a league and identify the account’s roster, including co-owners.
- Show loading feedback and disable lookup buttons during requests.
- Decode the current week and prepare the weekly matchup model.

Matchup fetching is the next lesson: `findMatchup(league:)` currently only checks its inputs. Live Activities and server updates are planned, not implemented in this learning project.

## Open

Open `SleeperLive.xcodeproj` in Xcode and run the SleeperLive scheme on an iPhone simulator. Physical-device installation requires selecting your own signing team.

This repository contains the original learning project, not the separate Matchday preview.
