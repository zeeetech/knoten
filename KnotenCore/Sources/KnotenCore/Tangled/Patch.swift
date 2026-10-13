import Foundation

/// A `git format-patch` payload, which is what a pull round's patch blob holds
/// once inflated: the round's diff against the target branch.
///
/// Parsing is total. Anything that does not look like a diff is skipped, so a
/// truncated or unfamiliar patch yields fewer files rather than an error.
public struct Patch: Sendable, Equatable {
    public let files: [PatchFile]

    public init(files: [PatchFile]) {
        self.files = files
    }

    public var additions: Int { files.reduce(0) { $0 + $1.additions } }
    public var deletions: Int { files.reduce(0) { $0 + $1.deletions } }
    public var isEmpty: Bool { files.isEmpty }

    public static func parse(_ text: String) -> Patch {
        var builder = Builder()
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            builder.consume(String(line))
        }
        return Patch(files: builder.finish())
    }

    /// Walks the lines, keeping one file and one hunk open at a time. A hunk
    /// ends when its header's line counts are used up, which is the only
    /// reliable end: the `-- ` signature and the next file look like content.
    private struct Builder {
        private var files: [PatchFile] = []

        private var path: String?
        private var oldPath: String?

        private var hunks: [PatchHunk] = []
        private var header: String?
        private var lines: [PatchLine] = []
        private var remainingOld = 0
        private var remainingNew = 0

        mutating func consume(_ line: String) {
            if header != nil, consumeHunkLine(line) { return }

            if line.hasPrefix("diff --git ") {
                closeFile()
                path = pathFromDiffLine(line)
                oldPath = nil
                return
            }
            if line.hasPrefix("--- ") {
                oldPath = clean(String(line.dropFirst(4)))
                return
            }
            if line.hasPrefix("+++ ") {
                let new = clean(String(line.dropFirst(4)))
                path = new == "/dev/null" ? oldPath : new
                return
            }
            if line.hasPrefix("@@"), let counts = counts(of: line) {
                header = line
                lines = []
                remainingOld = counts.old
                remainingNew = counts.new
            }
        }

        /// True when the line belonged to the open hunk.
        private mutating func consumeHunkLine(_ line: String) -> Bool {
            if line.hasPrefix("\\") {
                lines.append(PatchLine(kind: .marker, text: String(line.dropFirst()).trimmingCharacters(in: .whitespaces)))
                return true
            }

            if remainingOld <= 0, remainingNew <= 0 {
                closeHunk()
                return false
            }

            // A blank context line is sometimes written without its leading
            // space, so an empty line counts as one while lines remain.
            if line.isEmpty {
                lines.append(PatchLine(kind: .context, text: ""))
                remainingOld -= 1
                remainingNew -= 1
                return true
            }

            switch line.first {
            case "+":
                lines.append(PatchLine(kind: .addition, text: String(line.dropFirst())))
                remainingNew -= 1
            case "-":
                lines.append(PatchLine(kind: .deletion, text: String(line.dropFirst())))
                remainingOld -= 1
            case " ":
                lines.append(PatchLine(kind: .context, text: String(line.dropFirst())))
                remainingOld -= 1
                remainingNew -= 1
            default:
                closeHunk()
                return false
            }
            return true
        }

        private mutating func closeHunk() {
            if let header {
                hunks.append(PatchHunk(header: header, lines: lines))
            }
            header = nil
            lines = []
            remainingOld = 0
            remainingNew = 0
        }

        private mutating func closeFile() {
            closeHunk()
            if let path, !hunks.isEmpty {
                files.append(PatchFile(path: path, hunks: hunks))
            }
            path = nil
            hunks = []
        }

        mutating func finish() -> [PatchFile] {
            closeFile()
            return files
        }

        /// `--- a/x` or `+++ b/x`, with any tab separated timestamp dropped and
        /// the side prefix removed.
        private func clean(_ raw: String) -> String {
            let trimmed = raw.split(separator: "\t", maxSplits: 1).first.map(String.init) ?? raw
            if trimmed.hasPrefix("a/") || trimmed.hasPrefix("b/") {
                return String(trimmed.dropFirst(2))
            }
            return trimmed
        }

        /// The fallback path, for a diff that never reaches a `+++` line.
        private func pathFromDiffLine(_ line: String) -> String? {
            let rest = String(line.dropFirst("diff --git ".count))
            guard let range = rest.range(of: " b/", options: .backwards) else { return nil }
            let candidate = String(rest[range.upperBound...])
            return candidate.hasSuffix("\"") ? String(candidate.dropLast()) : candidate
        }

        /// `@@ -264,6 +264,10 @@` yields six old lines and ten new ones. A
        /// missing count means one line.
        private func counts(of line: String) -> (old: Int, new: Int)? {
            let tokens = line.split(separator: " ", omittingEmptySubsequences: true)
            guard tokens.count >= 3, tokens[0] == "@@" else { return nil }
            guard let old = count(tokens[1], sign: "-"), let new = count(tokens[2], sign: "+") else {
                return nil
            }
            return (old, new)
        }

        private func count(_ token: Substring, sign: Character) -> Int? {
            guard token.first == sign else { return nil }
            let parts = token.dropFirst().split(separator: ",", omittingEmptySubsequences: false)
            guard let start = parts.first, Int(start) != nil else { return nil }
            if parts.count == 1 { return 1 }
            return Int(parts[1])
        }
    }
}

/// One file of a patch, and the hunks that change it.
public struct PatchFile: Sendable, Equatable {
    public let path: String
    public let hunks: [PatchHunk]

    public init(path: String, hunks: [PatchHunk]) {
        self.path = path
        self.hunks = hunks
    }

    public var additions: Int { hunks.reduce(0) { $0 + $1.additions } }
    public var deletions: Int { hunks.reduce(0) { $0 + $1.deletions } }
}

/// One hunk of a patch: the `@@` header and the lines under it.
public struct PatchHunk: Sendable, Equatable {
    public let header: String
    public let lines: [PatchLine]

    public init(header: String, lines: [PatchLine]) {
        self.header = header
        self.lines = lines
    }

    public var additions: Int { lines.filter { $0.kind == .addition }.count }
    public var deletions: Int { lines.filter { $0.kind == .deletion }.count }
}

/// One line of a hunk, with the leading marker removed from `text`.
public struct PatchLine: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case context
        case addition
        case deletion
        /// `\ No newline at end of file`, kept so the diff reads true.
        case marker
    }

    public let kind: Kind
    public let text: String

    public init(kind: Kind, text: String) {
        self.kind = kind
        self.text = text
    }
}
