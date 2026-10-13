import Foundation

/// A DPoP bound atproto session.
///
/// The DPoP key is stored raw so the whole value round trips through the
/// Keychain. Treat it as key material, same as the tokens.
public struct OAuthSession: Codable, Sendable {
    public let did: String
    public var handle: String?
    public var accessToken: String
    public var refreshToken: String?
    public var scope: String?
    public var expiresAt: Date?
    public let serviceURL: URL
    public let issuer: URL
    public let tokenEndpoint: URL
    public var dpopKey: Data
    public var dpopNonce: String?

    public init(
        did: String,
        handle: String? = nil,
        accessToken: String,
        refreshToken: String? = nil,
        scope: String? = nil,
        expiresAt: Date? = nil,
        serviceURL: URL,
        issuer: URL,
        tokenEndpoint: URL,
        dpopKey: Data,
        dpopNonce: String? = nil
    ) {
        self.did = did
        self.handle = handle
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.scope = scope
        self.expiresAt = expiresAt
        self.serviceURL = serviceURL
        self.issuer = issuer
        self.tokenEndpoint = tokenEndpoint
        self.dpopKey = dpopKey
        self.dpopNonce = dpopNonce
    }

    /// Refresh tokens are single use, so renew before the access token dies.
    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt.addingTimeInterval(-30)
    }
}
