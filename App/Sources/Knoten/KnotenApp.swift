import SwiftUI

@main
struct KnotenApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var purchases = PurchaseStore()
    @State private var session = SessionModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(purchases)
                .environment(session)
                .task {
                    await session.restore()
                    await purchases.refresh()
                    // Watches transaction updates, so it never returns.
                    await purchases.watch()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                BackgroundRefresh.schedule()
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await BackgroundRefresh.run(session: session)
        }
    }
}
