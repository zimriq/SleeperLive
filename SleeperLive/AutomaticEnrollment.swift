import CryptoKit
import DeviceCheck
import Foundation
import Security

struct PendingEnrollment: Codable {
    let baseURL: URL
    let keyId: String
    let secret: String
    var challengeId: String?
    var challenge: String?
    var expiresAt: TimeInterval?
    var attestation: String?
}

@MainActor
enum AutomaticEnrollment {
    static let serverURL = AppEnvironment.serverURL

    private static func unavailable(_ text: String) -> ServerError {
        .init(status: 422, retryAfter: nil, errorDescription: text)
    }

    static func enroll(pending initial: PendingEnrollment?,
                       save: (PendingEnrollment?) throws -> Void) async throws -> ServerCredentials {
        let service = DCAppAttestService.shared
        guard service.isSupported else {
            throw unavailable("This device doesn't support secure background-update registration. You can view scores in the app; contact beta support for help.")
        }
        let client = ServerClient(credentials: .init(baseURL: serverURL, deviceId: "", deviceToken: ""))
        var pending = initial?.baseURL == serverURL ? initial : nil
        // Recover a committed enrollment if the completion response or Keychain
        // save was interrupted. This also works after the challenge expires.
        if let saved = pending, let id = saved.challengeId, saved.attestation != nil {
            let credentials = ServerCredentials(baseURL: serverURL, deviceId: id, deviceToken: "\(id).\(saved.secret)")
            do {
                struct Recovery: Decodable { let deviceId: String }
                let data = try await ServerClient(credentials: credentials).request("v1/devices/me")
                guard try JSONDecoder().decode(Recovery.self, from: data).deviceId == id else {
                    throw ServerError.invalidResponse
                }
                return credentials
            } catch let error as ServerError where error.status == 401 {
                // Not committed yet; continue with the saved proof if still valid.
            }
        }
        if let expires = pending?.expiresAt, expires <= Date().timeIntervalSince1970 {
            try save(nil)
            pending = nil
        }
        if pending == nil {
            var bytes = [UInt8](repeating: 0, count: 32)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
                throw unavailable("Couldn't create secure device access. Please try again.")
            }
            let secret = bytes.map { String(format: "%02x", $0) }.joined()
            let keyId = try await service.generateKey()
            pending = PendingEnrollment(baseURL: serverURL, keyId: keyId, secret: secret)
            try save(pending)
        }
        guard var current = pending else { throw ServerError.invalidResponse }
        if current.challengeId == nil {
            struct Challenge: Decodable { let challengeId: String; let challenge: String; let expiresAt: TimeInterval }
            let credentialHash = SHA256.hash(data: Data(current.secret.utf8)).map { String(format: "%02x", $0) }.joined()
            let data = try await client.request("v1/enrollment/challenge", method: "POST",
                body: JSONEncoder().encode(["keyId": current.keyId, "credentialHash": credentialHash]), authenticated: false)
            let result = try JSONDecoder().decode(Challenge.self, from: data)
            guard result.challengeId.range(of: "^[a-f0-9]{32}$", options: .regularExpression) != nil,
                  !result.challenge.isEmpty, result.expiresAt > Date().timeIntervalSince1970,
                  result.expiresAt < Date().timeIntervalSince1970 + 600 else { throw ServerError.invalidResponse }
            current.challengeId = result.challengeId
            current.challenge = result.challenge
            current.expiresAt = result.expiresAt
            try save(current)
        }
        if current.attestation == nil {
            guard let challenge = current.challenge else { throw ServerError.invalidResponse }
            do {
                let proof = try await service.attestKey(current.keyId,
                    clientDataHash: Data(SHA256.hash(data: Data(challenge.utf8))))
                current.attestation = proof.base64EncodedString()
                try save(current)
            } catch let error as DCError where error.code == .invalidKey {
                try save(nil)
                throw unavailable("Device verification needs another attempt. Please retry in a minute.")
            }
        }
        guard let id = current.challengeId, let proof = current.attestation else { throw ServerError.invalidResponse }
        do {
            struct Completion: Decodable { let deviceId: String }
            let data = try await client.request("v1/enrollment/complete", method: "POST",
                body: JSONEncoder().encode(["challengeId": id, "attestation": proof]), authenticated: false)
            let result = try JSONDecoder().decode(Completion.self, from: data)
            guard result.deviceId == id else { throw ServerError.invalidResponse }
            return .init(baseURL: serverURL, deviceId: id, deviceToken: "\(id).\(current.secret)")
        } catch let error as ServerError where [403, 409, 410].contains(error.status) {
            try save(nil)
            throw unavailable("Device verification couldn't finish. Please retry in a minute.")
        }
    }
}
