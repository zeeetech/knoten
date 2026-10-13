import Foundation

public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}

/// XRPC caller.
///
/// Session calls are DPoP signed and go to the account's own PDS. Reads on
/// another host (the Tangled API, another account's PDS) go through the
/// `public*` pair, which carries no session headers: the access token is bound
/// to the account's PDS, so sending it anywhere else hands that host the
/// account. Public reads need no credential, so there is nothing to lose.
///
/// When writes against another service land, they need a service auth token
/// minted for that service, not the session token. That is not this.
public struct XRPCClient: Sendable {
    private let store: SessionStore
    private let executor: DPoPExecutor
    private let transport: Transport

    public init(store: SessionStore, transport: Transport = URLSessionTransport()) {
        self.store = store
        self.executor = DPoPExecutor(transport: transport)
        self.transport = transport
    }

    public func get<Response: Decodable>(
        _ nsid: String,
        params: [String: String] = [:]
    ) async -> KnotenResult<Response> {
        let session = await store.current()
        return await Self.url(service: session.serviceURL, nsid: nsid, params: params).then { url in
            await self.perform(Self.request(url: url, method: "GET", body: nil), session: session)
                .then { result in self.decode(result) }
        }
    }

    public func post<Body: Encodable, Response: Decodable>(
        _ nsid: String,
        body: Body
    ) async -> KnotenResult<Response> {
        guard let encoded = try? JSONEncoder().encode(body) else {
            return .failure(.invalidResponse("request body is not encodable"))
        }

        let session = await store.current()
        return await Self.url(service: session.serviceURL, nsid: nsid, params: [:]).then { url in
            await self.perform(Self.request(url: url, method: "POST", body: encoded), session: session)
                .then { result in self.decode(result) }
        }
    }

    /// A public read on another host, decoded.
    public func publicGet<Response: Decodable>(
        _ nsid: String,
        params: [String: String] = [:],
        on service: URL
    ) async -> KnotenResult<Response> {
        await publicData(nsid, params: params, on: service).then { data in
            if data.isEmpty, let empty = EmptyResponse() as? Response {
                return .success(empty)
            }
            return JSONDecoder().decode(Response.self, from: data, label: "xrpc response")
        }
    }

    /// Raw bytes from a public endpoint, e.g. `com.atproto.sync.getBlob`.
    public func publicData(
        _ nsid: String,
        params: [String: String] = [:],
        on service: URL
    ) async -> KnotenResult<Data> {
        await Self.url(service: service, nsid: nsid, params: params).then { url in
            await self.transport.send(Self.request(url: url, method: "GET", body: nil)).then { http in
                guard http.isSuccess else {
                    return .failure(.http(status: http.status, body: http.body))
                }
                return .success(http.data)
            }
        }
    }

    private func perform(_ request: URLRequest, session: OAuthSession) async -> KnotenResult<DPoPResult> {
        await DPoPKey.load(session.dpopKey).then { key in
            let result = await self.executor.send(
                request,
                key: key,
                nonce: session.dpopNonce,
                accessToken: session.accessToken
            )
            if case .success(let value) = result {
                await self.store.recordNonce(value.nonce)
            }
            return result
        }
    }

    private func decode<Response: Decodable>(_ result: DPoPResult) -> KnotenResult<Response> {
        guard result.status.isSuccess else {
            return .failure(.http(status: result.status, body: result.body))
        }
        if result.data.isEmpty, let empty = EmptyResponse() as? Response {
            return .success(empty)
        }
        return JSONDecoder().decode(Response.self, from: result.data, label: "xrpc response")
    }

    private static func request(url: URL, method: String, body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }

    static func url(service: URL, nsid: String, params: [String: String]) -> KnotenResult<URL> {
        guard var components = URLComponents(url: service, resolvingAgainstBaseURL: false) else {
            return .failure(.invalidURL(service.absoluteString))
        }

        let base = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = "\(base)/xrpc/\(nsid)"
        if !params.isEmpty {
            components.queryItems = params
                .map { URLQueryItem(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        }

        guard let url = components.url else {
            return .failure(.invalidURL(service.absoluteString))
        }
        return .success(url)
    }
}

private extension Int {
    var isSuccess: Bool {
        (200..<300).contains(self)
    }
}
