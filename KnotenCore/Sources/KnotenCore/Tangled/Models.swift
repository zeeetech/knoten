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
/// `rounds`. Blob fields (blobs, round.patchBlob) are not read by the 0.1.0
/// UI and are left out.
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

    public struct Round: Decodable, Sendable {
        public let createdAt: String
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

/// sh.tangled.actor.profile record. Requires `bluesky`. The avatar is a blob
/// and is not read by the 0.1.0 UI.
public struct Profile: Decodable, Sendable {
    public let bluesky: Bool
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
