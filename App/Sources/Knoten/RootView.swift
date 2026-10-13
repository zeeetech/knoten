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
            Tab("Pulls", systemImage: "arrow.triangle.pull") {
                PullsView()
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
