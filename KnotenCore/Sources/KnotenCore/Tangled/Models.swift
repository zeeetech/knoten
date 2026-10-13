import Foundation

/// sh.tangled.repo record. Requires `knot` and `createdAt`.
public struct Repo: Decodable, Sendable {
    public let name: String?
    public let knot: String
    public let spindle: String?
    public let description: String?
    public let website: String?
    public let topics: [String]?
    public let source: String?
    public let labels: [String]?
    public let repoDid: String?
    public let createdAt: String
}

/// sh.tangled.repo.pull record. Requires `target`, `title`, `createdAt` and
/// `rounds`.
public struct Pull: Decodable, Sendable {
    public let title: String
    public let body: String?
    public let rounds: [Round]
    public let source: Source?
    public let target: Target
    public let createdAt: String
    public let mentions: [String]?
    public let references: [String]?
    public let dependentOn: String?
    public let blobs: [BlobRef]?

    /// revisions of this pull, newer rounds are appended. The patch blob is
    /// gzipped `git format-patch` text.
    public struct Round: Decodable, Sendable {
        public let createdAt: String
        public let patchBlob: BlobRef?
    }

    /// source of the pull. Requires `branch`.
    public struct Source: Decodable, Sendable {
        public let branch: String
        public let repo: String?
    }

    /// target of the pull. Requires `repo` and `branch`.
    public struct Target: Decodable, Sendable {
        public let repo: String
        public let branch: String
    }
}

/// sh.tangled.repo.issue record. Requires `repo`, `title` and `createdAt`.
public struct Issue: Decodable, Sendable {
    public let repo: String
    public let title: String
    public let body: String?
    public let createdAt: String
    public let mentions: [String]?
    public let references: [String]?
    public let blobs: [BlobRef]?
}

/// sh.tangled.ci.pipeline. Requires `id`, `trigger`, `commit` and `workflows`.
/// The record-like object a spindle owns, so it may live outside a PDS.
public struct Pipeline: Decodable, Sendable {
    public let id: String
    public let repo: String?
    public let trigger: Trigger
    public let commit: String
    public let sourceRepo: String?
    public let createdAt: String?
    public let workflows: [Workflow]

    /// A union of sh.tangled.ci.trigger#push/#pullRequest/#manual/#schedule,
    /// on the wire as one flat object with a $type discriminator. Fields from
    /// different variants overlap, so every field is optional and `type`
    /// says which variant is present.
    public struct Trigger: Decodable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case type = "$type"
            case ref, newSha, oldSha
            case action, sourceRepo, sourceBranch, targetBranch, sourceSha, pull
            case sha, scheduledAt
        }

        public let type: String?
        public let ref: String?
        public let newSha: String?
        public let oldSha: String?
        public let action: String?
        public let sourceRepo: String?
        public let sourceBranch: String?
        public let targetBranch: String?
        public let sourceSha: String?
        public let pull: String?
        public let sha: String?
        public let scheduledAt: String?
    }

    public struct Workflow: Decodable, Sendable {
        public let id: String
        public let name: String
        public let status: String
        public let startedAt: String?
        public let finishedAt: String?
        public let error: String?
    }
}

/// sh.tangled.knot record. The knot registers itself with nothing but a
/// creation time; the identity is in the record's AT-URI.
public struct Knot: Decodable, Sendable {
    public let createdAt: String
}

/// sh.tangled.actor.profile record. Requires `bluesky`.
public struct Profile: Decodable, Sendable {
    public let bluesky: Bool
    public let avatar: BlobRef?
    public let description: String?
    public let links: [String]?
    public let stats: [String]?
    public let location: String?
    public let pinnedRepositories: [String]?
    public let pronouns: String?
    public let preferredHandle: String?
}

/// A record with its address: the shape every list item and single-record
/// fetch returns. `value` is the embedded record.
public struct RecordView<Value: Decodable & Sendable>: Decodable, Sendable {
    public let uri: String
    public let cid: String?
    public let value: Value
}

/// Output of a listRepos/listKnots call: record views plus a pagination
/// cursor.
public struct RecordPage<Value: Decodable & Sendable>: Decodable, Sendable {
    public let items: [RecordView<Value>]
    public let cursor: String?
}

/// Item of sh.tangled.repo.listPulls: the pull record plus its derived state.
public struct PullItem: Decodable, Sendable {
    public let uri: String
    public let cid: String?
    public let value: Pull
    public let state: String
    public let stateUpdatedAt: String?
    public let commentCount: Int
}

/// Output of sh.tangled.repo.listPulls.
public struct PullPage: Decodable, Sendable {
    public let items: [PullItem]
    public let cursor: String?
}

/// Item of sh.tangled.repo.listIssues: the issue record plus its derived state.
public struct IssueItem: Decodable, Sendable {
    public let uri: String
    public let cid: String?
    public let value: Issue
    public let state: String
    public let stateUpdatedAt: String?
    public let commentCount: Int
}

/// Output of sh.tangled.repo.listIssues.
public struct IssuePage: Decodable, Sendable {
    public let items: [IssueItem]
    public let cursor: String?
}

/// Output of sh.tangled.ci.queryPipelines.
public struct PipelinePage: Decodable, Sendable {
    public let cursor: String?
    public let total: Int
    public let pipelines: [Pipeline]
}

/// An account reference as feeds present it: a DID plus, when the appview
/// knows one, a handle.
public struct Actor: Decodable, Sendable {
    public let did: String
    public let handle: String?

    /// The handle when there is one, otherwise the DID. A handle is the only
    /// form of this worth showing a person.
    public var label: String {
        handle ?? did
    }
}

/// A repo as the appview presents it in feeds: the derived view, with an owner
/// and counters. Not the sh.tangled.repo record, which carries `knot` and no
/// owner; this carries `owner` and `slug` and no `knot`.
public struct RepoSummary: Decodable, Sendable {
    public let did: String
    public let slug: String
    public let owner: Actor
    public let description: String?
    public let createdAt: String?
    public let starCount: Int?
    public let forkCount: Int?
    public let openIssueCount: Int?
    public let openPullCount: Int?

    /// `owner/slug`, the way a repo is named.
    public var name: String {
        "\(owner.label)/\(slug)"
    }
}

/// One event of sh.tangled.feed.getTimeline. On the wire it is a union
/// discriminated by the fragment of `$type`; each case carries only what its
/// variant has. An unrecognized variant is kept, not dropped, so a new event
/// type on the server does not empty the feed.
public enum TimelineEvent: Decodable, Sendable {
    case follow(actor: Actor, subject: Actor, uri: String, cid: String?)
    case repo(RepoSummary, uri: String, cid: String?)
    case star(actor: Actor, repo: RepoSummary, uri: String, cid: String?)
    case unknown(type: String, uri: String)

    /// The event's AT-URI. Every variant carries one, and it is what tells two
    /// events apart.
    public var uri: String {
        switch self {
        case .follow(_, _, let uri, _), .repo(_, let uri, _), .star(_, _, let uri, _):
            return uri
        case .unknown(_, let uri):
            return uri
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case actor, subject, repo, uri, cid
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        let uri = try container.decodeIfPresent(String.self, forKey: .uri) ?? ""
        let cid = try container.decodeIfPresent(String.self, forKey: .cid)

        switch type.split(separator: "#").last.map(String.init) ?? type {
        case "followEvent":
            self = .follow(
                actor: try container.decode(Actor.self, forKey: .actor),
                subject: try container.decode(Actor.self, forKey: .subject),
                uri: uri,
                cid: cid
            )
        case "repoEvent":
            self = .repo(try container.decode(RepoSummary.self, forKey: .repo), uri: uri, cid: cid)
        case "starEvent":
            self = .star(
                actor: try container.decode(Actor.self, forKey: .actor),
                repo: try container.decode(RepoSummary.self, forKey: .repo),
                uri: uri,
                cid: cid
            )
        default:
            self = .unknown(type: type, uri: uri)
        }
    }
}

/// One item of sh.tangled.feed.getTimeline: an event and when it happened.
public struct TimelineItem: Decodable, Sendable {
    public let event: TimelineEvent
    public let eventAt: String

    /// Identity for lists. The event's AT-URI, not the timestamp, which can
    /// repeat when several events land in the same millisecond.
    public var id: String {
        event.uri
    }
}

/// Output of sh.tangled.feed.getTimeline. The feed is the whole network: the
/// server accepts no actor filter and ignores one if it is sent.
public struct TimelinePage: Decodable, Sendable {
    public let feed: [TimelineItem]
    public let cursor: String?
}

/// A markup body, the shape sh.tangled.feed.comment carries: `original` is what
/// the author typed, `text` is the rendered plain form.
public struct Markup: Decodable, Sendable {
    public let original: String?
    public let text: String?

    /// The best plain text there is, empty when the body carries none.
    public var plain: String {
        text ?? original ?? ""
    }
}

/// Item of sh.tangled.feed.listComments. The subject is the commented record,
/// so one comment type serves both pulls and issues.
public struct FeedComment: Decodable, Sendable {
    public let uri: String
    public let cid: String?
    public let createdAt: String
    public let body: Markup
    public let subject: Subject

    public struct Subject: Decodable, Sendable {
        public let uri: String
        public let cid: String?
    }

    /// The author's DID: the repository the comment record lives in. The feed
    /// sends no handle, so this is the only identity on the wire.
    public var author: String? {
        guard uri.hasPrefix("at://") else { return nil }
        let parts = uri.dropFirst("at://".count).split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count >= 3 else { return nil }
        return String(parts[0])
    }
}

/// Output of sh.tangled.feed.listComments.
public struct FeedCommentPage: Decodable, Sendable {
    public let items: [FeedComment]
    public let total: Int?
}
