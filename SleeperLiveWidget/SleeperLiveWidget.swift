import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SleeperLiveWidgetBundle: WidgetBundle {
    var body: some Widget { MatchupLiveActivity() }
}

struct MatchupLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchupActivityAttributes.self) { context in
            VStack(spacing: 12) {
                HStack {
                    Text(context.attributes.leagueName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("Week \(context.attributes.week)").font(.caption)
                }
                .foregroundStyle(.white.opacity(0.75))
                HStack(alignment: .top, spacing: 16) {
                    team(name: context.attributes.yourName, score: context.state.yourScore,
                         projected: context.state.yourProjected)
                    Text("VS").font(.caption2.bold()).foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 28)
                    team(name: context.attributes.opponentName, score: context.state.opponentScore,
                         projected: context.state.opponentProjected)
                }
                status(context)
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 0.04, green: 0.12, blue: 0.09))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    team(name: context.attributes.yourName, score: context.state.yourScore,
                         projected: context.state.yourProjected)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    team(name: context.attributes.opponentName, score: context.state.opponentScore,
                         projected: context.state.opponentProjected)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text("Week \(context.attributes.week)").font(.caption)
                        status(context)
                    }
                }
            } compactLeading: {
                Text(context.state.yourScore, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit().foregroundStyle(.green)
                    .accessibilityLabel("Your score \(context.state.yourScore)")
            } compactTrailing: {
                Text(context.state.opponentScore, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .accessibilityLabel("Opponent score \(context.state.opponentScore)")
            } minimal: {
                Image(systemName: context.isStale ? "clock.badge.exclamationmark" : "sportscourt.fill")
                    .foregroundStyle(context.isStale ? .orange : .green)
                    .accessibilityLabel(context.isStale ? "Matchup needs refresh" : "Matchup preview")
            }
            .keylineTint(.green)
        }
    }

    private func team(name: String, score: Double, projected: Double?) -> some View {
        VStack(spacing: 6) {
            Text(name).font(.caption.weight(.semibold)).lineLimit(2)
                .multilineTextAlignment(.center)
            Text(score, format: .number.precision(.fractionLength(2)))
                .font(.title2.bold()).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            if let projected, projected.isFinite {
                Text("Proj. \(projected, format: .number.precision(.fractionLength(2)))")
                    .font(.caption2).foregroundStyle(.white.opacity(0.7))
            } else {
                Text("Proj. —").font(.caption2).foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func status(_ context: ActivityViewContext<MatchupActivityAttributes>) -> some View {
        VStack(spacing: 3) {
            if context.isStale {
                Text("Scores may be outdated · Open app to refresh")
                    .foregroundStyle(.orange)
            } else {
                Text("Updated \(context.state.updatedDate, style: .time)")
                    .foregroundStyle(.white.opacity(0.7))
            }
            if context.attributes.previewOnly == true {
                Text("Preview · No automatic background updates")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .font(.caption2)
        .multilineTextAlignment(.center)
    }
}

private let sampleAttributes = MatchupActivityAttributes(
    leagueName: "Sunday League", yourName: "Rigo FC", opponentName: "Cocolans republic",
    week: 7, leagueId: "123456789", rosterId: 4, previewOnly: true
)
private let sampleState = MatchupActivityAttributes.ContentState(
    yourScore: 83.42, opponentScore: 76.18, yourProjected: nil, opponentProjected: nil,
    yourProjectionKind: "unavailable", opponentProjectionKind: "unavailable",
    updatedAt: Int(Date().timeIntervalSince1970)
)

#Preview("Matchup", as: .content, using: sampleAttributes) {
    MatchupLiveActivity()
} contentStates: {
    sampleState
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: sampleAttributes) {
    MatchupLiveActivity()
} contentStates: {
    sampleState
}
