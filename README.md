# SleeperLive

An iPhone app for following Sleeper fantasy football matchups through Live Activities.

## Automated testing with GitHub Actions

The **iPhone app tests** workflow builds the app and runs its XCTest suite on an iPhone simulator using a GitHub-hosted macOS runner. This checks that the app builds and that its automated tests pass together.

The workflow is configured to run on:

- Pushes to `main` and `develop`.
- Pull requests targeting `main` or `develop`.
- Manual runs from the repository's Actions tab.

It selects an available iPhone simulator and runs `xcodebuild test` with the shared **SleeperLive Dev** scheme. Simulator testing does not require App Store signing credentials.

The existing tests cover app/server data handling, response validation, retry timing, and registration state changes such as token rotation and refreshes during an in-flight request.

View execution logs and pass/fail results in [GitHub Actions](https://github.com/zimriq/SleeperLive/actions). The workflow definition is intended to live at `.github/workflows/ios-tests.yml`; consult the Actions tab to confirm it has been committed and to verify the latest run.

These checks complement physical-device testing. They do not verify actual Apple push delivery, lock-screen update timing, production server availability, or the absence of all bugs.
