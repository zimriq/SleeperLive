import SwiftUI

struct ServerSetupView: View {
    @ObservedObject var manager: LiveActivityManager
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var invitation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Private testing") {
                    Text("Connect to your SleeperLive server to enable Lock Screen updates while the app is closed.")
                    TextField("https://your-server.up.railway.app", text: $address)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityLabel("Server address")
                    SecureField("Tester invitation", text: $invitation)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button(manager.isConnected ? "Reconnect server" : "Connect server") {
                        Task {
                            if await manager.connect(address: address, invite: invitation) {
                                invitation = ""
                                dismiss()
                            }
                        }
                    }
                    .disabled(!manager.canConnect || invitation.isEmpty || address.isEmpty)
                    if manager.isBusy { ProgressView("Connecting…") }
                }
                Section {
                    if manager.isConnected {
                        Text("Connected: \(manager.serverAddress)").font(.footnote)
                        if !manager.serverMode.isEmpty { Text("Server mode: \(manager.serverMode)") }
                    }
                    if manager.hasActivity || manager.pendingCleanup > 0 {
                        Text("Stop your Live Activity and finish its server cleanup before reconnecting.")
                    }
                    if !manager.message.isEmpty { Text(manager.message).font(.footnote) }
                }
                Section("About updates") {
                    Text("The server checks scores about every 75 seconds. iOS and network conditions can delay delivery. Outdated scores are marked on your Lock Screen.")
                    Text("Proj. values are experimental estimates when available. Missing projections appear as a dash; actual scores remain visible.")
                    Text("For remote updates, use a physical iPhone with Push Notifications signing configured. No Apple signing keys belong in this app.")
                }
            }
            .navigationTitle("Server setup")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.disabled(manager.isBusy) } }
            .interactiveDismissDisabled(manager.isBusy)
            .onAppear { address = manager.serverAddress }
        }
    }
}
