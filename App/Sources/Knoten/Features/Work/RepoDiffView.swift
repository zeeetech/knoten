import KnotenCore
import SwiftUI

/// The unified diff of a pull, one card per file.
///
/// Lines do not wrap: a diff is read by column, so each file scrolls sideways.
/// A file past the cap names what it left out instead of laying it out, because
/// a large patch is cheap to fetch and expensive to render.
struct RepoDiffView: View {
    let patch: Patch

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            ForEach(patch.files.indices, id: \.self) { index in
                DiffFileCard(file: patch.files[index])
            }
        }
    }
}

/// One line of the rendered diff: either a hunk header or a hunk line.
private enum DiffEntry {
    case header(String)
    case line(PatchLine)
}

private struct DiffFileCard: View {
    let file: PatchFile

    /// About a screen of scrolling per file.
    private static let lineCap = 300

    var body: some View {
        let parts = entries

        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(parts.shown.indices, id: \.self) { index in
                        DiffEntryRow(entry: parts.shown[index])
                    }

                    if parts.hidden > 0 {
                        Text("\(parts.hidden) more lines")
                            .font(.identifier(.caption2))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, Theme.Space.sm)
                            .padding(.vertical, Theme.Space.sm)
                    }
                }
                .padding(.vertical, Theme.Space.xs)
            }
        }
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var header: some View {
        HStack(spacing: Theme.Space.sm) {
            Text(file.path)
                .font(.identifier(.caption).weight(.semibold))
                .lineLimit(1)
                .truncationMode(.head)

            Spacer(minLength: Theme.Space.sm)

            if file.additions > 0 {
                Text("+\(file.additions)")
                    .font(.identifier(.caption2))
                    .foregroundStyle(Theme.Palette.trust)
            }
            if file.deletions > 0 {
                Text("-\(file.deletions)")
                    .font(.identifier(.caption2))
                    .foregroundStyle(DiffColor.deletion)
            }
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, Theme.Space.sm)
        .background(Theme.Palette.surfaceHigh)
    }

    private var entries: (shown: [DiffEntry], hidden: Int) {
        let all = file.hunks.flatMap { hunk in
            [DiffEntry.header(hunk.header)] + hunk.lines.map(DiffEntry.line)
        }
        return (Array(all.prefix(Self.lineCap)), max(0, all.count - Self.lineCap))
    }
}

private struct DiffEntryRow: View {
    let entry: DiffEntry

    var body: some View {
        switch entry {
        case .header(let text):
            Text(text)
                .font(.identifier(.caption2))
                .foregroundStyle(Theme.Palette.ide)
                .padding(.horizontal, Theme.Space.sm)
                .padding(.vertical, 2)
                .background(Theme.Palette.surfaceHigh)

        case .line(let line):
            HStack(alignment: .top, spacing: Theme.Space.sm) {
                Text(marker)
                    .font(.identifier(.caption2))
                    .foregroundStyle(.tertiary)
                    .frame(width: 8, alignment: .center)

                Text(line.text)
                    .font(.identifier(.caption))
                    .foregroundStyle(DiffColor.text(for: line.kind))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, 1)
            .background(DiffColor.background(for: line.kind))
        }
    }

    private var marker: String {
        switch entry {
        case .header:
            return ""
        case .line(let line):
            switch line.kind {
            case .addition: return "+"
            case .deletion: return "-"
            case .context: return " "
            case .marker: return "\\"
            }
        }
    }
}

/// The two diff colors. Additions take the app's trust green; deletions take the
/// system red, which the palette already leans on for system surfaces.
private enum DiffColor {
    static let deletion = Color(.systemRed)

    static func text(for kind: PatchLine.Kind) -> Color {
        switch kind {
        case .addition: return Theme.Palette.trust
        case .deletion: return deletion
        case .context, .marker: return .secondary
        }
    }

    static func background(for kind: PatchLine.Kind) -> Color {
        switch kind {
        case .addition: return Theme.Palette.trust.opacity(0.12)
        case .deletion: return deletion.opacity(0.12)
        case .context, .marker: return .clear
        }
    }
}
