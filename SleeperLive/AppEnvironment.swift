import Foundation

// Only the dedicated Develop configuration selects the isolated Railway service.
// Normal Debug and Release builds continue to use production.
enum AppEnvironment {
    #if SLEEPERLIVE_DEVELOP
    static let serverURL = URL(string: "https://sleeperlive-server-develop.up.railway.app")!
    #else
    static let serverURL = URL(string: "https://sleeperlive-server-production.up.railway.app")!
    #endif
}
