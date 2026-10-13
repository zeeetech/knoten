import Foundation
import Testing

@testable import KnotenCore

private actor Recorder {
    private(set) var hosts: [String] = []

    func record(_ host: String?) {
        if let host {
            hosts.append(host)
        }
    }
}

private func session(service: String) -> OAuthSession {
    OAuthSession(
        did: "did:plc:tester",
        accessToken: "token",
        serviceURL: URL(string: service)!,
        issuer: URL(string: "https://auth.example")!,
        tokenEndpoint: URL(string: "https://auth.example/oauth/token")!,
        dpopKey: DPoPKey().rawRepresentation
    )
}

private let profileBody = """
{"uri":"at://did:plc:tester/sh.tangled.actor.profile/self","cid":"bafy","value":{"bluesky":true}}
"""

@Test func profileQueriesGoToTheAPIHostNotThePDS() async {
    let recorder = Recorder()
    let transport = StubTransport { request in
        await recorder.record(request.url?.host)
        return .success(http(request.url, 200, body: profileBody))
    }

    let client = XRPCClient(store: SessionStore(session: session(service: "https://pds.example")), transport: transport)
    let tangled = TangledClient(client: client, api: URL(string: "https://api.tangled.org")!)

    let fetched = await tangled.getProfile(actor: "at://did:plc:tester/sh.tangled.actor.profile/self")

    #expect(fetched.value?.value.bluesky == true)
    #expect(await recorder.hosts == ["api.tangled.org"])
}

@Test func readsDecodeWithoutASessionOnTheAPIHost() async {
    let transport = StubTransport { request in
        .success(http(request.url, 200, body: #"{"items":[],"cursor":null}"#))
    }

    let client = XRPCClient(store: SessionStore(session: session(service: "https://pds.example")), transport: transport)
    let tangled = TangledClient(client: client, api: URL(string: "https://api.tangled.org")!)

    let listed = await tangled.listRepos(subject: "did:plc:tester")

    #expect(listed.value?.items.isEmpty == true)
}
