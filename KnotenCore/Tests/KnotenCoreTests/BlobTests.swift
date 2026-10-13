import Foundation
import Testing

@testable import KnotenCore

// The wire shape of an atproto blob: ref carries the CID under $link.
private let blobRef = """
{
  "$type": "blob",
  "ref": {"$link": "bafkreihxqvvqpmvi5gecgltkpdzhcsjsnywuoykgsqryawuuhefusm3z4m"},
  "mimeType": "image/png",
  "size": 12345
}
"""

actor RequestBox {
    var value: URLRequest?

    func record(_ request: URLRequest) {
        value = request
    }
}

@Test func decodesBlobRefFromNestedLink() throws {
    let blob = try JSONDecoder().decode(BlobRef.self, from: Data(blobRef.utf8))
    #expect(blob.cid == "bafkreihxqvvqpmvi5gecgltkpdzhcsjsnywuoykgsqryawuuhefusm3z4m")
    #expect(blob.mimeType == "image/png")
    #expect(blob.size == 12345)
}

@Test func decodesProfileRecordWithAvatar() throws {
    let data = Data("""
    {
      "bluesky": true,
      "avatar": \(blobRef),
      "description": "Senior Elixir engineer"
    }
    """.utf8)
    let profile = try JSONDecoder().decode(Profile.self, from: data)
    #expect(profile.avatar?.cid == "bafkreihxqvvqpmvi5gecgltkpdzhcsjsnywuoykgsqryawuuhefusm3z4m")
    #expect(profile.avatar?.mimeType == "image/png")
    #expect(profile.avatar?.size == 12345)
}

@Test func decodesProfileRecordWithoutAvatar() throws {
    let data = Data(#"{"bluesky": false}"#.utf8)
    let profile = try JSONDecoder().decode(Profile.self, from: data)
    #expect(profile.avatar == nil)
}

@Test func fetchesBlobFromActorPDS() async throws {
    let pds = URL(string: "https://pds.tngl.sh")!
    let box = RequestBox()
    let transport = StubTransport { request in
        await box.record(request)
        return .success(http(request.url, 200, body: "PNG-BYTES"))
    }

    let session = OAuthSession(
        did: "did:plc:owner000000000000000000000000",
        accessToken: "token",
        serviceURL: pds,
        issuer: pds,
        tokenEndpoint: URL(string: "https://pds.tngl.sh/oauth/token")!,
        dpopKey: DPoPKey().rawRepresentation
    )
    let loader = BlobLoader(client: XRPCClient(store: SessionStore(session: session), transport: transport))
    let blob = try JSONDecoder().decode(BlobRef.self, from: Data(blobRef.utf8))

    let result = await loader.fetch(blob, did: "did:plc:repodid0000000000000000000000aa", pds: pds)

    #expect(result.value == Data("PNG-BYTES".utf8))
    let request = try #require(await box.value)
    #expect(request.url?.host == "pds.tngl.sh")
    #expect(request.url?.path == "/xrpc/com.atproto.sync.getBlob")

    let url = try #require(request.url)
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let query = try #require(components?.queryItems)
    #expect(query.first { $0.name == "did" }?.value == "did:plc:repodid0000000000000000000000aa")
    #expect(query.first { $0.name == "cid" }?.value == "bafkreihxqvvqpmvi5gecgltkpdzhcsjsnywuoykgsqryawuuhefusm3z4m")
}
