import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            Tab("Repos", systemImage: "shippingbox") {
                ReposView()
            }
            Tab("Work", systemImage: "arrow.triangle.pull") {
                RepoItemsView(kind: .pulls)
            }
            Tab("Inbox", systemImage: "bell") {
                InboxView()
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}
