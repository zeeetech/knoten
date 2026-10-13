import Foundation
import Testing

@testable import KnotenCore

private func makeSession() -> OAuthSession {
    OAuthSession(
        did: "did:plc:abc123",
        handle: "zoey.tngl.sh",
        accessToken: "access-token",
        refreshToken: "refresh-token",
        scope: "atproto transition:generic",
        expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
        serviceURL: URL(string: "https://pds.example")!,
        issuer: URL(string: "https://auth.example")!,
        tokenEndpoint: URL(string: "https://auth.example/oauth/token")!,
        dpopKey: Data([1, 2, 3, 4])
    )
}

@Test func loadReturnsNilWhenEmpty() async {
    guard case .success(nil) = await InMemorySessionStorage().load() else {
        Issue.record("an empty store should load no session")
        return
    }
}

@Test func roundTripsASession() async {
    let storage = InMemorySessionStorage()
    let session = makeSession()

    let saved = await storage.save(session)
    #expect(saved.error == nil)

    guard case .success(let restored) = await storage.load() else {
        Issue.record("a saved session should load back")
        return
    }
    #expect(restored?.did == session.did)
    #expect(restored?.handle == session.handle)
    #expect(restored?.accessToken == session.accessToken)
    #expect(restored?.refreshToken == session.refreshToken)
    #expect(restored?.scope == session.scope)
    #expect(restored?.expiresAt == session.expiresAt)
    #expect(restored?.serviceURL == session.serviceURL)
    #expect(restored?.issuer == session.issuer)
    #expect(restored?.tokenEndpoint == session.tokenEndpoint)
    #expect(restored?.dpopKey == session.dpopKey)
}

@Test func saveReplacesTheStoredSession() async {
    let storage = InMemorySessionStorage()
    var renewed = makeSession()
    renewed.accessToken = "renewed-token"

    let first = await storage.save(makeSession())
    let second = await storage.save(renewed)
    #expect(first.error == nil)
    #expect(second.error == nil)

    guard case .success(let stored) = await storage.load() else {
        Issue.record("a saved session should load back")
        return
    }
    #expect(stored?.accessToken == "renewed-token")
}

@Test func clearRemovesTheSession() async {
    let storage = InMemorySessionStorage()

    let saved = await storage.save(makeSession())
    let cleared = await storage.clear()
    #expect(saved.error == nil)
    #expect(cleared.error == nil)

    guard case .success(nil) = await storage.load() else {
        Issue.record("a cleared store should load no session")
        return
    }
}
