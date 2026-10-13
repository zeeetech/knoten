import CryptoKit
import Foundation

/// An ES256 key pair used to bind tokens to this device (RFC 9449).
///
/// The raw 32 byte representation is what gets persisted; the JWK is derived
/// on demand so it never has to be stored.
public struct DPoPKey: @unchecked Sendable {
    public let privateKey: P256.Signing.PrivateKey

    public init() {
        privateKey = P256.Signing.PrivateKey()
    }

    private init(privateKey: P256.Signing.PrivateKey) {
        self.privateKey = privateKey
    }

    /// Rebuilds a key from the raw bytes held in the session.
    public static func load(_ rawRepresentation: Data) -> KnotenResult<DPoPKey> {
        guard let key = try? P256.Signing.PrivateKey(rawRepresentation: rawRepresentation) else {
            return .failure(.invalidSession("dpop key is not a valid P-256 scalar"))
        }
        return .success(DPoPKey(privateKey: key))
    }

    public var rawRepresentation: Data {
        privateKey.rawRepresentation
    }

    public var jwk: [String: String] {
        let uncompressed = privateKey.publicKey.x963Representation
        return [
            "kty": "EC",
            "crv": "P-256",
            "x": B64URL.encode(Data(uncompressed[1..<33])),
            "y": B64URL.encode(Data(uncompressed[33..<65])),
        ]
    }
}
