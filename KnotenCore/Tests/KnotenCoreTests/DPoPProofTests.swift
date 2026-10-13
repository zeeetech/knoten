import CryptoKit
import Foundation
import Testing

@testable import KnotenCore

private func segments(_ jwt: String) throws -> (header: [String: Any], claims: [String: Any], signature: Data) {
    let parts = jwt.split(separator: ".").map(String.init)
    guard parts.count == 3,
          let headerData = B64URL.decode(parts[0]),
          let claimsData = B64URL.decode(parts[1]),
          let signature = B64URL.decode(parts[2]),
          let header = try JSONSerialization.jsonObject(with: headerData) as? [String: Any],
          let claims = try JSONSerialization.jsonObject(with: claimsData) as? [String: Any]
    else {
        throw KnotenError.invalidResponse("not a JWS")
    }
    return (header, claims, signature)
}

private func proof(_ key: DPoPKey, method: String = "GET", url: String, nonce: String? = nil, accessToken: String? = nil) throws -> String {
    try #require(DPoPProof.build(
        key: key,
        method: method,
        url: URL(string: url)!,
        nonce: nonce,
        accessToken: accessToken
    ).value)
}

@Test func headerCarriesPublicJWK() throws {
    let key = DPoPKey()
    let (header, _, _) = try segments(try proof(key, url: "https://pds.tngl.sh/xrpc/x"))

    #expect(header["alg"] as? String == "ES256")
    #expect(header["typ"] as? String == "dpop+jwt")

    let jwk = try #require(header["jwk"] as? [String: String])
    #expect(jwk["kty"] == "EC")
    #expect(jwk["crv"] == "P-256")
    #expect(jwk["x"] == key.jwk["x"])
}

@Test func htuStripsQueryAndFragment() throws {
    let (_, claims, _) = try segments(
        try proof(DPoPKey(), url: "https://pds.tngl.sh/xrpc/sh.tangled.repo.list?limit=20#frag")
    )
    #expect(claims["htu"] as? String == "https://pds.tngl.sh/xrpc/sh.tangled.repo.list")
}

@Test func carriesNonceWhenGiven() throws {
    let (_, claims, _) = try segments(
        try proof(DPoPKey(), url: "https://pds.tngl.sh/xrpc/x", nonce: "abc")
    )
    #expect(claims["nonce"] as? String == "abc")
}

@Test func bindsAccessTokenWithAth() throws {
    let (_, claims, _) = try segments(
        try proof(DPoPKey(), method: "POST", url: "https://pds.tngl.sh/xrpc/x", accessToken: "token-123")
    )
    let expected = B64URL.encode(Data(SHA256.hash(data: Data("token-123".utf8))))
    #expect(claims["ath"] as? String == expected)
}

@Test func signatureVerifiesAgainstEmbeddedJWK() throws {
    let key = DPoPKey()
    let proof = try proof(key, url: "https://pds.tngl.sh/xrpc/x")
    let (header, _, signature) = try segments(proof)

    let jwk = try #require(header["jwk"] as? [String: String])
    let x = try #require(jwk["x"].flatMap(B64URL.decode))
    let y = try #require(jwk["y"].flatMap(B64URL.decode))
    let publicKey = try P256.Signing.PublicKey(x963Representation: Data([0x04]) + x + y)

    let parts = proof.split(separator: ".").map(String.init)
    let ecdsa = try P256.Signing.ECDSASignature(rawRepresentation: signature)

    #expect(publicKey.isValidSignature(ecdsa, for: Data("\(parts[0]).\(parts[1])".utf8)))
}

@Test func everyProofIsUnique() throws {
    let key = DPoPKey()
    #expect(try proof(key, url: "https://pds.tngl.sh/xrpc/x") != (try proof(key, url: "https://pds.tngl.sh/xrpc/x")))
}
