import ActivityKit
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    @Published private(set) var activity: Activity<MatchupActivityAttributes>?
    @Published private(set) var message = ""
    @Published private(set) var isBusy = false
    @Published private(set) var serverAddress = ""
    @Published private(set) var serverMode = ""
    @Published private(set) var pendingCleanup = 0
    @Published private(set) var connectionVersion = UUID()
    private let store = IntegrationStore()
    private var saved = IntegrationState()
    private var storageReady = false
    private var stateTask: Task<Void, Never>?
    private var tokenTask: Task<Void, Never>?
    private var syncTask: Task<Void, Never>?
    private var tokenTimeoutTask: Task<Void, Never>?
    private var registrationFailure: String?
    private var nextSnapshotAttempt: TimeInterval = 0

    init() {
        do {
            saved = try store.load()
            storageReady = true
            serverAddress = saved.credentials?.baseURL.absoluteString ?? ""
        } catch { message = error.localizedDescription }
        restore()
    }

    var isConnected: Bool { saved.credentials != nil }
    var hasActivity: Bool { activity != nil }
    var canConnect: Bool { storageReady && !isBusy && !hasActivity && saved.records.isEmpty }
    private var client: ServerClient? { saved.credentials.map { ServerClient(credentials: $0) } }

    func matches(leagueId: String, rosterId: Int, week: Int) -> Bool {
        guard let a = activity?.attributes else { return false }
        return a.leagueId == leagueId && a.rosterId == rosterId && a.week == week
    }

    private func change(_ update: (inout IntegrationState) -> Void) throws {
        guard storageReady else { throw ServerError.invalidResponse }
        var candidate = saved
        update(&candidate)
        try store.save(candidate)
        saved = candidate
        pendingCleanup = saved.records.filter(\.ending).count
    }

    func connect(address: String, invite: String) async -> Bool {
        guard canConnect else {
            message = "Stop your Live Activity and let pending cleanup finish before changing server access."
            return false
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let credentials = try await ServerClient.enroll(address: address, invite: invite.trimmingCharacters(in: .whitespacesAndNewlines))
            // Save a successful enrollment immediately, even if the health check fails.
            try change { $0.credentials = credentials }
            registrationFailure = nil
            serverAddress = credentials.baseURL.absoluteString
            connectionVersion = UUID()
            nextSnapshotAttempt = 0
            serverMode = (try? await ServerClient(credentials: credentials).health()) ?? "unknown"
            message = serverMode == "dry-run"
                ? "Server connected in test mode. It won't send updates to your phone yet."
                : "Server connected. Load your matchup to continue."
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func snapshot(_ selection: MatchupSelection) async throws -> ServerSnapshot {
        guard let client else { throw ServerError(status: 401, retryAfter: nil, errorDescription: "Connect your server first.") }
        let wait = nextSnapshotAttempt - Date().timeIntervalSince1970
        guard wait <= 0 else {
            throw ServerError(status: 429, retryAfter: wait, errorDescription: "Please wait before refreshing again.")
        }
        do { return try await client.snapshot(selection) }
        catch {
            if let serverError = error as? ServerError, serverError.retryable {
                nextSnapshotAttempt = Date().timeIntervalSince1970 + max(5, serverError.retryAfter ?? 75)
            }
            throw error
        }
    }

    func restore() {
        guard storageReady else { return }
        let activities = Activity<MatchupActivityAttributes>.activities
        let existing = activities.first { $0.activityState == .active || $0.activityState == .stale }
        do {
            try change { state in
                for i in state.records.indices {
                    let exists = activities.contains { $0.id == state.records[i].id && ($0.activityState == .active || $0.activityState == .stale) }
                    if !exists || state.records[i].expiresAt <= Date().timeIntervalSince1970 { state.records[i].ending = true }
                }
            }
        } catch { message = error.localizedDescription; return }
        if existing?.id != activity?.id {
            activity = existing
            if let existing { observe(existing) }
            else { stateTask?.cancel(); tokenTask?.cancel(); tokenTimeoutTask?.cancel() }
        }
        if let existing, existing.attributes.previewOnly != true {
            if let record = saved.records.first(where: { $0.id == existing.id }) {
                if record.ending {
                    Task { await self.stop() }
                } else if let token = existing.pushToken { receive(token, for: existing.id) }
            } else {
                message = "This activity has no saved server registration. Stop it and start again."
            }
        }
        sync()
    }

    func start(attributes: MatchupActivityAttributes, state: MatchupActivityAttributes.ContentState) {
        guard !isBusy else { return }
        restore()
        guard canStart(), state.yourScore.isFinite, state.opponentScore.isFinite else { return }
        do {
            let created = try Activity.request(attributes: attributes,
                content: ActivityContent(state: state, staleDate: state.staleDate), pushType: nil)
            activity = created
            message = "Preview started. It won't update automatically in the background."
            observe(created)
        } catch { message = error.localizedDescription }
    }

    func startRemote(_ selection: MatchupSelection) async -> ServerSnapshot? {
        guard !isBusy else { return nil }
        restore()
        guard canStart(), saved.records.isEmpty, let client else {
            if !saved.records.isEmpty { message = "Finishing cleanup of the previous activity. Please wait." }
            return nil
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let environment = try PushEnvironment.current()
            serverMode = try await client.health()
            guard serverMode == "live" else {
                throw ServerError(status: 422, retryAfter: nil,
                                  errorDescription: "The server is in test mode. Configure APNs and set APNS_MODE=live before starting background updates.")
            }
            let result = try await snapshot(selection)
            guard result.state.staleDate > Date() else {
                throw ServerError(status: 422, retryAfter: nil, errorDescription: "The server's scores are outdated. Refresh before starting.")
            }
            registrationFailure = nil
            let startedAt = Int(Date().timeIntervalSince1970)
            let created = try Activity.request(attributes: result.attributes,
                content: ActivityContent(state: result.state, staleDate: result.state.staleDate), pushType: .token)
            do {
                try change { $0.records.append(.init(id: created.id, selection: selection, startedAt: startedAt, environment: environment)) }
            } catch {
                await created.end(nil, dismissalPolicy: .immediate)
                throw error
            }
            activity = created
            message = "Waiting for Apple's Live Activity token…"
            observe(created)
            if let token = created.pushToken { receive(token, for: created.id) }
            tokenTimeoutTask?.cancel()
            tokenTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled, let self, self.activity?.id == created.id,
                      self.saved.records.first(where: { $0.id == created.id })?.token == nil else { return }
                self.message = "Still waiting for Apple's token. Keep the app open and check connectivity and push signing. You can stop and try again."
            }
            return result
        } catch { message = error.localizedDescription; return nil }
    }

    private func canStart() -> Bool {
        guard activity == nil else { message = "Stop your current Live Activity before starting another."; return false }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Live Activities are disabled. Enable them for SleeperLive in Settings."
            return false
        }
        return true
    }

    func stop() async {
        guard !isBusy, let current = activity else { return }
        isBusy = true
        defer { isBusy = false }
        // Persist the deletion BEFORE ending locally. A running PUT is allowed to
        // finish; the single worker then DELETEs, preventing a late registration.
        do { try change { state in
            if let i = state.records.firstIndex(where: { $0.id == current.id }) {
                state.records[i].ending = true
                state.records[i].nextAttempt = 0
            }
        } } catch { message = error.localizedDescription; return }
        tokenTask?.cancel(); tokenTimeoutTask?.cancel(); stateTask?.cancel()
        await current.end(nil, dismissalPolicy: .immediate)
        activity = nil
        message = pendingCleanup > 0 ? "Stopped on your phone. Finishing server cleanup…" : "Live Activity stopped."
        sync()
    }

    func refresh(leagueId: String, rosterId: Int, week: Int, state: MatchupActivityAttributes.ContentState) async {
        guard !isBusy, matches(leagueId: leagueId, rosterId: rosterId, week: week),
              let current = activity, current.attributes.previewOnly == true,
              state.updatedAt >= current.content.state.updatedAt,
              state.yourScore.isFinite, state.opponentScore.isFinite else { return }
        // Never race app-driven updates against remote APNs timestamps.
        await current.update(ActivityContent(state: state, staleDate: state.staleDate))
    }

    private func observe(_ current: Activity<MatchupActivityAttributes>) {
        stateTask?.cancel(); tokenTask?.cancel()
        stateTask = Task { [weak self] in
            for await state in current.activityStateUpdates {
                guard !Task.isCancelled, let self, self.activity?.id == current.id else { return }
                if state == .ended || state == .dismissed {
                    do { try self.change { saved in
                        if let i = saved.records.firstIndex(where: { $0.id == current.id }) {
                            saved.records[i].ending = true
                            saved.records[i].nextAttempt = 0
                        }
                    } } catch { self.message = error.localizedDescription; return }
                    self.activity = nil
                    self.tokenTask?.cancel(); self.tokenTimeoutTask?.cancel()
                    self.message = "Live Activity ended. You can start another after cleanup."
                    self.sync()
                    return
                }
                if state == .stale { self.message = "Scores may be outdated. Check the connection or refresh your matchup." }
            }
        }
        if current.attributes.previewOnly != true {
            tokenTask = Task { [weak self] in
                for await token in current.pushTokenUpdates {
                    guard !Task.isCancelled, let self else { return }
                    self.receive(token, for: current.id)
                }
            }
        }
    }

    private func receive(_ token: Data, for id: String) {
        guard let i = saved.records.firstIndex(where: { $0.id == id }), !saved.records[i].ending else { return }
        let value = token.map { String(format: "%02x", $0) }.joined()
        do {
            try change { state in
                if state.records[i].token != value {
                    state.records[i].token = value
                    state.records[i].failures = 0
                    state.records[i].nextAttempt = 0
                }
            }
            if saved.records[i].registeredToken != value { message = "Connecting Live Activity to the server…" }
            tokenTimeoutTask?.cancel()
            sync()
        } catch { message = error.localizedDescription }
    }

    // One serial worker owns PUT/DELETE ordering. Token observers can replace the
    // queued token while a request is in flight; the newest token is sent next.
    private func sync() {
        guard syncTask == nil, client != nil else { return }
        syncTask = Task { [weak self] in
            guard let self else { return }
            defer { self.syncTask = nil }
            while !Task.isCancelled {
                do {
                    try self.change { state in
                        for i in state.records.indices where state.records[i].expiresAt <= Date().timeIntervalSince1970 {
                            state.records[i].ending = true
                        }
                    }
                    guard let record = self.saved.records.filter(\.needsSync).min(by: { $0.nextAttempt < $1.nextAttempt }),
                          let client = self.client else { return }
                    let wait = record.nextAttempt - Date().timeIntervalSince1970
                    if wait > 0 { try await Task.sleep(for: .seconds(min(wait, 30))); continue }
                    do {
                        if record.ending { try await client.deleteActivity(record.id) }
                        else { try await client.register(record) }
                        try self.change { state in
                            guard let i = state.records.firstIndex(where: { $0.id == record.id }) else { return }
                            if record.ending { state.records.remove(at: i) }
                            else {
                                state.records[i].acknowledge(sentToken: record.token)
                            }
                        }
                        self.message = record.ending ? (self.registrationFailure ?? "Server cleanup completed.")
                            : "Registered for background updates. Delivery depends on your connection and iOS."
                    } catch {
                        if let e = error as? ServerError, !e.retryable {
                            if record.ending && [401, 403, 404, 409].contains(e.status) {
                                try self.change { $0.records.removeAll { $0.id == record.id } }
                            } else if !record.ending {
                                self.registrationFailure = e.localizedDescription
                                try self.change { state in
                                    if let i = state.records.firstIndex(where: { $0.id == record.id }) {
                                        state.records[i].ending = true
                                        state.records[i].nextAttempt = 0
                                    }
                                }
                                if let active = self.activity, active.id == record.id {
                                    self.stateTask?.cancel(); self.tokenTask?.cancel()
                                    await active.end(nil, dismissalPolicy: .immediate)
                                    self.activity = nil
                                }
                            } else {
                                // Bad endpoint/configuration: retain cleanup for the next launch,
                                // rather than hammering a server with a permanent error.
                                try self.change { state in
                                    if let i = state.records.firstIndex(where: { $0.id == record.id }) {
                                        state.records[i].nextAttempt = Date().timeIntervalSince1970 + 900
                                    }
                                }
                            }
                            self.message = e.localizedDescription
                        } else {
                            try self.change { state in
                                guard let i = state.records.firstIndex(where: { $0.id == record.id }) else { return }
                                // A stop or token rotation during the failed request takes priority.
                                state.records[i].retry(failed: record, retryAfter: (error as? ServerError)?.retryAfter,
                                                       now: Date().timeIntervalSince1970)
                            }
                            self.message = record.ending ? "Stopped locally. Server cleanup will retry when connected."
                                : "Couldn't register yet. Retrying when connected; scores may become outdated."
                        }
                    }
                } catch { self.message = error.localizedDescription; return }
            }
        }
    }
}
