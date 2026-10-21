import ActivityKit
import Foundation

// Shared by the app and widget. Score fields match the server's JSON contract.
struct MatchupActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let yourScore: Double
        let opponentScore: Double
        let yourProjected: Double?
        let opponentProjected: Double?
        let yourProjectionKind: String
        let opponentProjectionKind: String
        let updatedAt: Int

        var updatedDate: Date {
            Date(timeIntervalSince1970: TimeInterval(updatedAt))
        }

        // Missing updates must never look like fresh game scores.
        var staleDate: Date { updatedDate.addingTimeInterval(360) }
    }

    let leagueName: String
    let yourName: String
    let opponentName: String
    let week: Int

    // Optional so the existing server's four-field attributes still decode.
    var leagueId: String? = nil
    var rosterId: Int? = nil
    var previewOnly: Bool? = nil
}
