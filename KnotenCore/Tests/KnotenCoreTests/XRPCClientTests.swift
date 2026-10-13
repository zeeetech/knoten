import Foundation
import Testing

@testable import KnotenCore

@Test func buildsXRPCURLWithSortedParams() {
    let url = XRPCClient.url(
        service: URL(string: "https://pds.tngl.sh")!,
        nsid: "sh.tangled.repo.list",
        params: ["limit": "20", "cursor": "abc"]
    )
    #expect(url.value?.absoluteString == "https://pds.tngl.sh/xrpc/sh.tangled.repo.list?cursor=abc&limit=20")
}

@Test func keepsServicePathPrefix() {
    let url = XRPCClient.url(
        service: URL(string: "https://tngl.sh/pds")!,
        nsid: "com.atproto.server.describeServer",
        params: [:]
    )
    #expect(url.value?.absoluteString == "https://tngl.sh/pds/xrpc/com.atproto.server.describeServer")
}

@Test func formEncodesReservedCharacters() {
    let encoded = Authorizer.encode(["scope": "atproto transition:generic", "a": "b c"])
    #expect(encoded == "a=b%20c&scope=atproto%20transition%3Ageneric")
}
