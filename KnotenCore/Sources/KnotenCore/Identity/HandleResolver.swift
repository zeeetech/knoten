import Foundation

/// Resolves a handle to a DID, and checks the claim is bidirectional.
///
/// Two techniques, per the handle spec: the HTTPS well-known endpoint, then a
/// DNS TXT record. DNS is done over HTTPS because the platform gives us no TXT
/// lookup, and it keeps the resolver usable from any transport.
public struct HandleResolver: Sendable {
    private static let dnsEndpoint = URL(string: "https://cloudflare-dns.com/dns-query")

    private let transport: Transport

    public init(transport: Transport = URLSessionTransport()) {
        self.transport = transport
    }

    public func resolve(_ handle: String) async -> KnotenResult<String> {
        if handle.hasPrefix("did:") {
            return .success(handle)
        }

        switch await resolveWellKnown(handle) {
        case .success(let did):
            return .success(did)
        case .failure:
            break
        }

        switch await resolveDNS(handle) {
        case .success(let did):
            return .success(did)
        case .failure:
            return .failure(.handleNotFound(handle))
        }
    }

    /// The DID document must claim the handle back, otherwise a handle could
    /// point at someone else's account.
    public func verify(handle: String, did: String) async -> KnotenResult<Void> {
        await DIDResolver(transport: transport).resolve(did).then { document in
            document.handle == handle
                ? .success(())
                : .failure(.handleDIDMismatch(handle: handle, did: did))
        }
    }

    private func resolveWellKnown(_ handle: String) async -> KnotenResult<String> {
        guard let url = URL(string: "https://\(handle)/.well-known/atproto-did") else {
            return .failure(.invalidURL(handle))
        }

        return await transport.send(URLRequest(url: url)).then { http -> KnotenResult<String> in
            guard http.status == 200 else {
                return .failure(.handleNotFound(handle))
            }
            let did = http.body.trimmingCharacters(in: .whitespacesAndNewlines)
            guard did.hasPrefix("did:") else {
                return .failure(.handleNotFound(handle))
            }
            return .success(did)
        }
    }

    private func resolveDNS(_ handle: String) async -> KnotenResult<String> {
        guard
            let endpoint = Self.dnsEndpoint,
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        else {
            return .failure(.invalidURL(handle))
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: "_atproto.\(handle)"),
            URLQueryItem(name: "type", value: "TXT"),
        ]
        guard let url = components.url else {
            return .failure(.invalidURL(handle))
        }

        var request = URLRequest(url: url)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")

        return await transport.send(request).then { http -> KnotenResult<String> in
            guard http.status == 200 else {
                return .failure(.handleNotFound(handle))
            }
            return await JSONDecoder().decode(DNSResponse.self, from: http.data, label: "dns answer for \(handle)")
                .then { response -> KnotenResult<String> in
                    let raw = response.answers?.first { $0.type == 16 }?.data
                    guard let did = raw.flatMap(Self.did(fromTXT:)) else {
                        return .failure(.handleNotFound(handle))
                    }
                    return .success(did)
                }
        }
    }

    /// The record reads `did=<did>`. Older records carry the bare DID.
    static func did(fromTXT raw: String) -> String? {
        let value = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let candidate = value.hasPrefix("did=") ? String(value.dropFirst("did=".count)) : value
        return candidate.hasPrefix("did:") ? candidate : nil
    }

    /// Cloudflare and Google both answer with a capitalized `Answer` key.
    private struct DNSResponse: Decodable {
        let answers: [Answer]?

        enum CodingKeys: String, CodingKey {
            case answers = "Answer"
        }

        struct Answer: Decodable {
            let type: Int
            let data: String
        }
    }
}
