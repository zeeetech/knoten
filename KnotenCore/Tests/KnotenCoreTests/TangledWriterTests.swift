import Foundation
import Testing

@testable import KnotenCore

// A write needs a live session, which a test cannot have. What can be checked
// without one is the record, against the shape a real sh.tangled.feed.comment
// record has.

@Test func encodesTheCommentRecordTheServerStores() throws {
    let request = CreateRecordRequest(
        repo: "did:plc:me",
        collection: Tangled.feedComment,
        record: CommentRecord(
            body: "**bold** and `code`",
            createdAt: "2026-01-01T00:00:00Z",
            subject: CommentSubject(
                uri: "at://did:plc:author/sh.tangled.repo.pull/1",
                cid: "bafyreiabc"
            )
        )
    )

    let json = try #require(
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
    )

    #expect(json["repo"] as? String == "did:plc:me")
    #expect(json["collection"] as? String == "sh.tangled.feed.comment")

    let record = try #require(json["record"] as? [String: Any])
    #expect(record["$type"] as? String == "sh.tangled.feed.comment")
    #expect(record["createdAt"] as? String == "2026-01-01T00:00:00Z")

    let body = try #require(record["body"] as? [String: Any])
    #expect(body["$type"] as? String == "sh.tangled.markup.markdown")
    #expect(body["original"] as? String == "**bold** and `code`")
    #expect(body["text"] as? String == "**bold** and `code`")

    let subject = try #require(record["subject"] as? [String: Any])
    #expect(subject["uri"] as? String == "at://did:plc:author/sh.tangled.repo.pull/1")
    #expect(subject["cid"] as? String == "bafyreiabc")
}

@Test func writesOnlyTheKeysACommentRecordHas() throws {
    let request = CreateRecordRequest(
        repo: "did:plc:me",
        collection: Tangled.feedComment,
        record: CommentRecord(
            body: "hi",
            createdAt: "2026-01-01T00:00:00Z",
            subject: CommentSubject(uri: "at://x/y/z", cid: "b")
        )
    )

    let json = try #require(
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
    )
    let record = try #require(json["record"] as? [String: Any])
    let body = try #require(record["body"] as? [String: Any])

    #expect(Set(record.keys) == ["$type", "body", "createdAt", "subject"])
    #expect(Set(body.keys) == ["$type", "original", "text"])
}

@Test func roundTripsATimestampThroughTheWireForm() throws {
    let date = Date(timeIntervalSince1970: 1_800_000_000)
    let back = try #require(Timestamps.date(from: Timestamps.string(from: date)))

    #expect(abs(back.timeIntervalSince(date)) < 1)
}
