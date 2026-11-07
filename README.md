# SleeperLive

Follow your Sleeper fantasy football matchup from your iPhone’s Lock Screen with Live Activities.

[Download on the App Store](https://apps.apple.com/us/app/sleeperlive/id6826844567) · [App test runs](https://github.com/zimriq/SleeperLive/actions/workflows/iOS-tests.yml) · [Server repository](https://github.com/zimriq/SleeperLive-Server)

## Features

- View your matchup and both teams’ scores in the app.
- Follow scores through a Lock Screen Live Activity.
- Enable background updates and refresh your matchup manually.
- Try a sample matchup before connecting your own.
- Manage background-update preferences and device registration in settings.
- View experimental projected totals when supported data is available.

Projections are estimates, not Sleeper’s official live projections. Background delivery and timing depend on network access, upstream data, and iOS.

## How it works

The SwiftUI app displays matchup data and manages the Live Activity through ActivityKit. A companion Node.js server fetches Sleeper matchup data, stores device and activity registrations in SQLite, and submits background updates through Apple Push Notification service (APNs). The widget extension presents the Live Activity on supported devices.

The app and server are maintained in separate repositories. Server changes can be deployed independently; changes to the installed iPhone app require a new app release.

## Built with

Swift, SwiftUI, ActivityKit, WidgetKit, XCTest, and GitHub Actions.

## Run locally

1. Clone this repository and open `SleeperLive.xcodeproj` in Xcode 27 or later. The committed project uses format version 110.
2. Choose the **SleeperLive Dev** scheme to use the isolated development server. Normal Debug and Release configurations use the production server; see `AppEnvironment.swift`.
3. Select an iPhone simulator to build and run, or configure your own signing team for a physical device.
4. Use **Product → Test** to run the XCTest suite.

Use a physical iPhone and appropriate signing capabilities to validate App Attest enrollment and actual Live Activity push delivery. Simulator tests do not establish those behaviors.

## Automated testing with GitHub Actions

The [iPhone app tests workflow](.github/workflows/iOS-tests.yml) builds the app and runs its XCTest suite on an available iPhone simulator using GitHub’s **xcode-27** runner. It runs on pushes to `main` and `develop`, pull requests targeting either branch, and manual dispatches.

The workflow runs `xcodebuild test` with the shared **SleeperLive Dev** scheme and disables code signing for the simulator. The branch checked out by the workflow determines the source being tested; the scheme selects the build configuration.

Existing tests cover app/server data handling, response validation, retry timing, token rotation, and refreshes during in-flight registration. A successful GitHub Actions build-and-test run was confirmed on November 7, 2026. See [Actions](https://github.com/zimriq/SleeperLive/actions/workflows/iOS-tests.yml) for current results and logs.

These checks complement physical-device testing. They do not prove production availability, actual Apple push delivery, lock-screen update timing, or that every recovery path is correct.

## Project layout

- `SleeperLive/`: SwiftUI screens, networking, enrollment, and Live Activity management.
- `SleeperLiveWidget/`: Live Activity presentation.
- `SleeperLiveTests/`: XCTest coverage for integration logic.
- `.github/workflows/`: automated build and test configuration.

## Development and follow-up work

`main` is the branch used for the current app verification; `develop` holds ongoing work. Keep changes reviewable and verify both automated checks and affected device behavior before release.

A priority follow-up is handling the server’s `needsPushToken` registration response explicitly. The app can currently acknowledge a registration that still requires a replacement push token. Fixing that recovery path requires an app update; passing the existing tests does not mean this known gap is resolved.

## About

SleeperLive is an independent companion app for Sleeper fantasy football. It is not affiliated with or endorsed by Sleeper.
