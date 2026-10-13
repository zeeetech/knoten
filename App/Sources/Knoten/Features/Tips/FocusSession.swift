import SwiftUI

/// What the tip jar reacts to. The app tracks how much noise Focus Mode
/// cleared, and the copy stays quiet until there is something to celebrate.
struct FocusSession: Equatable {
    var cleared: Int = 0
    var minutes: Int = 0
    var streakDays: Int = 0

    var headline: String {
        if streakDays >= 3 {
            return "\(streakDays) days of inbox zero. Respect."
        }
        if cleared > 0 {
            return "You cleared \(cleared) PRs in \(minutes) min."
        }
        return "Knoten is a one-person project."
    }

    var detail: String {
        cleared > 0
            ? "That is faster than a coffee. Want to buy one?"
            : "Tips fund the notification relay and the App Store fee."
    }
}
