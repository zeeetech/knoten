import Foundation

/// Tangled sends timestamps in two ISO 8601 shapes: with fractional seconds
/// (`2026-10-13T04:10:31.151Z`) and with a numeric offset
/// (`2026-10-13T06:24:36+03:00`). The default strategy reads both, offset
/// included, so no formatter state is needed.
public enum Timestamps {
    /// Nil when the text is not a timestamp. Callers sort on this, so a
    /// malformed value degrades to "unorderable" rather than failing a screen.
    public static func date(from text: String) -> Date? {
        try? Date(text, strategy: .iso8601)
    }
}
