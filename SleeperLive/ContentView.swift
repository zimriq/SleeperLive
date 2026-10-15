import SwiftUI

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
    let points: Double
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
    
    var welcomeView: some View{
        VStack(alignment: .leading, spacing: 24){
            Text("Sleeper\nLive")
                .font(.system(size: 60, weight: .heavy))
            
            Text("Your Sleeper matchup, on the Lock Screen")
                .font(.body)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8){
                Text("Sleeper Username")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextField("Sleeper username", text: $username)
                    .textFieldStyle(.plain)
                        .padding(16)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("No password needed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(lookupMessage)
                if(isLoading){
                    ProgressView()
                }
            }
        }
    }
    
    var leagueSelectionView: some View {
        VStack(spacing: 24){
            Text("Choose a league")
            ForEach(leagues) { league in
                Button(league.name) {
                    myRosterID = nil
                    opponentScore = nil
                    yourScore = nil
                    yourTeamName = "You"
                    opponentTeamName = "Opponent"
                    selectedLeague = league

                    Task{
                        await findMyRoster(league: league)
                    }
                }
                .disabled(isLoading && selectedLeague?.league_id == league.league_id)
            }
            .allowsHitTesting(!isLoading)
        }
    }
    
    var matchupView: some View {
        VStack(spacing: 24) {
            if let selectedLeague {
                Text("Selected: \(selectedLeague.name)")
                    .font(.caption)
            }
            
            if let currentWeek = currentWeek {
                Text("Week \(currentWeek)")
            }
            
            if let yourScore = yourScore, let opponentScore = opponentScore {
                HStack(spacing: 40){
                    VStack(spacing: 12){
                        Text(yourTeamName)
                        Text(yourScore, format: .number.precision(.fractionLength(2)))
                    }
                    VStack(spacing: 12) {
                        Text(opponentTeamName)
                        Text(opponentScore, format: .number.precision(.fractionLength(2)))
                    }
                }
            }
            
            // TODO: Add a button to start the Live Activity.

        }
    }
    
    var findAccountButton: some View {
        Button {
            Task {
                await findUser()
            }
        } label: {
            Text("Find my account")
                .frame(maxWidth: .infinity)
                .font(.headline)
                .padding(.vertical, 12)
        }
        .disabled(isLoading)
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.05, green: 0.43, blue: 0.25))
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                welcomeView
                    .padding(24)
            }
            .safeAreaInset(edge: .bottom){
                findAccountButton
                    .padding(24)
            }
            .background(Color(uiColor:
                    .systemGroupedBackground))
            .navigationDestination(isPresented: $showLeagueSelection) {
                ScrollView {
                    leagueSelectionView
                        .padding()
                }
                .navigationDestination(isPresented: $showMatchup) {
                    ScrollView {
                        matchupView
                            .padding()
                    }
                }
            }
        }
    }

    // User lookup and loading leagues tied to it
    func findUser() async {
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
    func findMatchup(league: SleeperLeague) async {
        guard let myRosterID = myRosterID else {
            lookupMessage = "roster id is missing"
            return
        }
        guard let currentWeek = currentWeek else {
            lookupMessage = "current week is missing"
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
            
            yourScore = myMatchup.points
            opponentScore = opponentMatchup.points
            lookupMessage = "Matchup loaded."
            
            await findTeamNames(league: league)
            showMatchup = true
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
    
    // TODO: Connect matchup data to a separate Live Activity manager.
}

#Preview {
    ContentView()
}
