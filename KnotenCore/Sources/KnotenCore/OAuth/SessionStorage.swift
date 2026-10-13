import Foundation

/// Persists the OAuth session between launches.
public protocol SessionStorage: Sendable {
    func save(_ session: OAuthSession) async -> KnotenResult<Void>
    func load() async -> KnotenResult<OAuthSession?>
    func clear() async -> KnotenResult<Void>
}

/// Keychain backed storage. The whole session, DPoP key included, round
/// trips as JSON under a single account.
public struct KeychainSessionStorage: SessionStorage {
    private let keychain: Keychain
    private static let account = "session"

    public init(service: String) {
        self.keychain = Keychain(service: service)
    }

    public func save(_ session: OAuthSession) async -> KnotenResult<Void> {
        let data: Data
        do {
            data = try JSONEncoder().encode(session)
        } catch {
            return .failure(.invalidSession("could not encode the session"))
        }
        return keychain.set(data, account: Self.account)
    }

    public func load() async -> KnotenResult<OAuthSession?> {
        switch keychain.get(account: Self.account) {
        case .success(nil):
            return .success(nil)
        case .success(.some(let data)):
            do {
                return .success(try JSONDecoder().decode(OAuthSession.self, from: data))
            } catch {
                return .failure(.invalidResponse("stored session"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    public func clear() async -> KnotenResult<Void> {
        keychain.remove(account: Self.account)
    }
}

/// In memory storage for tests and previews. Seeding it starts from a session
/// instead of a login.
public actor InMemorySessionStorage: SessionStorage {
    private var stored: OAuthSession?

    public init(_ session: OAuthSession? = nil) {
        stored = session
    }

    public func save(_ session: OAuthSession) async -> KnotenResult<Void> {
        stored = session
        return .success(())
    }

    public func load() async -> KnotenResult<OAuthSession?> {
        .success(stored)
    }

    public func clear() async -> KnotenResult<Void> {
        stored = nil
        return .success(())
    }
}
