import SwiftUI

struct BackgroundUpdatesConsentView: View {
    @ObservedObject var manager: LiveActivityManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Follow this matchup on your Lock Screen?", systemImage: "lock.rectangle")
                        .font(.headline)
                    Text("Background updates connect this device to the SleeperLive service hosted on Railway. You can keep using username lookup, manual score refreshes, and the sample matchup without enabling them.")
                }
                Section("What enabling sends") {
                    Text("To register this device, SleeperLive sends Apple App Attest verification information and a device access credential hash. The server keeps device and security identifiers to manage access and prevent abuse.")
                    Text("When you load a matchup through the connected service, its league, roster, and week are sent to the server. Starting a Live Activity also sends its update token and start time so Apple’s push service can deliver scores.")
                    Text("Network services process connection information, including your IP address. No Sleeper password is requested.")
                }
                Section("Your choice") {
                    Text("You can log out from Settings to disconnect this device and clear its saved matchup. Server security records, logs, and backups may remain. Logging out is not full data deletion.")
                    Button("Enable background updates") {
                        Task {
                            await manager.resumeBackgroundUpdates()
                            if manager.isConnected { dismiss() }
                        }
                    }
                    .disabled(!manager.canConnect)
                    Button("Not now") { dismiss() }
                        .disabled(manager.isBusy)
                    if manager.hasActivity {
                        Text("Stop the current Live Activity before enabling background updates.")
                    }
                    if manager.isBusy { ProgressView("Connecting…") }
                    if !manager.message.isEmpty {
                        Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Background updates")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(manager.isBusy)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.disabled(manager.isBusy)
                }
            }
        }
    }
}
