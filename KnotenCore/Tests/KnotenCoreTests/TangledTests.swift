import Foundation
import Testing

@testable import KnotenCore

// Fixtures shaped exactly like the sh.tangled.* lexicons in
// tangled.org/core. Field names come from the lexicon JSON, not from us.

private let repoRecord = """
{
  "name": "knoten",
  "knot": "knot1.tangled.sh",
  "spindle": "spindle1.tangled.sh",
  "description": "Native Tangled client for iOS",
  "website": "https://example.dev",
  "topics": ["swift", "atproto"],
  "source": "https://tangled.org/zoey/knoten",
  "labels": ["at://did:plc:labeler/sh.tangled.label.definition/self"],
  "repoDid": "did:plc:repodid0000000000000000000000aa",
  "createdAt": "2026-01-15T09:30:00Z"
}
"""

private let pullRecord = """
{
  "title": "Add pipeline list",
  "body": "Adds the CI list screen.",
  "rounds": [
    {
      "createdAt": "2026-02-01T10:00:00Z",
      "patchBlob": {"$type": "blob", "ref": {"$link": "bafkreihaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}, "mimeType": "application/gzip", "size": 512}
    },
    {
      "createdAt": "2026-02-02T10:00:00Z",
      "patchBlob": {"$type": "blob", "ref": {"$link": "bafkreihbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}, "mimeType": "application/gzip", "size": 640}
    }
  ],
  "source": {"branch": "feat/pipelines", "repo": "did:plc:forker00000000000000000000000"},
  "target": {"repo": "did:plc:repodid0000000000000000000000aa", "branch": "main"},
  "createdAt": "2026-02-01T09:00:00Z",
  "mentions": ["did:plc:reviewer000000000000000000000"],
  "references": ["at://did:plc:repodid0000000000000000000000aa/sh.tangled.repo.issue/3j2kk"],
  "dependentOn": "at://did:plc:repodid0000000000000000000000aa/sh.tangled.repo.pull/42"
}
"""

private let issueRecord = """
{
  "repo": "did:plc:repodid0000000000000000000000aa",
  "title": "Crash on empty diff",
  "body": "Steps to reproduce below.",
  "createdAt": "2026-02-02T11:00:00Z",
  "mentions": ["did:plc:reviewer000000000000000000000"],
  "references": ["at://did:plc:repodid0000000000000000000000aa/sh.tangled.repo.pull/42"]
}
"""

private let pipelineRecord = """
{
  "id": "01HQABCDEF",
  "repo": "did:plc:repodid0000000000000000000000aa",
  "trigger": {
    "$type": "sh.tangled.ci.trigger#push",
    "ref": "refs/heads/main",
    "newSha": "0123456789abcdef0123456789abcdef01234567",
    "oldSha": "fedcba9876543210fedcba9876543210fedcba98"
  },
  "commit": "0123456789abcdef0123456789abcdef01234567",
  "sourceRepo": "did:plc:forker00000000000000000000000",
  "createdAt": "2026-02-03T12:00:00Z",
  "workflows": [
    {
      "id": "build",
      "name": "build",
      "status": "success",
      "startedAt": "2026-02-03T12:00:05Z",
      "finishedAt": "2026-02-03T12:01:00Z"
    },
    {
      "id": "test",
      "name": "test",
      "status": "failed",
      "error": "exit status 1"
    }
  ]
}
"""

private let knotRecord = """
{
  "createdAt": "2025-06-01T00:00:00Z"
}
"""

private let profileRecord = """
{
  "bluesky": true,
  "description": "Senior Elixir engineer",
  "links": ["https://zeetech.io"],
  "stats": ["repository-count", "star-count"],
  "location": "Sao Paulo",
  "pinnedRepositories": ["did:plc:repodid0000000000000000000000aa"],
  "pronouns": "she/her",
  "preferredHandle": "zoey.tngl.sh"
}
"""

@Test func decodesRepoRecord() throws {
    let repo = try JSONDecoder().decode(Repo.self, from: Data(repoRecord.utf8))
    #expect(repo.name == "knoten")
    #expect(repo.knot == "knot1.tangled.sh")
    #expect(repo.spindle == "spindle1.tangled.sh")
    #expect(repo.description == "Native Tangled client for iOS")
    #expect(repo.topics == ["swift", "atproto"])
    #expect(repo.repoDid == "did:plc:repodid0000000000000000000000aa")
    #expect(repo.createdAt == "2026-01-15T09:30:00Z")
}

@Test func decodesMinimalRepoRecord() throws {
    let data = Data(#"{"knot": "knot1.tangled.sh", "createdAt": "2026-01-15T09:30:00Z"}"#.utf8)
    let repo = try JSONDecoder().decode(Repo.self, from: data)
    #expect(repo.knot == "knot1.tangled.sh")
    #expect(repo.name == nil)
    #expect(repo.description == nil)
    #expect(repo.repoDid == nil)
}

@Test func decodesPullRecord() throws {
    let pull = try JSONDecoder().decode(Pull.self, from: Data(pullRecord.utf8))
    #expect(pull.title == "Add pipeline list")
    #expect(pull.rounds.count == 2)
    #expect(pull.rounds.first?.createdAt == "2026-02-01T10:00:00Z")
    #expect(pull.source?.branch == "feat/pipelines")
    #expect(pull.source?.repo == "did:plc:forker00000000000000000000000")
    #expect(pull.target.branch == "main")
    #expect(pull.mentions == ["did:plc:reviewer000000000000000000000"])
    #expect(pull.dependentOn == "at://did:plc:repodid0000000000000000000000aa/sh.tangled.repo.pull/42")
}

@Test func decodesMinimalPullRecord() throws {
    let data = Data("""
    {
      "title": "Doc fix",
      "rounds": [],
      "target": {"repo": "did:plc:repodid0000000000000000000000aa", "branch": "main"},
      "createdAt": "2026-02-01T09:00:00Z"
    }
    """.utf8)
    let pull = try JSONDecoder().decode(Pull.self, from: data)
    #expect(pull.rounds.isEmpty)
    #expect(pull.source == nil)
    #expect(pull.body == nil)
}

@Test func decodesIssueRecord() throws {
    let issue = try JSONDecoder().decode(Issue.self, from: Data(issueRecord.utf8))
    #expect(issue.repo == "did:plc:repodid0000000000000000000000aa")
    #expect(issue.title == "Crash on empty diff")
    #expect(issue.body == "Steps to reproduce below.")
    #expect(issue.createdAt == "2026-02-02T11:00:00Z")
    #expect(issue.references?.count == 1)
}

@Test func decodesPipelineWithPushTrigger() throws {
    let pipeline = try JSONDecoder().decode(Pipeline.self, from: Data(pipelineRecord.utf8))
    #expect(pipeline.id == "01HQABCDEF")
    #expect(pipeline.trigger.type == "sh.tangled.ci.trigger#push")
    #expect(pipeline.trigger.ref == "refs/heads/main")
    #expect(pipeline.trigger.newSha == "0123456789abcdef0123456789abcdef01234567")
    #expect(pipeline.trigger.action == nil)
    #expect(pipeline.workflows.count == 2)
    #expect(pipeline.workflows[0].status == "success")
    #expect(pipeline.workflows[1].status == "failed")
    #expect(pipeline.workflows[1].error == "exit status 1")
    #expect(pipeline.workflows[1].finishedAt == nil)
}

@Test func decodesPipelineWithPullRequestTrigger() throws {
    let data = Data("""
    {
      "id": "01HQFFFF",
      "trigger": {
        "$type": "sh.tangled.ci.trigger#pullRequest",
        "action": "synchronize",
        "sourceRepo": "did:plc:forker00000000000000000000000",
        "sourceBranch": "feat/pipelines",
        "targetBranch": "main",
        "sourceSha": "0123456789abcdef0123456789abcdef01234567",
        "pull": "at://did:plc:author/sh.tangled.repo.pull/3j2kk"
      },
      "commit": "0123456789abcdef0123456789abcdef01234567",
      "workflows": [{"id": "build", "name": "build", "status": "pending"}]
    }
    """.utf8)
    let pipeline = try JSONDecoder().decode(Pipeline.self, from: data)
    #expect(pipeline.trigger.type == "sh.tangled.ci.trigger#pullRequest")
    #expect(pipeline.trigger.action == "synchronize")
    #expect(pipeline.trigger.targetBranch == "main")
    #expect(pipeline.trigger.sourceSha == "0123456789abcdef0123456789abcdef01234567")
    #expect(pipeline.trigger.ref == nil)
    #expect(pipeline.repo == nil)
    #expect(pipeline.workflows[0].startedAt == nil)
}

@Test func decodesKnotRecord() throws {
    let knot = try JSONDecoder().decode(Knot.self, from: Data(knotRecord.utf8))
    #expect(knot.createdAt == "2025-06-01T00:00:00Z")
}

@Test func decodesProfileRecord() throws {
    let profile = try JSONDecoder().decode(Profile.self, from: Data(profileRecord.utf8))
    #expect(profile.bluesky == true)
    #expect(profile.description == "Senior Elixir engineer")
    #expect(profile.links == ["https://zeetech.io"])
    #expect(profile.stats == ["repository-count", "star-count"])
    #expect(profile.pinnedRepositories == ["did:plc:repodid0000000000000000000000aa"])
    #expect(profile.preferredHandle == "zoey.tngl.sh")
}

@Test func decodesMinimalProfileRecord() throws {
    let data = Data(#"{"bluesky": false}"#.utf8)
    let profile = try JSONDecoder().decode(Profile.self, from: data)
    #expect(profile.bluesky == false)
    #expect(profile.description == nil)
    #expect(profile.preferredHandle == nil)
}

@Test func decodesRecordViewOfRepo() throws {
    let data = Data("""
    {
      "uri": "at://did:plc:owner/sh.tangled.repo/did:plc:repodid0000000000000000000000aa",
      "cid": "bafyreibbb",
      "value": \(repoRecord)
    }
    """.utf8)
    let view = try JSONDecoder().decode(RecordView<Repo>.self, from: data)
    #expect(view.uri == "at://did:plc:owner/sh.tangled.repo/did:plc:repodid0000000000000000000000aa")
    #expect(view.cid == "bafyreibbb")
    #expect(view.value.knot == "knot1.tangled.sh")
}

@Test func decodesPullPage() throws {
    let data = Data("""
    {
      "items": [
        {
          "uri": "at://did:plc:author/sh.tangled.repo.pull/3j2kk",
          "cid": "bafyreiccc",
          "value": \(pullRecord),
          "state": "open",
          "stateUpdatedAt": "2026-02-01T10:05:00Z",
          "commentCount": 2
        }
      ],
      "cursor": "3j2kk::next"
    }
    """.utf8)
    let page = try JSONDecoder().decode(PullPage.self, from: data)
    #expect(page.items.count == 1)
    #expect(page.items[0].state == "open")
    #expect(page.items[0].commentCount == 2)
    #expect(page.items[0].value.title == "Add pipeline list")
    #expect(page.cursor == "3j2kk::next")
}

@Test func decodesIssuePageWithoutCursor() throws {
    let data = Data("""
    {
      "items": [
        {
          "uri": "at://did:plc:author/sh.tangled.repo.issue/3j2kk",
          "value": \(issueRecord),
          "state": "closed",
          "commentCount": 0
        }
      ]
    }
    """.utf8)
    let page = try JSONDecoder().decode(IssuePage.self, from: data)
    #expect(page.items.count == 1)
    #expect(page.items[0].state == "closed")
    #expect(page.items[0].stateUpdatedAt == nil)
    #expect(page.items[0].commentCount == 0)
    #expect(page.cursor == nil)
}

@Test func decodesPipelinePage() throws {
    let data = Data("""
    {
      "cursor": "01HQABCDEF",
      "total": 1,
      "pipelines": [\(pipelineRecord)]
    }
    """.utf8)
    let page = try JSONDecoder().decode(PipelinePage.self, from: data)
    #expect(page.total == 1)
    #expect(page.pipelines.count == 1)
    #expect(page.pipelines[0].trigger.type == "sh.tangled.ci.trigger#push")
    #expect(page.cursor == "01HQABCDEF")
}
