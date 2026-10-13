import Testing

@testable import KnotenCore

// RFC 7636, Appendix B.
@Test func matchesRFC7636Vector() {
    let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
    #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
}

@Test func generatesUniqueVerifiers() {
    #expect(PKCE().verifier != PKCE().verifier)
}
