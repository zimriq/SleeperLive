import SwiftUI
import ActivityKit

// Data we receive from Sleeper.
struct SleeperUser: Decodable {
    let user_id: String
    let display_name: String?
}

struct SleeperLeague: Decodable, Identifiable {
    let league_id: String
    let name: String

    var id: String {
        league_id
    }
}

struct NFLState: Decodable {
    let league_season: String
    let week: Int
}

struct SleeperRoster: Decodable {
    let roster_id: Int
    let owner_id: String?
    let co_owners: [String]?
}

struct SleeperMatchup: Decodable {
    let roster_id: Int
    let matchup_id: Int?
    let points: Double?
    let custom_points: Double?
}

struct SleeperLeagueUser: Decodable {
    let user_id: String
    let display_name: String?
    let metadata: SleeperLeagueUserMetadata?
}

struct SleeperLeagueUserMetadata: Decodable {
    let team_name: String?
}

struct ContentView: View {
    @StateObject private var liveActivity = LiveActivityManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var scoreUpdatedAt: Int?
    @State private var showServerSetup = false
    @State private var serverSnapshot: ServerSnapshot?
    @State private var selectionVersion = UUID()

    @AppStorage("lastSuccessfulUsername") private var rememberedUsername = ""
    @AppStorage("lastSelectedLeagueID") private var rememberedLeagueID = ""
    @State private var didRestoreAccount = false
    @State private var username = ""
    @State private var lookupMessage = ""
    @State private var sleeperUser: SleeperUser? = nil
    @State private var leagues: [SleeperLeague] = []
    @State private var selectedLeague: SleeperLeague? = nil
    @State private var myRosterID: Int? = nil
    @State private var isLoading: Bool = false
    @State private var currentWeek: Int? = nil
    @State private var yourScore: Double? = nil
    @State private var opponentScore: Double? = nil
    @State private var leagueRosters: [SleeperRoster] = []
    @State private var opponentRosterID: Int? = nil
    @State private var yourTeamName: String = "You"
    @State private var opponentTeamName: String = "Opponent"
    @State private var showLeagueSelection: Bool = false
    @State private var showMatchup: Bool = false
    
    // Shared visual styling keeps all three screens consistent.
    private let accentColor = Color(red: 0.05, green: 0.43, blue: 0.25)
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 60

    var welcomeView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleeper\nLive")
                    .font(.system(size: titleSize, weight: .heavy))
                    .tracking(-2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Your Sleeper matchup, on the Lock Screen.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Sleeper username")
                    .font(.subheadline.weight(.semibold))
                TextField("e.g. rigo_fc", text: $username)
                    .textFieldStyle(.plain)
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Sleeper username")
                Text("No password needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            lookupFeedback
            if let activity = liveActivity.activity {
                Text("Active: \(activity.attributes.leagueName) · Week \(activity.attributes.week)")
                    .font(.footnote)
                Button("Stop Live Activity", role: .destructive) { Task { await liveActivity.stop() } }
                    .disabled(liveActivity.isBusy)
            }
            Button(liveActivity.isConnected ? "Server connected · Settings" : "Set up background updates") {
                showServerSetup = true
            }
            .font(.footnote)
            .disabled(isLoading || liveActivity.isBusy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var leagueSelectionView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a league")
                    .font(.largeTitle.bold())
                if let sleeperUser {
                    Text("Account: \(sleeperUser.display_name ?? username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 12) {
                ForEach(leagues) { league in
                    Button {
                        // Also blocks keyboard/VoiceOver activation during a request.
                        guard !isLoading, !liveActivity.isBusy else { return }
                        selectionVersion = UUID()
                        serverSnapshot = nil
                        scoreUpdatedAt = nil
                        opponentRosterID = nil
                        myRosterID = nil
                        opponentScore = nil
                        yourScore = nil
                        yourTeamName = "You"
                        opponentTeamName = "Opponent"
                        selectedLeague = league
                        rememberedLeagueID = league.league_id
                        Task {
                            await findMyRoster(league: league)
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Text(league.name)
                                .font(.body.weight(.semibold))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            if isLoading && selectedLeague?.league_id == league.league_id {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(isLoading && selectedLeague?.league_id == league.league_id
                                         ? Color.secondary : Color.primary)
                        .padding(20)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 18))
                        .contentShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading && selectedLeague?.league_id == league.league_id)
                }
            }
            .allowsHitTesting(!isLoading && !liveActivity.isBusy)
            lookupFeedback
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var matchupView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                if let selectedLeague {
                    Text(selectedLeague.name)
                        .font(.title.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let currentWeek {
                    Text("Week \(currentWeek)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if let yourScore, let opponentScore {
                VStack(spacing: 20) {
                    teamScoreRow(name: yourTeamName, role: "Your team", score: yourScore, projected: activityState?.yourProjected)
                    Divider()
                    teamScoreRow(name: opponentTeamName, role: "Opponent", score: opponentScore, projected: activityState?.opponentProjected)
                }
                .padding(24)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 24))
            }
            lookupFeedback
            liveActivityControls
            Text(liveActivity.isConnected ? "Updates are requested about every 75 seconds; delivery can vary. Proj. values are experimental estimates, not Sleeper’s official live projections." : "Connect your server for automatic background updates. Local previews update only when you refresh here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedMatchup: MatchupSelection? {
        guard let league = selectedLeague, let week = currentWeek, let rosterId = myRosterID else { return nil }
        return .init(leagueId: league.league_id, week: week, rosterId: rosterId)
    }

    private var activityState: MatchupActivityAttributes.ContentState? {
        if liveActivity.isConnected { return serverSnapshot?.state }
        guard let yourScore, let opponentScore, let scoreUpdatedAt else { return nil }
        return .init(yourScore: yourScore, opponentScore: opponentScore,
                     yourProjected: nil, opponentProjected: nil,
                     yourProjectionKind: "unavailable", opponentProjectionKind: "unavailable",
                     updatedAt: scoreUpdatedAt)
    }

    private var liveActivityControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let state = activityState {
                TimelineView(.periodic(from: .now, by: 30)) { timeline in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Updated \(state.updatedDate, style: .time)")
                        if timeline.date >= state.staleDate {
                            Text("Scores may be outdated. Refresh to get the latest.")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button {
                guard !isLoading, let selectedLeague else { return }
                isLoading = true
                Task {
                    defer { isLoading = false }
                    await findMatchup(league: selectedLeague, navigate: false)
                }
            } label: {
                Label("Refresh scores", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isLoading || liveActivity.isBusy)

            if liveActivity.hasActivity {
                if let activity = liveActivity.activity {
                    Text("On your Lock Screen: \(activity.attributes.leagueName) · Week \(activity.attributes.week)")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Button("Stop Live Activity", role: .destructive) {
                    Task { await liveActivity.stop() }
                }
                .buttonStyle(.bordered)
                .disabled(liveActivity.isBusy)
            } else {
                Button {
                    guard let league = selectedLeague, let week = currentWeek,
                          let rosterId = myRosterID, let state = activityState else { return }
                    if liveActivity.isConnected, let selection = selectedMatchup {
                        let version = selectionVersion
                        Task {
                            if let result = await liveActivity.startRemote(selection),
                               version == selectionVersion, selection == selectedMatchup {
                                applySnapshot(result)
                            }
                        }
                    } else {
                        liveActivity.start(attributes: .init(
                            leagueName: league.name, yourName: yourTeamName,
                            opponentName: opponentTeamName, week: week,
                            leagueId: league.league_id, rosterId: rosterId, previewOnly: true
                        ), state: state)
                    }
                } label: {
                    Label(liveActivity.isConnected ? "Start Live Activity" : "Preview Live Activity", systemImage: "lock.rectangle")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .disabled(isLoading || activityState == nil || liveActivity.isBusy)
            }
            if !liveActivity.message.isEmpty {
                Text(liveActivity.message).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func teamScoreRow(name: String, role: String, score: Double, projected: Double?) -> some View {
        // Large accessibility text can place the score below the name instead.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                teamNameLabel(name: name, role: role)
                Spacer(minLength: 8)
                scoreLabel(score, projected: projected)
            }
            VStack(alignment: .leading, spacing: 12) {
                teamNameLabel(name: name, role: role)
                scoreLabel(score, projected: projected)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func teamNameLabel(name: String, role: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(role)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func scoreLabel(_ score: Double, projected: Double?) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(score, format: .number.precision(.fractionLength(2)))
                .font(.largeTitle.weight(.bold)).monospacedDigit().fixedSize()
            if let projected {
                Text("Proj. \(projected, format: .number.precision(.fractionLength(2)))")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Proj. —").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var lookupFeedback: some View {
        HStack(alignment: .top, spacing: 10) {
            if isLoading { ProgressView() }
            if !lookupMessage.isEmpty {
                Text(lookupMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var findAccountButton: some View {
        Button {
            guard !isLoading, !liveActivity.isBusy else { return }
            Task { await findUser() }
        } label: {
            Text("Find my account")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .disabled(isLoading)
        .buttonStyle(.borderedProminent)
        .tint(accentColor)
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                welcomeView.padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                findAccountButton
                    .padding(24)
                    .background(Color(uiColor: .systemGroupedBackground))
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationDestination(isPresented: $showLeagueSelection) {
                ScrollView {
                    leagueSelectionView.padding(24)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showMatchup) {
                    ScrollView {
                        matchupView.padding(24)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .tint(accentColor)
        .task {
            guard !didRestoreAccount else { return }
            didRestoreAccount = true
            guard !rememberedUsername.isEmpty else { return }
            username = rememberedUsername
            let leagueID = rememberedLeagueID
            await findUser()
            guard !Task.isCancelled,
                  let league = leagues.first(where: { $0.league_id == leagueID }) else { return }
            selectedLeague = league
            // Load fresh scores and the current week instead of restoring stale scores.
            await findMyRoster(league: league)
        }
        .sheet(isPresented: $showServerSetup) { ServerSetupView(manager: liveActivity) }
        .onChange(of: liveActivity.connectionVersion) { _, _ in
            selectionVersion = UUID()
            serverSnapshot = nil
            scoreUpdatedAt = nil
            yourScore = nil
            opponentScore = nil
        }
        .task(id: "\(scenePhase)-\(showMatchup)-\(selectedMatchup?.leagueId ?? "")-\(selectedMatchup?.week ?? 0)-\(selectedMatchup?.rosterId ?? 0)-\(liveActivity.connectionVersion)") {
            guard scenePhase == .active, showMatchup, liveActivity.isConnected else { return }
            while !Task.isCancelled {
                if !isLoading, !liveActivity.isBusy, let league = selectedLeague {
                    isLoading = true
                    await findMatchup(league: league, navigate: false)
                    isLoading = false
                }
                do { try await Task.sleep(for: .seconds(75)) } catch { return }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { liveActivity.restore() }
        }
    }

    // User lookup and loading leagues tied to it
    func findUser() async {
        selectionVersion = UUID()
        serverSnapshot = nil
        scoreUpdatedAt = nil
        currentWeek = nil
        sleeperUser = nil
        leagues = []
        selectedLeague = nil
        myRosterID = nil
        opponentRosterID = nil
        yourScore = nil
        opponentScore = nil
        yourTeamName = "You"
        opponentTeamName = "Opponent"

        let cleanUsername = username.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanUsername.isEmpty else {
            lookupMessage = "Enter your Sleeper username."
            return
        }
        isLoading = true
        defer {
            isLoading = false
        }

        let url = URL(string: "https://api.sleeper.app/v1/user")!
            .appendingPathComponent(cleanUsername)

        lookupMessage = "Looking up your account..."

        do {
            let (data, response) = try await URLSession.shared.data(
                from: url
            )

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lookupMessage = "Sleeper couldn't complete the request."
                return
            }

            let user = try JSONDecoder().decode(
                SleeperUser?.self,
                from: data
            )

            if let user {
                if rememberedUsername.caseInsensitiveCompare(cleanUsername) != .orderedSame {
                    rememberedLeagueID = ""
                }
                rememberedUsername = cleanUsername
                sleeperUser = user
                lookupMessage = "Found: \(user.display_name ?? cleanUsername)"
                await findLeagues(for: user.user_id)
            } else {
                lookupMessage = "Username not found."
            }
        } catch {
            lookupMessage = "Couldn't load your account, please try again."
        }
    }

    // Finds the leagues for the current user and current year
    func findLeagues(for userID: String) async {
        lookupMessage = "Loading leagues..."

        do {
            let season = try await fetchLeagueSeason()

            let url = URL(string: "https://api.sleeper.app/v1/user")!
                .appendingPathComponent(userID)
                .appendingPathComponent("leagues")
                .appendingPathComponent("nfl")
                .appendingPathComponent(season)

            let (data, response) = try await URLSession.shared.data(
                from: url
            )

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lookupMessage = "Couldn't load leagues."
                return
            }

            leagues = try JSONDecoder().decode(
                [SleeperLeague].self,
                from: data
            )

            lookupMessage = leagues.isEmpty
                ? "No leagues found for \(season)."
                : "Found \(leagues.count) leagues."
            
            if !leagues.isEmpty {
                showLeagueSelection = true
            }
        } catch {
            lookupMessage = "Couldn't load leagues. Please try again."
        }
    }

    // Gets the league season instead of hardcoding
    func fetchLeagueSeason() async throws -> String {
        let url = URL(string: "https://api.sleeper.app/v1/state/nfl")!

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let state = try JSONDecoder().decode(
            NFLState.self,
            from: data
        )

        currentWeek = state.week
        return state.league_season
    }

    // match your user ID to a roster.
    func findMyRoster(league: SleeperLeague) async {
        guard let sleeperUser = sleeperUser else {
            lookupMessage = "user is missing"
            return
        }
        isLoading = true
        defer {
            isLoading = false
        }
        
        do{
            let url = URL(string: "https://api.sleeper.app/v1/league")!
                .appendingPathComponent(league.league_id)
                .appendingPathComponent("rosters")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lookupMessage = "Couldn't load roster, please try again"
                return
            }
            let rosters = try JSONDecoder().decode([SleeperRoster].self, from: data)
            leagueRosters = rosters
            
            let myRoster = rosters.first { roster in
                roster.owner_id == sleeperUser.user_id
                    || roster.co_owners?.contains(sleeperUser.user_id) == true
            }
            myRosterID = myRoster?.roster_id
            
            if let myRoster { lookupMessage = "Found your roster \(myRoster.roster_id)"
                await findMatchup(league: league)
            }
            else { lookupMessage = "No roster belonging to this account was found in selected league."}
        } catch {
            lookupMessage = "Couldn't find roster."
        }
    }
    
    // Fetches the selected week's matchup and finds the opponent.
    func findMatchup(league: SleeperLeague, navigate: Bool = true) async {
        guard let myRosterID = myRosterID else {
            lookupMessage = "roster id is missing"
            return
        }
        guard let currentWeek = currentWeek else {
            lookupMessage = "current week is missing"
            return
        }
        
        let version = selectionVersion
        let connection = liveActivity.connectionVersion
        if liveActivity.isConnected {
            do {
                let selection = MatchupSelection(leagueId: league.league_id, week: currentWeek, rosterId: myRosterID)
                let result = try await liveActivity.snapshot(selection)
                guard !Task.isCancelled, version == selectionVersion,
                      connection == liveActivity.connectionVersion, selectedMatchup == selection else { return }
                if serverSnapshot == nil || result.state.updatedAt >= serverSnapshot!.state.updatedAt {
                    applySnapshot(result)
                }
                lookupMessage = "Matchup loaded."
                if navigate { showMatchup = true }
            } catch {
                guard !Task.isCancelled, version == selectionVersion else { return }
                lookupMessage = error.localizedDescription
            }
            return
        }

        do{
            let url = URL(string: "https://api.sleeper.app/v1/league")!
                .appendingPathComponent(league.league_id)
                .appendingPathComponent("matchups")
                .appendingPathComponent(String(currentWeek))
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lookupMessage = "Couldn't load matchup, please try again"
                return
            }
            
            guard !Task.isCancelled, version == selectionVersion, connection == liveActivity.connectionVersion else { return }
            let matchups = try JSONDecoder().decode([SleeperMatchup].self, from: data)
            let myMatchup = matchups.first {
                matchup in matchup.roster_id == myRosterID
            }
            
            guard let myMatchup = myMatchup else {
                lookupMessage = "Your team has no matchup for this week"
                return
            }
            guard let matchupID = myMatchup.matchup_id else {
                lookupMessage = "No opponent is assigned for this week"
                return
            }
            
            //finding opponent
            let opponentMatchup = matchups.first {
                matchup in matchup.matchup_id == matchupID &&
                matchup.roster_id != myRosterID
            }
            
            guard let opponentMatchup = opponentMatchup else {
                lookupMessage = "No opponent is found."
                return
            }
            opponentRosterID = opponentMatchup.roster_id
            
            guard let ownPoints = myMatchup.custom_points ?? myMatchup.points,
                  let otherPoints = opponentMatchup.custom_points ?? opponentMatchup.points,
                  ownPoints.isFinite, otherPoints.isFinite else {
                lookupMessage = "Scores are unavailable. Please try again."
                return
            }
            yourScore = ownPoints
            opponentScore = otherPoints
            scoreUpdatedAt = Int(Date().timeIntervalSince1970)
            lookupMessage = "Matchup loaded."
            
            await findTeamNames(league: league)
            if let state = activityState {
                await liveActivity.refresh(leagueId: league.league_id, rosterId: myRosterID,
                                           week: currentWeek, state: state)
            }
            if navigate { showMatchup = true }
        } catch {
            lookupMessage = "Couldn't find matchup."
        }
                
    }
    
    func findTeamNames(league: SleeperLeague) async {
        guard let myRosterID = myRosterID, let opponentRosterID = opponentRosterID else {
            lookupMessage = "Roster IDs not found."
            return
        }
        
        let url = URL(string: "https://api.sleeper.app/v1/league")!
            .appendingPathComponent(league.league_id)
            .appendingPathComponent("users")
        
        do{
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lookupMessage = "Couldn't load team name."
                return
            }
            
            let leagueUsers = try JSONDecoder().decode([SleeperLeagueUser].self, from: data)
            let yourRoster = leagueRosters.first{roster in roster.roster_id == myRosterID }
            let opponentRoster = leagueRosters.first{roster in roster.roster_id == opponentRosterID }
            
            guard let yourRoster = yourRoster, let opponentRoster = opponentRoster else {
                lookupMessage = "Rosters not found."
                return
            }
            
            let yourLeagueUser = leagueUsers.first{ user in user.user_id == yourRoster.owner_id }
            let opponentLeagueUser = leagueUsers.first{ user in user.user_id == opponentRoster.owner_id }
            
            yourTeamName = yourLeagueUser?.metadata?.team_name ?? yourLeagueUser?.display_name ?? "You"
            opponentTeamName = opponentLeagueUser?.metadata?.team_name ?? opponentLeagueUser?.display_name ?? "Opponent"
        } catch {
            lookupMessage = "Couldn't load team names. Please try again"
        }
    }
    
    private func applySnapshot(_ snapshot: ServerSnapshot) {
        serverSnapshot = snapshot
        yourScore = snapshot.state.yourScore
        opponentScore = snapshot.state.opponentScore
        scoreUpdatedAt = snapshot.state.updatedAt
        yourTeamName = snapshot.attributes.yourName
        opponentTeamName = snapshot.attributes.opponentName
    }
}

#Preview {
    ContentView()
}
