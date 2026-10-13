import Foundation

/// When the inbox was last cleared.
///
/// Unread is "newer than the last clear", which is cheaper than a flag per item
/// and is what clearing means to a person. The mark is the newest item on
/// screen rather than the wall clock, so a refresh a second later does not
/// resurrect rows that were already read.
struct InboxSeenStore {
    private static let key = "io.zeetech.knoten.inbox.lastSeenAt"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastSeenAt: Date? {
        defaults.object(forKey: Self.key) as? Date
    }

    func markSeen(at date: Date) {
        defaults.set(date, forKey: Self.key)
    }
}
