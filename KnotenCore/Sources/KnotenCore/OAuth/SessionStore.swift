import Foundation

/// Holds the live session so a rotating DPoP nonce and refreshed tokens are
/// visible to every caller. Same role as a session manager in a long lived
/// client, one actor instead of a process.
public actor SessionStore {
    private var session: OAuthSession

    public init(session: OAuthSession) {
        self.session = session
    }

    public func current() -> OAuthSession {
        session
    }

    public func update(_ session: OAuthSession) {
        self.session = session
    }

    func recordNonce(_ nonce: String?) {
        if let nonce {
            session.dpopNonce = nonce
        }
    }

    /// Refreshes when the access token is close to expiry, leaving the store
    /// untouched otherwise.
    @discardableResult
    public func refreshIfNeeded(client: OAuthClient, authorizer: Authorizer) async -> KnotenResult<OAuthSession> {
        guard session.isExpired else {
            return .success(session)
        }

        let refreshed = await authorizer.refresh(client: client, session: session)
        if case .success(let value) = refreshed {
            session = value
        }
        return refreshed
    }
}
