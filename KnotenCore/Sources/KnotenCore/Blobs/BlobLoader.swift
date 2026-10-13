import Foundation

/// Fetches blob bytes from an actor's PDS over the authenticated XRPC path,
/// the protocol-native way to render an avatar. Thin by design: the app hangs
/// an image cache on this seam later.
///
/// com.atproto.sync.getBlob returns the original bytes with no resizing, so
/// the app downscales client side.
public struct BlobLoader: Sendable {
    private let client: XRPCClient

    public init(client: XRPCClient) {
        self.client = client
    }

    public func fetch(_ blob: BlobRef, did: String, pds: URL) async -> KnotenResult<Data> {
        await client.getData(
            "com.atproto.sync.getBlob",
            params: ["did": did, "cid": blob.cid],
            on: pds
        )
    }
}
