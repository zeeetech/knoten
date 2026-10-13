import Foundation

public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}

/// Thin XRPC caller over a live session. Every request is DPoP signed, and a
/// rotated nonce is written back to the store.
public struct XRPCClient: Sendable {
    private let store: SessionStore
    private let executor: DPoPExecutor

    public init(store: SessionStore, transport: Transport = URLSessionTransport()) {
        self.store = store
        self.executor = DPoPExecutor(transport: transport)
    }

    public func get<Response: Decodable>(
        _ nsid: String,
        params: [String: String] = [:]
    ) async -> KnotenResult<Response> {
        let session = await store.current()
        return await call(method: "GET", nsid: nsid, params: params, body: nil, session: session)
    }

    /// Reads the raw body of an XRPC endpoint. `service` nil targets the
    /// session's own PDS, a URL targets another host, e.g. an actor's PDS for
    /// `com.atproto.sync.getBlob`.
    public func getData(
        _ nsid: String,
        params: [String: String],
        on service: URL? = nil
    ) async -> KnotenResult<Data> {
        let session = await store.current()
        return await request(method: "GET", nsid: nsid, params: params, body: nil, service: service, session: session)
            .then { result -> KnotenResult<Data> in
                guard result.status.isSuccess else {
                    return .failure(.http(status: result.status, body: result.body))
                }
                return .success(result.data)
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
        return await call(method: "POST", nsid: nsid, params: [:], body: encoded, session: session)
    }

    private func call<Response: Decodable>(
        method: String,
        nsid: String,
        params: [String: String],
        body: Data?,
        service: URL? = nil,
        session: OAuthSession
    ) async -> KnotenResult<Response> {
        await request(method: method, nsid: nsid, params: params, body: body, service: service, session: session)
            .then { result -> KnotenResult<Response> in
                self.decode(result)
            }
    }

    private func request(
        method: String,
        nsid: String,
        params: [String: String],
        body: Data?,
        service: URL?,
        session: OAuthSession
    ) async -> KnotenResult<DPoPResult> {
        await Self.url(service: service ?? session.serviceURL, nsid: nsid, params: params).then { url -> KnotenResult<DPoPResult> in
            var request = URLRequest(url: url)
            request.httpMethod = method
            if let body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }

            return await self.perform(request, session: session)
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
