import CryptoKit
import Foundation

public enum DPoPProof {
    public static func build(
        key: DPoPKey,
        method: String,
        url: URL,
        nonce: String? = nil,
        accessToken: String? = nil
    ) -> KnotenResult<String> {
        var claims: [String: Any] = [
            "jti": B64URL.encode(Random.bytes(16)),
            "htm": method.uppercased(),
            "htu": canonical(url),
            "iat": Int(Date().timeIntervalSince1970),
        ]
        if let nonce {
            claims["nonce"] = nonce
        }
        if let accessToken {
            claims["ath"] = B64URL.encode(Data(SHA256.hash(data: Data(accessToken.utf8))))
        }

        return JWT.sign(
            header: ["alg": "ES256", "typ": "dpop+jwt", "jwk": key.jwk],
            claims: claims,
            key: key.privateKey
        )
    }

    /// RFC 9449 §4.2: `htu` carries no query or fragment.
    static func canonical(_ url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        return components?.url?.absoluteString ?? url.absoluteString
    }
}
