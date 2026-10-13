import CryptoKit
import Foundation

/// A PKCE verifier and its S256 challenge (RFC 7636).
public struct PKCE: Sendable {
    public let verifier: String
    public let challenge: String

    public init(verifier: String? = nil) {
        let value = verifier ?? B64URL.encode(Random.bytes(32))
        self.verifier = value
        self.challenge = B64URL.encode(Data(SHA256.hash(data: Data(value.utf8))))
    }
}
