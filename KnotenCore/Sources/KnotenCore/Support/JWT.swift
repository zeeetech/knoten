import CryptoKit
import Foundation

/// Minimal JWS for the ES256 case only.
///
/// CryptoKit signs into the raw `r || s` form, which is already what JWS
/// expects, so there is no DER round trip here.
enum JWT {
    static func sign(
        header: [String: Any],
        claims: [String: Any],
        key: P256.Signing.PrivateKey
    ) -> KnotenResult<String> {
        guard
            let headerSegment = try? segment(header),
            let claimsSegment = try? segment(claims)
        else {
            return .failure(.invalidResponse("jwt payload is not encodable"))
        }

        let signingInput = "\(B64URL.encode(headerSegment)).\(B64URL.encode(claimsSegment))"
        guard let signature = try? key.signature(for: Data(signingInput.utf8)) else {
            return .failure(.invalidResponse("jwt signature failed"))
        }

        return .success("\(signingInput).\(B64URL.encode(signature.rawRepresentation))")
    }

    private static func segment(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
