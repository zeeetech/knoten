import Foundation

/// The atproto blob reference embedded in records:
/// `{"$type":"blob","ref":{"$link":"<cid>"},"mimeType":"image/png","size":12345}`.
/// The `$type` marker is ignored; `cid` reads the link out of the nested ref.
public struct BlobRef: Decodable, Sendable {
    private struct Link: Decodable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case link = "$link"
        }

        let link: String
    }

    private enum CodingKeys: String, CodingKey {
        case ref, mimeType, size
    }

    private let ref: Link
    public let mimeType: String
    public let size: Int

    public var cid: String {
        ref.link
    }
}
