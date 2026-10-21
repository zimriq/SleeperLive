import Foundation
import Security

struct RemoteActivityRecord: Codable, Identifiable {
    let id: String
    let selection: MatchupSelection
    let startedAt: Int
    let environment: String
    var token: String?
    var registeredToken: String?
    var ending = false
    var failures = 0
    var nextAttempt: TimeInterval = 0

    var needsSync: Bool { ending || (token != nil && token != registeredToken) }
    var expiresAt: TimeInterval { TimeInterval(startedAt) + 28_800 }

    mutating func acknowledge(sentToken: String?) {
        // Keep any newer token or queued stop; only acknowledge what was sent.
        registeredToken = sentToken
        failures = 0
        nextAttempt = 0
    }

    mutating func retry(failed: RemoteActivityRecord, retryAfter: TimeInterval?, now: TimeInterval) {
        guard ending == failed.ending, token == failed.token else { return }
        failures += 1
        let delay = max(retryAfter ?? 0, min(300, 5 * pow(2, Double(min(failures, 6)))))
        nextAttempt = now + delay
    }
}

struct IntegrationState: Codable {
    var credentials: ServerCredentials?
    var records: [RemoteActivityRecord] = []
}

// One atomic Keychain item keeps credentials and pending work tied to the same server.
// Tokens never go into UserDefaults, logs, source files, or iCloud backups.
struct IntegrationStore {
    private let account = "server-integration-v1"
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.zimri.SleeperLive",
         kSecAttrAccount as String: account]
    }

    func load() throws -> IntegrationState {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return IntegrationState() }
        guard status == errSecSuccess, let data = result as? Data else { throw storageError(status) }
        return try JSONDecoder().decode(IntegrationState.self, from: data)
    }

    func save(_ state: IntegrationState) throws {
        let attributes: [String: Any] = [kSecValueData as String: try JSONEncoder().encode(state),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw storageError(status) }
    }

    private func storageError(_ status: OSStatus) -> ServerError {
        ServerError(status: 422, retryAfter: nil,
                    errorDescription: "Couldn't access secure storage (\(status)). Unlock your phone and reopen SleeperLive.")
    }
}

// Private device testing: derive the APNs environment from the embedded profile,
// not from Debug/Release. Distribution without an embedded profile fails closed.
enum PushEnvironment {
    static func current() throws -> String {
        #if targetEnvironment(simulator)
        throw ServerError(status: 422, retryAfter: nil,
                          errorDescription: "Use your signed physical iPhone for server updates. The simulator supports the local preview.")
        #else
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url), let environment = parseProfile(data) else {
            throw ServerError(status: 422, retryAfter: nil,
                              errorDescription: "Push signing isn't ready. Enable Push Notifications and select your paid Apple team in Xcode, then reinstall on your phone.")
        }
        return environment
        #endif
    }

    static func parseProfile(_ data: Data) -> String? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex),
              let plist = try? PropertyListSerialization.propertyList(from: data[start.lowerBound..<end.upperBound], format: nil),
              let dictionary = plist as? [String: Any], let entitlements = dictionary["Entitlements"] as? [String: Any],
              let value = entitlements["aps-environment"] as? String,
              ["development", "production"].contains(value) else { return nil }
        return value
    }
}
