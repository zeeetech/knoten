import Foundation

/// A public atproto OAuth client.
///
/// `clientID` is the HTTPS URL of the published client metadata document, so
/// the authorization server can fetch it. `redirectURI` must match one of the
/// URIs declared there, in reverse-domain order for native apps.
public struct OAuthClient: Sendable {
    public let clientID: URL
    public let redirectURI: URL
    public let scope: String

    public init(
        clientID: URL,
        redirectURI: URL,
        scope: String = "atproto transition:generic"
    ) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scope = scope
    }
}
