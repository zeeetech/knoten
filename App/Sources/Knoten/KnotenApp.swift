import SwiftUI

@main
struct KnotenApp: App {
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
                    await purchases.watch()
                }
        }
    }
}
