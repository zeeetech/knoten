import Foundation

public struct DIDResolver: Sendable {
    private let transport: Transport

    public init(transport: Transport = URLSessionTransport()) {
        self.transport = transport
    }

    public func resolve(_ did: String) async -> KnotenResult<DIDDocument> {
        if did.hasPrefix("did:plc:") {
            return await plcURL(did).then { await self.fetch($0) }
        }
        if did.hasPrefix("did:web:") {
            return await webURL(did).then { await self.fetch($0) }
        }
        return .failure(.unsupportedDIDMethod(did))
    }

    private func plcURL(_ did: String) -> KnotenResult<URL> {
        guard let url = URL(string: "https://plc.directory/\(did)") else {
            return .failure(.invalidURL(did))
        }
        return .success(url)
    }

    /// `did:web:example.com` maps to `https://example.com/.well-known/did.json`.
    /// Colons become path separators, with `%3A` the escape for a real port.
    private func webURL(_ did: String) -> KnotenResult<URL> {
        let host = String(did.dropFirst("did:web:".count))
            .replacingOccurrences(of: "%3A", with: ":")
            .replacingOccurrences(of: ":", with: "/")
        guard let url = URL(string: "https://\(host)/.well-known/did.json") else {
            return .failure(.invalidURL(did))
        }
        return .success(url)
    }

    private func fetch(_ url: URL) async -> KnotenResult<DIDDocument> {
        await transport.send(URLRequest(url: url)).then { http -> KnotenResult<DIDDocument> in
            switch http.status {
            case 200:
                return JSONDecoder().decode(DIDDocument.self, from: http.data, label: "DID document for \(url)")
            case 404:
                return .failure(.notFound)
            case 429:
                return .failure(.rateLimited)
            default:
                return .failure(.http(status: http.status, body: http.body))
            }
        }
    }
}
