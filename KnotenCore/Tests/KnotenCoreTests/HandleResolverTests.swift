import Foundation
import Testing

@testable import KnotenCore

@Test func resolvesViaWellKnown() async {
    let transport = StubTransport { request in
        .success(http(request.url, 200, body: "did:plc:abc123"))
    }

    let resolved = await HandleResolver(transport: transport).resolve("zoey.tngl.sh")
    #expect(resolved.value == "did:plc:abc123")
}

@Test func fallsBackToDNSOverHTTPS() async {
    let transport = StubTransport { request in
        guard request.url?.path.contains("dns-query") == true else {
            return .success(http(request.url, 404))
        }
        let body = #"{"Answer":[{"name":"_atproto.zoey.tngl.sh","type":16,"data":"\"did:plc:abc123\""}]}"#
        return .success(http(request.url, 200, body: body))
    }

    let resolved = await HandleResolver(transport: transport).resolve("zoey.tngl.sh")
    #expect(resolved.value == "did:plc:abc123")
}

// Real records carry the `did=` prefix, which is what tangled.org and
// bsky.app both answer today.
@Test func readsThePrefixedTXTRecord() async {
    let transport = StubTransport { request in
        guard request.url?.path.contains("dns-query") == true else {
            return .success(http(request.url, 404))
        }
        let body = #"{"Answer":[{"name":"_atproto.tangled.org","type":16,"data":"\"did=did:plc:wshs7t2adsemcrrd4snkeqli\""}]}"#
        return .success(http(request.url, 200, body: body))
    }

    let resolved = await HandleResolver(transport: transport).resolve("tangled.org")
    #expect(resolved.value == "did:plc:wshs7t2adsemcrrd4snkeqli")
}

@Test func rejectsATXTRecordThatIsNotADID() {
    #expect(HandleResolver.did(fromTXT: "\"hello world\"") == nil)
    #expect(HandleResolver.did(fromTXT: "\"did=not-a-did\"") == nil)
    #expect(HandleResolver.did(fromTXT: "\"did=did:plc:abc\"") == "did:plc:abc")
    #expect(HandleResolver.did(fromTXT: "\"did:plc:abc\"") == "did:plc:abc")
}

@Test func passesThroughDIDs() async {
    let transport = StubTransport { request in
        .success(http(request.url, 404))
    }

    let resolved = await HandleResolver(transport: transport).resolve("did:plc:abc123")
    #expect(resolved.value == "did:plc:abc123")
}

@Test func failsWhenHandleDoesNotResolve() async {
    let transport = StubTransport { request in
        .success(http(request.url, 404))
    }

    let resolved = await HandleResolver(transport: transport).resolve("nobody.example")
    #expect(resolved.error == .handleNotFound("nobody.example"))
}

@Test func rejectsHandleThatDoesNotClaimTheDID() async {
    let transport = StubTransport { request in
        .success(http(
            request.url,
            200,
            body: #"{"id":"did:plc:abc123","alsoKnownAs":["at://someone.else"]}"#
        ))
    }

    let verified = await HandleResolver(transport: transport).verify(handle: "zoey.tngl.sh", did: "did:plc:abc123")
    #expect(verified.error == .handleDIDMismatch(handle: "zoey.tngl.sh", did: "did:plc:abc123"))
}
