import KnotenCore

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
