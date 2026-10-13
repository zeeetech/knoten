import Foundation

/// Writes against the account's own repository.
///
/// Deliberately separate from `TangledClient`: those reads go to the API host
/// and carry no credential, while a write goes to the account's PDS and carries
/// the session token. That token is bound to one PDS, so it must not travel to
/// the API host.
public struct TangledWriter: Sendable {
    private let client: XRPCClient
    private let did: String

    public init(client: XRPCClient, did: String) {
        self.client = client
        self.did = did
    }

    /// Creates a comment on a record, in the account's own repository.
    ///
    /// The subject carries the cid as well as the uri, which is what anchors the
    /// comment to the revision it was written against.
    public func comment(
        on subject: CommentSubject,
        body: String,
        at createdAt: Date = Date()
    ) async -> KnotenResult<CreatedRecord> {
        await client.post(
            "com.atproto.repo.createRecord",
            body: CreateRecordRequest(
                repo: did,
                collection: Tangled.feedComment,
                record: CommentRecord(
                    body: body,
                    createdAt: Timestamps.string(from: createdAt),
                    subject: subject
                )
            )
        )
    }
}

/// What a comment is anchored to: the record's address and its content hash.
public struct CommentSubject: Encodable, Sendable {
    public let uri: String
    public let cid: String

    public init(uri: String, cid: String) {
        self.uri = uri
        self.cid = cid
    }
}

/// Output of com.atproto.repo.createRecord. The record is not echoed back, so a
/// caller that wants to show the comment reads it again.
public struct CreatedRecord: Decodable, Sendable {
    public let uri: String
    public let cid: String
}

/// The request body of com.atproto.repo.createRecord.
///
/// Internal rather than private so the shape can be checked against a real
/// record without a live session, which is the only part of a write that can be
/// checked without one.
struct CreateRecordRequest<Record: Encodable>: Encodable {
    let repo: String
    let collection: String
    let record: Record
}

/// The sh.tangled.feed.comment record as it goes on the wire.
struct CommentRecord: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case body, createdAt, subject
    }

    let type = Tangled.feedComment
    let body: CommentMarkup
    let createdAt: String
    let subject: CommentSubject

    init(body: String, createdAt: String, subject: CommentSubject) {
        self.body = CommentMarkup(original: body, text: body)
        self.createdAt = createdAt
        self.subject = subject
    }
}

/// The markup union a comment body carries.
///
/// Both fields hold the markdown the author typed. Every record observed has
/// them equal, and the renderer runs at display time, so writing them equal is
/// the shape the server already holds.
struct CommentMarkup: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case original, text
    }

    let type = Tangled.markupMarkdown
    let original: String
    let text: String
}
