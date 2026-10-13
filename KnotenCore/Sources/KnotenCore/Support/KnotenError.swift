import Foundation

public enum KnotenError: Error, Equatable {
    case network(String)
    case http(status: Int, body: String)
    case invalidURL(String)
    case invalidResponse(String)
    case unsupportedDIDMethod(String)
    case handleNotFound(String)
    case handleDIDMismatch(handle: String, did: String)
    case notFound
    case rateLimited
    case missingNonce
    case missingMetadataField(String)
    case invalidSession(String)
    case keychain(OSStatus)
    case cancelledLogin
}

extension KnotenError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network(let reason): "network failure: \(reason)"
        case .http(let status, _): "unexpected HTTP \(status)"
        case .invalidURL(let value): "invalid URL: \(value)"
        case .invalidResponse(let reason): "invalid response: \(reason)"
        case .unsupportedDIDMethod(let did): "unsupported DID method: \(did)"
        case .handleNotFound(let handle): "handle does not resolve: \(handle)"
        case .handleDIDMismatch(let handle, let did): "handle \(handle) does not claim \(did)"
        case .notFound: "not found"
        case .rateLimited: "rate limited"
        case .missingNonce: "response carried no DPoP nonce"
        case .missingMetadataField(let field): "metadata is missing \(field)"
        case .invalidSession(let reason): "invalid session: \(reason)"
        case .keychain(let status): "keychain failure: \(status)"
        case .cancelledLogin: "sign in was cancelled"
        }
    }
}
