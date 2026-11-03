import SwiftUI

struct AppSettingsView: View {
    @ObservedObject var manager: LiveActivityManager
    let username: String
    let leagueName: String?
    let isLoading: Bool
    var onChangeLeague: () async -> Void
    var onEnableUpdates: () -> Void
    var onPrivacyAndHelp: () -> Void
    var onSample: () -> Void
    var onEndSession: (Bool) async -> Void
    @State private var showSessionConfirmation = false
    @State private var deleting = false

    private var busy: Bool { isLoading || manager.isBusy }
    private var hasSession: Bool {
        !username.isEmpty || manager.hasSavedDeviceAccess || manager.hasActivity || manager.disconnectPending
    }

    var body: some View {
        Form {
            Section("Account") {
                if username.isEmpty {
                    Text("No Sleeper username selected").foregroundStyle(.secondary)
                } else {
                    LabeledContent("Sleeper username", value: username)
                    if let leagueName { LabeledContent("League", value: leagueName) }
                    Button("Change league") { Task { await onChangeLeague() } }
                        .disabled(busy)
                }
            }

            Section("Background updates") {
                DeviceRegistrationStatusView(manager: manager)
                if manager.disconnectPending {
                    Button(manager.deviceDataDeletionPending ? "Retry data deletion" : "Retry previous disconnection") {
                        Task { await onEndSession(manager.deviceDataDeletionPending) }
                    }
                    .disabled(busy)
                } else if manager.isSessionPaused {
                    Text("Enter a Sleeper username on Matchup to reuse this device’s registration.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if !manager.isConnected {
                    Button("Enable background updates", action: onEnableUpdates)
                        .disabled(busy)
                }
                if !manager.message.isEmpty {
                    Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Live Activities") {
                LiveActivitySettingsView(showDisabledExplanation: !manager.liveActivitiesEnabled)
            }

            Section("Help") {
                Button(action: onPrivacyAndHelp) {
                    Label("Privacy & Help", systemImage: "hand.raised")
                }
                Button(action: onSample) {
                    Label("Try a sample matchup", systemImage: "testtube.2")
                }
                .disabled(busy)
            }

            Section {
                Button("Log out", role: .destructive) {
                    deleting = false
                    showSessionConfirmation = true
                }
                .disabled(busy || (username.isEmpty && !manager.hasActivity) || manager.disconnectPending)
                Button("Delete SleeperLive data", role: .destructive) {
                    deleting = true
                    showSessionConfirmation = true
                }
                .disabled(busy || !hasSession || manager.disconnectPending)
            } header: {
                Text("Session & data")
            } footer: {
                Text("Log out stops Live Activities and clears the saved username and matchup, keeping this device’s registration and background-update choice for your next login. Delete SleeperLive data removes its current registration and activity records from the active server database and clears the saved matchup. Neither action deletes your Sleeper account or other devices. Previously disconnected registrations, backups, and logs may remain.")
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(deleting ? "Delete SleeperLive data?" : "Log out of SleeperLive?",
                            isPresented: $showSessionConfirmation, titleVisibility: .visible) {
            Button(deleting ? "Delete SleeperLive data" : "Log out", role: .destructive) {
                Task { await onEndSession(deleting) }
            }
        } message: {
            Text(deleting
                ? "Your Live Activities will stop, the saved matchup will be cleared, and this device’s current server registration and activity records will be deleted. Deletion cannot be undone. Older backups and logs may remain. Your Sleeper account is unaffected."
                : "Your Live Activities will stop and the saved username and matchup will be cleared. This device’s registration and previous background-update choice are kept and can resume when you log in again. Your Sleeper account is unaffected.")
        }
    }
}
