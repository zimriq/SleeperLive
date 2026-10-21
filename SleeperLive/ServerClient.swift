import Foundation

struct MatchupSelection: Codable, Hashable {
    let leagueId: String
    let week: Int
    let rosterId: Int
}

struct ServerSnapshot: Decodable {
    var attributes: MatchupActivityAttributes
    let state: MatchupActivityAttributes.ContentState

    func validated(for selection: MatchupSelection, now: Date = .now) throws -> ServerSnapshot {
        guard attributes.week == selection.week, state.yourScore.isFinite,
              state.opponentScore.isFinite, state.updatedAt > 0,
              Double(state.updatedAt) <= now.timeIntervalSince1970 + 60,
              [state.yourProjected, state.opponentProjected].allSatisfy({ $0?.isFinite ?? true }) else {
            throw ServerError.invalidResponse
        }
        var result = self
        result.attributes.leagueId = selection.leagueId
        result.attributes.rosterId = selection.rosterId
        result.attributes.previewOnly = false
        return result
    }
}

struct ServerCredentials: Codable {
    let baseURL: URL
    let deviceId: String
    let deviceToken: String
}

struct ServerError: LocalizedError {
    let status: Int
    let retryAfter: TimeInterval?
    let errorDescription: String?
    var retryable: Bool { status == 429 || status >= 500 }
    static let invalidResponse = ServerError(status: 422, retryAfter: nil,
                                             errorDescription: "The server returned an invalid matchup. Try refreshing.")
}

struct ServerClient {
    let credentials: ServerCredentials
    private let session: URLSession
    init(credentials: ServerCredentials, session: URLSession = ServerClient.sharedSession) {
        self.credentials = credentials
        self.session = session
    }

    // Never forward tester credentials or invitations through an HTTP redirect.
    private final class NoRedirect: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
    }

    static let sharedSession = makeSession()

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 25
        config.urlCache = nil
        return URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
    }

    static func baseURL(_ text: String) throws -> URL {
        guard let parts = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              parts.scheme?.lowercased() == "https", let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              parts.path.isEmpty || parts.path == "/", let url = parts.url else {
            throw ServerError(status: 400, retryAfter: nil,
                              errorDescription: "Enter the server's HTTPS address without a path, password, or query.")
        }
        return url
    }

    static func enroll(address: String, invite: String, session: URLSession = sharedSession) async throws -> ServerCredentials {
        let url = try baseURL(address)
        let client = ServerClient(credentials: .init(baseURL: url, deviceId: "", deviceToken: ""), session: session)
        struct Enrollment: Decodable { let deviceId: String; let deviceToken: String }
        let data = try await client.request("v1/devices", method: "POST",
                                            body: JSONEncoder().encode(["inviteCode": invite]), authenticated: false)
        let result = try JSONDecoder().decode(Enrollment.self, from: data)
        guard !result.deviceId.isEmpty, !result.deviceToken.isEmpty else { throw ServerError.invalidResponse }
        return .init(baseURL: url, deviceId: result.deviceId, deviceToken: result.deviceToken)
    }

    func health() async throws -> String {
        struct Health: Decodable { let ok: Bool; let mode: String }
        let data = try await request("health", authenticated: false)
        let response = try JSONDecoder().decode(Health.self, from: data)
        guard response.ok, ["live", "dry-run"].contains(response.mode) else { throw ServerError.invalidResponse }
        return response.mode
    }

    func snapshot(_ selection: MatchupSelection) async throws -> ServerSnapshot {
        let query = [URLQueryItem(name: "leagueId", value: selection.leagueId),
                     URLQueryItem(name: "week", value: String(selection.week)),
                     URLQueryItem(name: "rosterId", value: String(selection.rosterId))]
        return try JSONDecoder().decode(ServerSnapshot.self, from: await request("v1/matchup", query: query))
            .validated(for: selection)
    }

    func register(_ record: RemoteActivityRecord) async throws {
        struct Registration: Encodable {
            let leagueId: String; let week: Int; let rosterId: Int
            let pushToken: String; let apnsEnvironment: String; let startedAt: Int
        }
        guard let token = record.token else { return }
        let body = Registration(leagueId: record.selection.leagueId, week: record.selection.week,
                                rosterId: record.selection.rosterId, pushToken: token,
                                apnsEnvironment: record.environment, startedAt: record.startedAt)
        _ = try await request("v1/activities/\(record.id)", method: "PUT", body: JSONEncoder().encode(body))
    }

    func deleteActivity(_ id: String) async throws {
        _ = try await request("v1/activities/\(id)", method: "DELETE")
    }

    func request(_ path: String, method: String = "GET", body: Data? = nil,
                 query: [URLQueryItem] = [], authenticated: Bool = true) async throws -> Data {
        var components = URLComponents(url: credentials.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if authenticated { request.setValue("Bearer \(credentials.deviceToken)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let message: String
            switch http.statusCode {
            case 401: message = "Server access expired. Stop your activity, then reconnect in Server setup."
            case 403: message = "The invitation was not accepted. Check your tester invitation."
            case 409: message = "This activity has ended or no longer matches. Start a new one."
            case 429: message = "The server is busy. Waiting before retrying."
            case 503: message = "The matchup is temporarily unavailable. Please try again."
            default: message = "Server request failed (\(http.statusCode)). Check your server setup."
            }
            throw ServerError(status: http.statusCode,
                              retryAfter: Self.retryDelay(http.value(forHTTPHeaderField: "Retry-After")),
                              errorDescription: message)
        }
        return data
    }

    static func retryDelay(_ value: String?, now: Date = .now) -> TimeInterval? {
        guard let value else { return nil }
        if let seconds = Double(value), seconds.isFinite { return max(0, seconds) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: value).map { max(0, $0.timeIntervalSince(now)) }
    }
}
