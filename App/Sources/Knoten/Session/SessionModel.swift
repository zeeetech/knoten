import KnotenCore
import SwiftUI

extension OAuthClient {
    /// Knoten's published client identity. The redirect carries a single
    /// slash after the scheme, as the atproto profile requires for native
    /// apps.
    static let knoten = OAuthClient(
        clientID: URL(string: "https://knoten.app/oauth/client-metadata.json")!,
        redirectURI: URL(string: "app.knoten:/callback")!
    )
}

@MainActor
@Observable
final class SessionModel {
    enum State {
        case signedOut
        case signingIn
        case signedIn(OAuthSession)
        case failed(KnotenError)
    }

    private(set) var state: State = .signedOut

    private let client: OAuthClient
    private let storage: SessionStorage
    private let authorizer = Authorizer()
    private let authentication = AuthenticationSession()

    init(
        client: OAuthClient = .knoten,
        storage: SessionStorage = KeychainSessionStorage(service: "io.zeetech.knoten")
    ) {
        self.client = client
        self.storage = storage
    }

    func restore() async {
        switch await storage.load() {
        case .success(.some(let session)):
            state = .signedIn(session)
        case .success(nil):
            state = .signedOut
        case .failure(let error):
            state = .failed(error)
        }
    }

    @discardableResult
    func login(handle: String) async -> KnotenResult<Void> {
        state = .signingIn
        switch await authorize(handle: handle) {
        case .success(let session):
            state = .signedIn(session)
            return .success(())
        case .failure(let error):
            state = .failed(error)
            return .failure(error)
        }
    }

    func logout() async {
        if case .failure(let error) = await storage.clear() {
            state = .failed(error)
            return
        }
        state = .signedOut
    }

    private func authorize(handle: String) async -> KnotenResult<OAuthSession> {
        switch await authorizer.start(client: client, identifier: handle) {
        case .failure(let error):
            return .failure(error)
        case .success(let authorization):
            return await self.authenticate(handle: handle, authorization: authorization)
        }
    }

    private func authenticate(
        handle: String,
        authorization: Authorization
    ) async -> KnotenResult<OAuthSession> {
        guard let scheme = client.redirectURI.scheme else {
            return .failure(.invalidURL(client.redirectURI.absoluteString))
        }

        switch await authentication.start(url: authorization.url, callbackScheme: scheme) {
        case .failure(let error):
            return .failure(error)
        case .success(let callback):
            switch Self.callbackCode(from: callback, authorization: authorization) {
            case .failure(let error):
                return .failure(error)
            case .success(let code):
                return await self.store(handle: handle, authorization: authorization, code: code)
            }
        }
    }

    private func store(
        handle: String,
        authorization: Authorization,
        code: String
    ) async -> KnotenResult<OAuthSession> {
        switch await authorizer.exchange(client: client, authorization: authorization, code: code) {
        case .failure(let error):
            return .failure(error)
        case .success(var session):
            session.handle = handle
            switch await storage.save(session) {
            case .failure(let error):
                return .failure(error)
            case .success:
                return .success(session)
            }
        }
    }

    /// The code only counts when the state token round trips and the issuer
    /// is the authorization server we discovered, so a redirect cannot be
    /// mixed up with another flow.
    private static func callbackCode(from url: URL, authorization: Authorization) -> KnotenResult<String> {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value
        else {
            return .failure(.invalidSession("the callback carried no code and state"))
        }

        guard state == authorization.state else {
            return .failure(.invalidSession("the callback state does not match the request"))
        }

        guard components.queryItems?.first(where: { $0.name == "iss" })?.value == authorization.issuer.absoluteString else {
            return .failure(.invalidSession("the callback issuer does not match the authorization server"))
        }

        return .success(code)
    }
}
