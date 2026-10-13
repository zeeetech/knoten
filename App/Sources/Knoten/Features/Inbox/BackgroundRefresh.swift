import BackgroundTasks
import KnotenCore
import UserNotifications

/// The periodic refresh behind the inbox badge.
///
/// There is no push in 0.1.0, so the badge is whatever the last run worked out,
/// and the system decides when a run actually happens. The task only needs the
/// count, so it builds the same inbox the screen does and throws it away.
enum BackgroundRefresh {
    /// Must match `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
    static let identifier = "io.zeetech.knoten.inbox-refresh"

    private static let interval: TimeInterval = 60 * 60

    /// Asks the system for another run. The request is consumed when it fires,
    /// so this is called again every time the app goes to the background.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        try? BGTaskScheduler.shared.submit(request)
    }

    @MainActor
    static func run(session: SessionModel) async {
        guard let account = session.account else { return }

        let inbox = InboxModel(account: account)
        await inbox.load()
        await setBadge(inbox.unreadCount)
    }

    /// Badges need permission. A refusal is not an error worth surfacing: the
    /// inbox works fine without a badge, it just stops announcing itself.
    @MainActor
    static func requestBadgeAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.badge])
    }

    @MainActor
    private static func setBadge(_ count: Int) async {
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
