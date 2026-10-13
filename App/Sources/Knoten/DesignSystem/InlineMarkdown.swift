import Foundation

/// The inline markdown the app supports: bold, italic, code and links.
///
/// `AttributedString` already parses that subset, so there is no renderer to
/// own here. Only inline syntax is read, which leaves a comment reading the way
/// it was written and keeps block syntax from turning a short reply into a page.
enum InlineMarkdown {
    static func attributed(_ source: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: source, options: options))
            ?? AttributedString(source)
    }
}
