import SwiftUI
import UIKit

struct LiveActivitySettingsView: View {
    var showDisabledExplanation = true
    @Environment(\.openURL) private var openURL
    @State private var settingsUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showDisabledExplanation {
                Label("Live Activities aren’t available", systemImage: "lock.rectangle")
                    .font(.headline)
                Text("Check that Live Activities are enabled for SleeperLive in iPhone Settings. You can still view scores and refresh them in the app.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    settingsUnavailable = true
                    return
                }
                openURL(url) { accepted in settingsUnavailable = !accepted }
            } label: {
                Label("Open iPhone Settings", systemImage: "gearshape")
            }
            .accessibilityHint("Opens SleeperLive’s settings. Return here after changing Live Activities.")
        }
        .alert("Open Settings manually", isPresented: $settingsUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Open the Settings app, find SleeperLive under Apps, and check Live Activities. If the option is unavailable, your device or system settings may restrict it.")
        }
    }
}
