import SwiftUI

/// The comment box: a markdown editor with the four inline styles the app
/// renders, and nothing else.
///
/// The markers are inserted as text rather than hidden behind a rich model, so
/// what is in the box is exactly what gets written to the record.
struct CommentComposer: View {
    let isSending: Bool
    let failure: String?
    let onSend: (String) async -> Bool

    @State private var text = ""
    @State private var selection: TextSelection?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            formatting
            editor

            if let failure {
                Text(failure)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            footer
        }
        .padding(Theme.Space.md)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var formatting: some View {
        HStack(spacing: Theme.Space.xl) {
            style("bold", "Bold") { wrap("**") }
            style("italic", "Italic") { wrap("*") }
            style("chevron.left.forwardslash.chevron.right", "Code") { wrap("`") }
            style("link", "Link", action: wrapLink)

            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.Palette.ide)
    }

    private func style(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
    }

    private var editor: some View {
        TextEditor(text: $text, selection: $selection)
            .font(.subheadline)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 88)
            .padding(Theme.Space.sm)
            .background(
                Theme.Palette.surfaceHigh,
                in: RoundedRectangle(cornerRadius: Theme.Radius.inner)
            )
            .focused($focused)
    }

    private var footer: some View {
        HStack {
            Text("Inline markdown")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer(minLength: Theme.Space.sm)

            Button {
                Task {
                    if await onSend(text) {
                        text = ""
                        focused = false
                    }
                }
            } label: {
                if isSending {
                    ProgressView()
                } else {
                    Text("Comment")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    /// Wraps the selection in a marker. With nothing selected the pair goes in
    /// and the caret lands between them, so the next thing typed is inside.
    private func wrap(_ marker: String) {
        guard let target = selectionTarget() else {
            text += marker + marker
            return
        }

        let replacement = marker + target.selected + marker
        let caret = target.length == 0
            ? target.location + marker.utf16.count
            : target.location + replacement.utf16.count
        replace(target, with: replacement, caret: caret)
    }

    private func wrapLink() {
        guard let target = selectionTarget() else {
            text += "[](url)"
            return
        }

        // The caret lands on the placeholder url, which is the part to replace.
        let replacement = "[\(target.selected)](url)"
        let caret = target.location + 1 + target.selected.utf16.count + 2
        replace(target, with: replacement, caret: caret)
    }

    /// The selection as UTF-16 offsets, which is what `NSString` and the editor
    /// both count in. Nil when the box has never been focused, so there is no
    /// range to work against.
    private func selectionTarget() -> (location: Int, length: Int, selected: String)? {
        guard let selection, case .selection(let range) = selection.indices else { return nil }

        let location = range.lowerBound.utf16Offset(in: text)
        let length = range.upperBound.utf16Offset(in: text) - location
        let selected = (text as NSString).substring(with: NSRange(location: location, length: length))
        return (location, length, selected)
    }

    private func replace(
        _ target: (location: Int, length: Int, selected: String),
        with replacement: String,
        caret: Int
    ) {
        text = (text as NSString).replacingCharacters(
            in: NSRange(location: target.location, length: target.length),
            with: replacement
        )
        selection = TextSelection(insertionPoint: String.Index(utf16Offset: caret, in: text))
    }
}
