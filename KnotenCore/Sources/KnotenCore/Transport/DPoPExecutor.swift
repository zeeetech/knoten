import Foundation

public struct DPoPResult: Sendable {
    public let data: Data
    public let response: HTTPURLResponse
    public let nonce: String?

    public var status: Int {
        response.statusCode
    }

    public var body: String {
        String(decoding: data, as: UTF8.self)
    }
}

/// Signs a request with DPoP and retries once when the server asks for a
/// fresh nonce, which it signals with a `400` carrying `use_dpop_nonce`.
public struct DPoPExecutor: Sendable {
    private let transport: Transport

    public init(transport: Transport = URLSessionTransport()) {
        self.transport = transport
    }

    public func send(
        _ request: URLRequest,
        key: DPoPKey,
        nonce: String?,
        accessToken: String? = nil
    ) async -> KnotenResult<DPoPResult> {
        let first = await attempt(request, key: key, nonce: nonce, accessToken: accessToken)
        switch first {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            guard isNonceFailure(result), let fresh = result.nonce else {
                return .success(result)
            }
            return await attempt(request, key: key, nonce: fresh, accessToken: accessToken)
        }
    }

    private func attempt(
        _ base: URLRequest,
        key: DPoPKey,
        nonce: String?,
        accessToken: String?
    ) async -> KnotenResult<DPoPResult> {
        guard let url = base.url else {
            return .failure(.invalidURL(""))
        }

        return await DPoPProof
            .build(
                key: key,
                method: base.httpMethod ?? "GET",
                url: url,
                nonce: nonce,
                accessToken: accessToken
            )
            .then { proof -> KnotenResult<DPoPResult> in
                var request = base
                request.setValue(proof, forHTTPHeaderField: "DPoP")
                if let accessToken {
                    request.setValue("DPoP \(accessToken)", forHTTPHeaderField: "Authorization")
                }

                return await self.transport.send(request).then { http -> KnotenResult<DPoPResult> in
                    .success(DPoPResult(
                        data: http.data,
                        response: http.response,
                        nonce: http.response.value(forHTTPHeaderField: "DPoP-Nonce")
                    ))
                }
            }
    }

    private func isNonceFailure(_ result: DPoPResult) -> Bool {
        guard result.status == 400 else { return false }
        let body = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any]
        return body?["error"] as? String == "use_dpop_nonce"
    }
}
