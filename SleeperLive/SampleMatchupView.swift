import ActivityKit
import SwiftUI

private enum SampleMatchup {
    static let leagueID = "sample-matchup"
    static let attributes = MatchupActivityAttributes(
        leagueName: "Sample matchup", yourName: "Sample Home", opponentName: "Sample Away",
        week: 1, leagueId: leagueID, rosterId: 1, previewOnly: true
    )

    static func state(afterUpdate: Bool) -> MatchupActivityAttributes.ContentState {
        .init(yourScore: afterUpdate ? 91.42 : 84.32, opponentScore: 79.18,
              yourProjected: nil, opponentProjected: nil,
              yourProjectionKind: "unavailable", opponentProjectionKind: "unavailable",
              updatedAt: Int(Date().timeIntervalSince1970))
    }
}

struct SampleMatchupView: View {
    @ObservedObject var manager: LiveActivityManager
    @Environment(\.dismiss) private var dismiss
    @State private var updated = false
    @State private var applyingUpdate = false

    private var showingSampleActivity: Bool {
        manager.activity?.attributes.leagueId == SampleMatchup.leagueID
            && manager.activity?.attributes.previewOnly == true
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Sample matchup", systemImage: "testtube.2")
                        .font(.headline)
                    Text("Fictional teams and scores. No Sleeper username is needed, and these sample scores are not sent to the background-update server.")
                    Text("This preview updates only when you tap Simulate score update. It does not receive live game data.")
                        .foregroundStyle(.secondary)
                }

                Section("Week 1 · Sample scores") {
                    scoreRow("Sample Home", score: updated ? 91.42 : 84.32)
                    scoreRow("Sample Away", score: 79.18)
                }

                Section("Try the Lock Screen") {
                    if showingSampleActivity {
                        Button("Stop sample Live Activity", role: .destructive) {
                            Task { await manager.stop() }
                        }
                        .disabled(manager.isBusy || applyingUpdate)
                    } else {
                        Button("Start sample Live Activity") {
                            manager.start(attributes: SampleMatchup.attributes,
                                          state: SampleMatchup.state(afterUpdate: updated))
                        }
                        .disabled(manager.hasActivity || manager.isBusy || applyingUpdate || manager.disconnectPending)
                    }

                    Button(updated ? "Reset sample scores" : "Simulate score update") {
                        updated.toggle()
                        applyingUpdate = true
                        Task {
                            defer { applyingUpdate = false }
                            await manager.refresh(leagueId: SampleMatchup.leagueID, rosterId: 1, week: 1,
                                                  state: SampleMatchup.state(afterUpdate: updated))
                        }
                    }
                    .disabled(manager.isBusy || applyingUpdate)

                    if manager.hasActivity && !showingSampleActivity {
                        Text("You already have a Live Activity running. Stop it from your matchup before starting a sample.")
                    }
                    if manager.disconnectPending {
                        Text("Finish device disconnection in Privacy & Help before starting a sample Live Activity.")
                    }
                    Text("After starting, lock your iPhone to see the preview. It stays visible until you stop or dismiss it, or iOS ends it. Stop the sample before starting a real matchup.")
                        .foregroundStyle(.secondary)
                    if !manager.message.isEmpty {
                        Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                if showingSampleActivity, let activity = manager.activity {
                    updated = activity.content.state.yourScore > 90
                }
            }
            .navigationTitle("Try SleeperLive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(manager.isBusy || applyingUpdate)
                }
            }
            .interactiveDismissDisabled(manager.isBusy || applyingUpdate)
        }
    }

    private func sampleScore(_ score: Double) -> some View {
        Text(score, format: .number.precision(.fractionLength(2)))
            .font(.title2.bold()).monospacedDigit().fixedSize()
    }

    private func scoreRow(_ name: String, score: Double) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(name).font(.headline).fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 16)
                sampleScore(score)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(name).font(.headline)
                sampleScore(score)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Sample team \(name), actual score \(score, format: .number.precision(.fractionLength(2)))"))
    }
}
