import KnotenCore

/// Names for wire values in the one form a person reads. Every one of these has
/// a fallback, because neither a repo name nor a handle is guaranteed to be
/// there.

extension PullItem {
    /// A pull opened from a patch, rather than from a branch, carries no source,
    /// so only the target is named.
    var branchLabel: String {
        guard let source = value.source?.branch else {
            return value.target.branch
        }
        return "\(source) -> \(value.target.branch)"
    }
}

extension RecordView where Value == Repo {
    /// A repo record may carry no name, in which case the record key is the slug
    /// the repo is addressed by.
    var repoName: String {
        if let name = value.name, !name.isEmpty { return name }
        return uri.split(separator: "/").last.map(String.init) ?? uri
    }
}
