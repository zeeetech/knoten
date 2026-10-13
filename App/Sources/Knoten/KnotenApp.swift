import SwiftUI

@main
struct KnotenApp: App {
    @State private var purchases = PurchaseStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(purchases)
                .task {
                    await purchases.refresh()
                    await purchases.watch()
                }
        }
    }
}
