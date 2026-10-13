import KnotenCore

/// A record opened against a repo: a pull or an issue.
///
/// The two come from different endpoints but carry the same fields, and the
/// server scopes both queries to a repo, so the screens that show them are one
/// screen with a kind rather than two that drift apart.
enum RepoItem: Identifiable, Sendable {
    case pull(PullItem)
    case issue(IssueItem)

    var id: String {
        switch self {
        case .pull(let pull): return pull.uri
        case .issue(let issue): return issue.uri
        }
    }

    var title: String {
        switch self {
        case .pull(let pull): return pull.value.title
        case .issue(let issue): return issue.value.title
        }
    }

    var body: String? {
        switch self {
        case .pull(let pull): return pull.value.body
        case .issue(let issue): return issue.value.body
        }
    }

    var state: String {
        switch self {
        case .pull(let pull): return pull.state
        case .issue(let issue): return issue.state
        }
    }

    var commentCount: Int {
        switch self {
        case .pull(let pull): return pull.commentCount
        case .issue(let issue): return issue.commentCount
        }
    }

    var createdAt: String {
        switch self {
        case .pull(let pull): return pull.value.createdAt
        case .issue(let issue): return issue.value.createdAt
        }
    }

    /// What a comment is anchored to. The cid is part of the record, so a pull
    /// or issue without one cannot be commented on.
    var uri: String { id }

    var cid: String? {
        switch self {
        case .pull(let pull): return pull.cid
        case .issue(let issue): return issue.cid
        }
    }

    /// Only a pull has branches; an issue has none to name.
    var branchLabel: String? {
        guard case .pull(let pull) = self else { return nil }
        return pull.branchLabel
    }

    /// Only a pull has a diff to show.
    var isPull: Bool {
        if case .pull = self { return true }
        return false
    }

    var kind: Kind {
        switch self {
        case .pull: return .pulls
        case .issue: return .issues
        }
    }

    enum Kind: String, CaseIterable, Sendable {
        case pulls = "Pulls"
        case issues = "Issues"

        var singular: String {
            switch self {
            case .pulls: return "pull"
            case .issues: return "issue"
            }
        }

        var plural: String {
            switch self {
            case .pulls: return "pulls"
            case .issues: return "issues"
            }
        }

        var symbol: String {
            switch self {
            case .pulls: return "arrow.triangle.pull"
            case .issues: return "exclamationmark.bubble"
            }
        }
    }
}
