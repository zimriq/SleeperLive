import SwiftUI

struct DeviceRegistrationStatusView: View {
    @ObservedObject var manager: LiveActivityManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if manager.isBusy {
                ProgressView("Updating device connection…")
            } else if manager.disconnectPending {
                Label(manager.deviceDataDeletionPending ? "Device deletion pending" : "Device disconnection pending",
                      systemImage: "clock")
                Text("The server request is unfinished. Use the retry control when connected.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else if manager.isConnected {
                Label("Device registration saved", systemImage: "checkmark.shield")
                if manager.serverMode == "dry-run" {
                    Text("Test mode · Remote score updates are off.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    Text("Registration alone does not confirm Live Activity score delivery.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                Label("Background updates are off", systemImage: "pause.circle")
                if !manager.message.isEmpty {
                    Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
