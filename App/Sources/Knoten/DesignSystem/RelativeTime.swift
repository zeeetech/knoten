import Foundation

/// Compact relative labels for lists: `18m`, `4h`, `2d`.
///
/// The automatic relative style counts seconds (`18 min, 9 secs`), which turns a
/// list into noise. Past a week the label becomes a date.
enum RelativeTime {
    static func label(for date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        switch seconds {
        case ..<60:
            return "now"
        case ..<3_600:
            return "\(Int(seconds / 60))m"
        case ..<86_400:
            return "\(Int(seconds / 3_600))h"
        case ..<604_800:
            return "\(Int(seconds / 86_400))d"
        default:
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}
