import Foundation
import Testing

@testable import KnotenCore

@Test func retriesOnceWithAFreshNonce() async {
    let counter = Counter()
    let transport = StubTransport { request in
        let attempt = await counter.next()
        guard attempt > 1 else {
            return .success(http(
                request.url,
                400,
                body: #"{"error":"use_dpop_nonce"}"#,
                headers: ["DPoP-Nonce": "fresh"]
            ))
        }
        return .success(http(request.url, 200, body: "{}", headers: ["DPoP-Nonce": "fresh"]))
    }

    let result = await DPoPExecutor(transport: transport).send(
        URLRequest(url: URL(string: "https://pds.tngl.sh/xrpc/x")!),
        key: DPoPKey(),
        nonce: nil
    )

    #expect(result.value?.status == 200)
    #expect(await counter.value == 2)
}

@Test func doesNotRetryOnOtherErrors() async {
    let counter = Counter()
    let transport = StubTransport { request in
        _ = await counter.next()
        return .success(http(request.url, 500))
    }

    let result = await DPoPExecutor(transport: transport).send(
        URLRequest(url: URL(string: "https://pds.tngl.sh/xrpc/x")!),
        key: DPoPKey(),
        nonce: nil
    )

    #expect(result.value?.status == 500)
    #expect(await counter.value == 1)
}
