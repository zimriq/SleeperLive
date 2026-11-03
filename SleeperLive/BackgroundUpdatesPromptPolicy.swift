// Automatic presentation is a one-time invitation, never an enrollment action.
enum BackgroundUpdatesPromptPolicy {
    static func shouldOffer(hasSeenPrompt: Bool, hasLoadedMatchup: Bool,
                            isConnected: Bool, hasOptedOut: Bool, needsConsent: Bool) -> Bool {
        !hasSeenPrompt && hasLoadedMatchup && !isConnected && !hasOptedOut && needsConsent
    }
}
