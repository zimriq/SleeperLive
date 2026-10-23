import XCTest
@testable import SleeperLive

final class ServerIntegrationTests: XCTestCase {
    private let selection = MatchupSelection(leagueId: "123456789", week: 7, rosterId: 4)

    func testExpiredCleanupDoesNotBlockNewServerButProtectsActiveAndUnexpiredRecords() {
        var record = makeRecord()
        record.ending = true
        var state = IntegrationState()
        state.records = [record]
        state.discardExpiredCleanup(now: record.expiresAt - 1, activeIDs: [])
        XCTAssertEqual(state.records.count, 1)
        state.discardExpiredCleanup(now: record.expiresAt, activeIDs: [record.id])
        XCTAssertEqual(state.records.count, 1)
        state.discardExpiredCleanup(now: record.expiresAt, activeIDs: [])
        XCTAssertTrue(state.records.isEmpty)
    }

    func testOnlyBareHTTPSAddressesAccepted() throws {
        XCTAssertEqual(try ServerClient.baseURL(" https://example.com/ ").host, "example.com")
        for value in ["http://example.com", "https://user:secret@example.com", "https://example.com/api", "https://example.com?token=secret", "https://example.com#fragment", ""] {
            XCTAssertThrowsError(try ServerClient.baseURL(value), value)
        }
    }

    func testNullableProjectionsAndUnixSecondsMatchServerContract() throws {
        let data = snapshotData()
        let result = try JSONDecoder().decode(ServerSnapshot.self, from: data).validated(for: selection)
        XCTAssertNil(result.state.yourProjected)
        XCTAssertEqual(result.state.opponentProjected, 112.5)
        XCTAssertEqual(result.attributes.leagueId, selection.leagueId)
        XCTAssertEqual(result.attributes.previewOnly, false)
        XCTAssertEqual(result.state.staleDate.timeIntervalSince(result.state.updatedDate), 360)
    }

    func testWrongWeekAndFutureTimestampsAreRejected() throws {
        let result = try JSONDecoder().decode(ServerSnapshot.self, from: snapshotData())
        XCTAssertThrowsError(try result.validated(for: .init(leagueId: "123456789", week: 8, rosterId: 4)))
        XCTAssertThrowsError(try result.validated(for: selection, now: Date(timeIntervalSince1970: 1)))
    }

    func testRetryAfterBothFormats() {
        XCTAssertEqual(ServerClient.retryDelay("75"), 75)
        XCTAssertNil(ServerClient.retryDelay("garbage"))
        XCTAssertNil(ServerClient.retryDelay("nan"))
        XCTAssertEqual(ServerClient.retryDelay("Wed, 21 Oct 2015 07:28:00 GMT", now: Date(timeIntervalSince1970: 1445412420)), 60)
    }

    func testRotationDuringRegistrationKeepsNewestTokenPending() {
        var record = makeRecord()
        record.token = "new-token"
        record.acknowledge(sentToken: "old-token")
        XCTAssertTrue(record.needsSync)
        XCTAssertEqual(record.token, "new-token")
        XCTAssertEqual(record.startedAt, 100)
        record.acknowledge(sentToken: "new-token")
        XCTAssertFalse(record.needsSync)
    }

    func testStopDuringRegistrationStillRequiresDelete() {
        var record = makeRecord()
        record.ending = true
        record.acknowledge(sentToken: "old-token")
        XCTAssertTrue(record.needsSync)
        XCTAssertTrue(record.ending)
    }

    func testRetryHonorsServerDelayWithoutDelayingNewerWork() {
        var record = makeRecord()
        let sent = record
        record.retry(failed: sent, retryAfter: 900, now: 1000)
        XCTAssertEqual(record.nextAttempt, 1900)
        record.token = "new-token"
        record.nextAttempt = 0
        record.retry(failed: sent, retryAfter: 900, now: 1000)
        XCTAssertEqual(record.nextAttempt, 0)
        record.ending = true
        record.retry(failed: sent, retryAfter: 900, now: 1000)
        XCTAssertEqual(record.nextAttempt, 0)
    }

    func testDurableRegistrationRetainsStartAndPendingDeletion() throws {
        var record = makeRecord()
        record.ending = true
        let state = IntegrationState(credentials: credentials, records: [record])
        let restored = try JSONDecoder().decode(IntegrationState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.records.first?.startedAt, 100)
        XCTAssertEqual(restored.records.first?.expiresAt, 28900)
        XCTAssertEqual(restored.records.first?.ending, true)
        XCTAssertEqual(restored.credentials?.baseURL, credentials.baseURL)
    }

    func testAPNsEnvironmentComesFromProfile() throws {
        for environment in ["development", "production"] {
            let plist = try PropertyListSerialization.data(fromPropertyList: ["Entitlements": ["aps-environment": environment]], format: .xml, options: 0)
            let envelope = Data([0, 255, 1]) + plist + Data([0, 2])
            XCTAssertEqual(PushEnvironment.parseProfile(envelope), environment)
        }
        XCTAssertNil(PushEnvironment.parseProfile(Data("invalid".utf8)))
    }

    func testRegistrationRequestCarriesStableIdentityAndAuthorization() async throws {
        let session = session { request in
            XCTAssertEqual(request.url?.path, "/v1/activities/activity-123")
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-device-token")
            let body = try JSONSerialization.jsonObject(with: Self.body(request)) as! [String: Any]
            XCTAssertEqual(body["startedAt"] as? Int, 100)
            XCTAssertEqual(body["rosterId"] as? Int, 4)
            XCTAssertEqual(body["apnsEnvironment"] as? String, "development")
            XCTAssertEqual(body["pushToken"] as? String, "old-token")
            return (200, [:], Data("{}".utf8))
        }
        defer { session.invalidateAndCancel() }
        try await ServerClient(credentials: credentials, session: session).register(makeRecord())
    }

    func testRateLimitPreservesRetryAfter() async throws {
        let session = session { _ in (429, ["Retry-After": "75"], Data("{}".utf8)) }
        defer { session.invalidateAndCancel() }
        do {
            _ = try await ServerClient(credentials: credentials, session: session).snapshot(selection)
            XCTFail("Expected rate limit")
        } catch let error as ServerError {
            XCTAssertEqual(error.status, 429)
            XCTAssertEqual(error.retryAfter, 75)
            XCTAssertTrue(error.retryable)
        }
    }

    func testEnrollmentDoesNotSendBearerCredential() async throws {
        let session = session { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try JSONSerialization.jsonObject(with: Self.body(request)) as! [String: String]
            XCTAssertEqual(body["inviteCode"], "test-invitation")
            return (201, [:], Data(#"{"deviceId":"device-1","deviceToken":"new-token"}"#.utf8))
        }
        defer { session.invalidateAndCancel() }
        let result = try await ServerClient.enroll(address: "https://example.com", invite: "test-invitation", session: session)
        XCTAssertEqual(result.deviceToken, "new-token")
    }

    private var credentials: ServerCredentials {
        .init(baseURL: URL(string: "https://example.com")!, deviceId: "device-1", deviceToken: "test-device-token")
    }
    private func makeRecord() -> RemoteActivityRecord {
        .init(id: "activity-123", selection: selection, startedAt: 100, environment: "development", token: "old-token")
    }
    private func snapshotData() -> Data {
        Data("""
        {"attributes":{"leagueName":"League","yourName":"You","opponentName":"Opponent","week":7},"state":{"yourScore":42.5,"opponentScore":51.25,"yourProjected":null,"opponentProjected":112.5,"yourProjectionKind":"unavailable","opponentProjectionKind":"estimate","updatedAt":\(Int(Date().timeIntervalSince1970))}}
        """.utf8)
    }
    private func session(_ handler: @escaping (URLRequest) throws -> (Int, [String: String], Data)) -> URLSession {
        StubProtocol.handler = handler
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: config)
    }
    private static func body(_ request: URLRequest) -> Data {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open(); defer { stream.close() }
        var result = Data(), buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            result.append(buffer, count: count)
        }
        return result
    }
}

private final class StubProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, [String: String], Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, headers, data) = try Self.handler!(request)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
