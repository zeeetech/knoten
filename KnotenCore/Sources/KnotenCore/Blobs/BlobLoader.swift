import Foundation

/// Fetches blob bytes from the actor's PDS, through a cache.
///
/// `com.atproto.sync.getBlob` returns the original bytes with no resizing, so
/// the app downscales before it renders. The read is public and carries no
/// session headers.
public struct BlobLoader: Sendable {
    private let client: XRPCClient
    private let cache: BlobCache

    public init(client: XRPCClient, cache: BlobCache) {
        self.client = client
        self.cache = cache
    }

    public func fetch(_ blob: BlobRef, did: String, pds: URL) async -> KnotenResult<Data> {
        let key = Self.key(did: did, cid: blob.cid)
        if let cached = await cache.read(key) {
            return .success(cached)
        }

        let fetched = await client.publicData(
            "com.atproto.sync.getBlob",
            params: ["did": did, "cid": blob.cid],
            on: pds
        )

        if case .success(let data) = fetched {
            await cache.write(data, key: key)
        }
        return fetched
    }

    public static func key(did: String, cid: String) -> String {
        "\(did)/\(cid)"
    }
}
