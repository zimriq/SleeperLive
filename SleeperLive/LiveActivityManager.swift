import ActivityKit
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    @Published private(set) var activity: Activity<MatchupActivityAttributes>?
    @Published private(set) var message = ""
    @Published private(set) var isBusy = false
    private var stateTask: Task<Void, Never>?

    init() { restore() }

    var hasActivity: Bool { activity != nil }

    func matches(leagueId: String, rosterId: Int, week: Int) -> Bool {
        guard let attributes = activity?.attributes else { return false }
        return attributes.leagueId == leagueId && attributes.rosterId == rosterId
            && attributes.week == week
    }

    // ActivityKit retains activities even when the app process is terminated.
    func restore() {
        let existing = Activity<MatchupActivityAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
        if existing?.id != activity?.id {
            activity = existing
            if let existing { observe(existing) }
            else { stateTask?.cancel() }
        }
    }

    func start(attributes: MatchupActivityAttributes,
               state: MatchupActivityAttributes.ContentState) {
        guard !isBusy else { return }
        restore()
        guard activity == nil else {
            message = "Stop your current Live Activity before starting another."
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Live Activities are disabled. Enable them for SleeperLive in Settings."
            return
        }
        guard state.yourScore.isFinite, state.opponentScore.isFinite else {
            message = "Refresh your matchup before starting a Live Activity."
            return
        }
        do {
            // This milestone is a local preview, so it doesn't request an APNs token.
            let created = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: state.staleDate),
                pushType: nil
            )
            activity = created
            message = "Preview started. Lock your phone to see it."
            observe(created)
        } catch {
            message = "Couldn't start the Live Activity. \(error.localizedDescription)"
        }
    }

    func stop() async {
        guard !isBusy, let current = activity else { return }
        isBusy = true
        defer { isBusy = false }
        await current.end(nil, dismissalPolicy: .immediate)
        stateTask?.cancel()
        activity = nil
        message = "Live Activity stopped."
    }

    func refresh(leagueId: String, rosterId: Int, week: Int,
                 state: MatchupActivityAttributes.ContentState) async {
        guard !isBusy, matches(leagueId: leagueId, rosterId: rosterId, week: week),
              let current = activity, current.attributes.previewOnly == true,
              state.updatedAt >= current.content.state.updatedAt,
              state.yourScore.isFinite, state.opponentScore.isFinite else { return }
        // Only local previews use app-driven updates. Remote pushes come next.
        await current.update(ActivityContent(state: state, staleDate: state.staleDate))
    }

    private func observe(_ current: Activity<MatchupActivityAttributes>) {
        stateTask?.cancel()
        stateTask = Task { [weak self] in
            for await state in current.activityStateUpdates {
                guard !Task.isCancelled, let self, self.activity?.id == current.id else { return }
                if state == .ended || state == .dismissed {
                    self.activity = nil
                    self.message = "Live Activity ended. You can start another preview."
                    return
                }
            }
        }
    }
}
