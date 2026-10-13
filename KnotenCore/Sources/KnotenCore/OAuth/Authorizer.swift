import Foundation

/// What the app carries from the authorization redirect back to the token
/// exchange. The verifier and the DPoP key must not leave the device.
public struct Authorization: Sendable {
    public let url: URL
    public let state: String
    public let verifier: String
    public let did: String
    public let serviceURL: URL
    public let issuer: URL
    public let tokenEndpoint: URL
    public let key: DPoPKey
    public let nonce: String?
}

/// Drives the atproto OAuth flow: identity resolution, server discovery, PAR,
/// then the code exchange and refresh.
public struct Authorizer: Sendable {
    private let transport: Transport
    private let executor: DPoPExecutor

    public init(transport: Transport = URLSessionTransport()) {
        self.transport = transport
        self.executor = DPoPExecutor(transport: transport)
    }

    public func start(client: OAuthClient, identifier: String) async -> KnotenResult<Authorization> {
        await resolveDID(identifier).then { did in
            await self.begin(client: client, identifier: identifier, did: did)
        }
    }

    public func exchange(
        client: OAuthClient,
        authorization: Authorization,
        code: String
    ) async -> KnotenResult<OAuthSession> {
        await token(
            endpoint: authorization.tokenEndpoint,
            fields: [
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": client.redirectURI.absoluteString,
                "client_id": client.clientID.absoluteString,
                "code_verifier": authorization.verifier,
            ],
            key: authorization.key,
            nonce: authorization.nonce
        ).then { tokens -> KnotenResult<OAuthSession> in
            // The token response must name the account we resolved earlier.
            guard tokens.sub == authorization.did else {
                return .failure(.invalidSession("sub does not match the resolved DID"))
            }

            return .success(OAuthSession(
                did: tokens.sub,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                scope: tokens.scope,
                expiresAt: Self.expiry(from: tokens.expiresIn),
                serviceURL: authorization.serviceURL,
                issuer: authorization.issuer,
                tokenEndpoint: authorization.tokenEndpoint,
                dpopKey: authorization.key.rawRepresentation,
                dpopNonce: authorization.nonce
            ))
        }
    }

    public func refresh(client: OAuthClient, session: OAuthSession) async -> KnotenResult<OAuthSession> {
        guard let refreshToken = session.refreshToken else {
            return .failure(.invalidSession("session has no refresh token"))
        }

        return await DPoPKey.load(session.dpopKey).then { key -> KnotenResult<OAuthSession> in
            await self.token(
                endpoint: session.tokenEndpoint,
                fields: [
                    "grant_type": "refresh_token",
                    "refresh_token": refreshToken,
                    "client_id": client.clientID.absoluteString,
                ],
                key: key,
                nonce: session.dpopNonce
            ).map { tokens in
                var refreshed = session
                refreshed.accessToken = tokens.accessToken
                refreshed.refreshToken = tokens.refreshToken ?? refreshToken
                refreshed.scope = tokens.scope ?? session.scope
                refreshed.expiresAt = Self.expiry(from: tokens.expiresIn)
                return refreshed
            }
        }
    }

    private func resolveDID(_ identifier: String) async -> KnotenResult<String> {
        if identifier.hasPrefix("did:") {
            return .success(identifier)
        }

        let resolver = HandleResolver(transport: transport)
        return await resolver.resolve(identifier).then { did in
            await resolver.verify(handle: identifier, did: did).map { did }
        }
    }

    private func begin(
        client: OAuthClient,
        identifier: String,
        did: String
    ) async -> KnotenResult<Authorization> {
        await pds(for: did).then { pds in
            await self.metadata(for: pds).then { metadata in
                await self.push(client: client, identifier: identifier, did: did, pds: pds, metadata: metadata)
            }
        }
    }

    private func pds(for did: String) async -> KnotenResult<URL> {
        await DIDResolver(transport: transport).resolve(did).then { document -> KnotenResult<URL> in
            guard let url = document.pdsURL else {
                return .failure(.missingMetadataField("serviceEndpoint"))
            }
            return .success(url)
        }
    }

    private func metadata(for pds: URL) async -> KnotenResult<AuthorizationServerMetadata> {
        await resourceServer(pds).then { server in
            await self.getJSON(
                server.appending(path: "/.well-known/oauth-authorization-server"),
                as: AuthorizationServerMetadata.self,
                label: "authorization server metadata"
            )
        }
    }

    private func resourceServer(_ pds: URL) async -> KnotenResult<URL> {
        await getJSON(
            pds.appending(path: "/.well-known/oauth-protected-resource"),
            as: ProtectedResourceMetadata.self,
            label: "protected resource metadata"
        ).then { metadata -> KnotenResult<URL> in
            guard let server = metadata.authorizationServers.first else {
                return .failure(.missingMetadataField("authorization_servers"))
            }
            return .success(server)
        }
    }

    private func push(
        client: OAuthClient,
        identifier: String,
        did: String,
        pds: URL,
        metadata: AuthorizationServerMetadata
    ) async -> KnotenResult<Authorization> {
        let pkce = PKCE()
        let state = B64URL.encode(Random.bytes(16))
        let key = DPoPKey()

        return await form(
            url: metadata.pushedAuthorizationRequestEndpoint,
            fields: [
                "response_type": "code",
                "client_id": client.clientID.absoluteString,
                "redirect_uri": client.redirectURI.absoluteString,
                "scope": client.scope,
                "state": state,
                "code_challenge": pkce.challenge,
                "code_challenge_method": "S256",
                "login_hint": identifier,
            ],
            key: key,
            nonce: nil
        ).then { result -> KnotenResult<Authorization> in
            guard result.status == 200 else {
                return .failure(.http(status: result.status, body: result.body))
            }

            return await self.decoder().decode(
                PushedAuthorizationResponse.self,
                from: result.data,
                label: "pushed authorization response"
            ).then { par in
                self.authorizeURL(metadata.authorizationEndpoint, client: client, requestURI: par.requestUri)
                    .map { url in
                        Authorization(
                            url: url,
                            state: state,
                            verifier: pkce.verifier,
                            did: did,
                            serviceURL: pds,
                            issuer: metadata.issuer,
                            tokenEndpoint: metadata.tokenEndpoint,
                            key: key,
                            nonce: result.nonce
                        )
                    }
            }
        }
    }

    private func token(
        endpoint: URL,
        fields: [String: String],
        key: DPoPKey,
        nonce: String?
    ) async -> KnotenResult<TokenResponse> {
        await form(url: endpoint, fields: fields, key: key, nonce: nonce).then { result -> KnotenResult<TokenResponse> in
            guard result.status == 200 else {
                return .failure(.http(status: result.status, body: result.body))
            }
            return self.decoder().decode(
                TokenResponse.self,
                from: result.data,
                label: "token response"
            )
        }
    }

    private func form(
        url: URL,
        fields: [String: String],
        key: DPoPKey,
        nonce: String?
    ) async -> KnotenResult<DPoPResult> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(Self.encode(fields).utf8)
        return await executor.send(request, key: key, nonce: nonce)
    }

    private func getJSON<Value: Decodable>(
        _ url: URL,
        as type: Value.Type,
        label: String
    ) async -> KnotenResult<Value> {
        await transport.send(URLRequest(url: url)).then { http -> KnotenResult<Value> in
            guard http.status == 200 else {
                return .failure(.http(status: http.status, body: http.body))
            }
            return self.decoder().decode(Value.self, from: http.data, label: label)
        }
    }

    private func authorizeURL(
        _ endpoint: URL,
        client: OAuthClient,
        requestURI: String
    ) -> KnotenResult<URL> {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return .failure(.invalidURL(endpoint.absoluteString))
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: client.clientID.absoluteString),
            URLQueryItem(name: "request_uri", value: requestURI),
        ]
        guard let url = components.url else {
            return .failure(.invalidURL(endpoint.absoluteString))
        }
        return .success(url)
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private static func expiry(from expiresIn: Int?) -> Date? {
        expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
    }

    /// `application/x-www-form-urlencoded`, sorted so tests and servers see a
    /// stable body.
    static func encode(_ fields: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")

        return fields
            .sorted { $0.key < $1.key }
            .map { key, value in
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                let escapedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(escapedKey)=\(escapedValue)"
            }
            .joined(separator: "&")
    }
}

struct ProtectedResourceMetadata: Decodable {
    let authorizationServers: [URL]
}

struct AuthorizationServerMetadata: Decodable {
    let issuer: URL
    let authorizationEndpoint: URL
    let tokenEndpoint: URL
    let pushedAuthorizationRequestEndpoint: URL
}

struct PushedAuthorizationResponse: Decodable {
    let requestUri: String
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String?
    let scope: String?
    let expiresIn: Int?
    let sub: String
}
