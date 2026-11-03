import SwiftUI

// Set these Info.plist values to real, public destinations before submission.
// No placeholder address or guessed policy URL is shown to users.
private enum PublicContact {
    static var privacyPolicyURL: URL? { httpsURL(for: "SleeperLivePrivacyPolicyURL") }
    static var supportPageURL: URL? { httpsURL(for: "SleeperLiveSupportURL") }

    private static func httpsURL(for key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value), url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        return url
    }

    static var supportURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SleeperLiveSupportEmail") as? String else { return nil }
        let email = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.range(of: #"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$"#,
                          options: .regularExpression) != nil else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: "SleeperLive support")]
        return components.url
    }
}

struct PrivacyAndHelpView: View {
    @ObservedObject var manager: LiveActivityManager
    var canDisconnect: Bool
    var clearSavedSelection: () -> Void
    @State private var confirmDisconnect = false
    @State private var requestDataDeletion = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    if let url = PublicContact.privacyPolicyURL {
                        Link(destination: url) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                    }
                    Text("SleeperLive looks up your Sleeper username without asking for your password. Your last username, league selection, and matchup are saved on this device so you can return to them.")
                    Text("Background updates register this device with the SleeperLive server using Apple App Attest. Matchup requests send the selected league, roster, and week. Live Activities also send an update token so the server can deliver scores through Apple’s push notification service. Device access credentials are stored in this device’s Keychain.")
                }

                Section("Live Activities") {
                    LiveActivitySettingsView(showDisabledExplanation: !manager.liveActivitiesEnabled)
                    Text("Start a Live Activity from your matchup to follow scores on the Lock Screen. Use Stop Live Activity in the app to end it.")
                    Text("If an activity does not appear, check that Live Activities are enabled for SleeperLive in iPhone Settings.")
                }

                Section("Scores and projections") {
                    Text("Delivery can be delayed by network conditions or iOS. Check the update time and use Refresh scores when needed. Saved scores may remain visible while offline.")
                    Text("Proj. values are experimental estimates, not Sleeper’s official live projections. A dash means an estimate is unavailable.")
                }

                Section("Device access") {
                    Button(manager.disconnectPending ? "Retry pending device request" : "Disconnect device & clear saved matchup", role: .destructive) {
                        requestDataDeletion = manager.deviceDataDeletionPending
                        confirmDisconnect = true
                    }
                    .disabled(manager.isBusy || !canDisconnect)
                    Button("Delete device data", role: .destructive) {
                        requestDataDeletion = true
                        confirmDisconnect = true
                    }
                    .disabled(manager.isBusy || !canDisconnect || manager.disconnectPending)
                    Text("Delete device data also removes this device’s registration, verification keys, push tokens, and activity records from the active server database. Older database copies, logs, and backups may remain. Other devices and your Sleeper account are unaffected.")
                    if manager.isBusy { ProgressView("Updating device access…") }
                    Text("Disconnecting stops your Live Activities, revokes this device’s server access, and clears its saved username and matchup. Background updates stay off until you enable them again. This does not delete your Sleeper account. Server identifiers used to prevent key reuse, logs, and backups may remain.")
                    if !manager.message.isEmpty {
                        Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("Your saved selection") {
                    Text("Choose Change username from the Account menu to clear the saved username, selected league, and cached matchup in this app. This does not delete your Sleeper account or server-side device registration.")
                }

                Section("Support") {
                    if let url = PublicContact.supportPageURL {
                        Link(destination: url) {
                            Label("Support website", systemImage: "questionmark.circle")
                        }
                    }
                    if let url = PublicContact.supportURL {
                        Link(destination: url) {
                            Label("Email support", systemImage: "envelope")
                        }
                        Text("Include your app version and what happened. Never send passwords or device access tokens.")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                }
            }
            .confirmationDialog(requestDataDeletion ? "Delete this device’s data?" : "Disconnect this device?", isPresented: $confirmDisconnect, titleVisibility: .visible) {
                Button(requestDataDeletion ? "Delete device data & clear matchup" : "Disconnect & clear saved matchup", role: .destructive) {
                    clearSavedSelection()
                    Task { _ = await manager.disconnectDevice(deleteData: requestDataDeletion) }
                }
            } message: {
                Text(requestDataDeletion
                    ? "This stops Live Activities and removes this device’s records from the active server database. Your saved matchup will be cleared. Deletion cannot be undone. If confirmation fails, the request stays pending for retry. Older backups or logs may remain."
                    : "Your Live Activities will stop and your saved matchup will be cleared. If the server is unavailable, disconnection will retry when you reopen the app or choose Retry. Security records and backups may remain.")
            }
            .interactiveDismissDisabled(manager.isBusy)
            .navigationTitle("Privacy & Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let release = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(release) (\(build))"
    }
}
