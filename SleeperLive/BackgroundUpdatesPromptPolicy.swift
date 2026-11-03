// First-launch invitation only. Choosing or dismissing it is persisted by the view.
enum BackgroundUpdatesPromptPolicy {
    static func shouldOffer(hasSeenPrompt: Bool, isConnected: Bool,
                            hasOptedOut: Bool, needsConsent: Bool) -> Bool {
        !hasSeenPrompt && !isConnected && !hasOptedOut && needsConsent
    }
}
