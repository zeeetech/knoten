import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                Placeholder(title: "Home")
            }
            Tab("Repos", systemImage: "shippingbox") {
                ReposView()
            }
            Tab("Pulls", systemImage: "arrow.triangle.pull") {
                Placeholder(title: "Pulls")
            }
            Tab("Inbox", systemImage: "bell") {
                Placeholder(title: "Inbox")
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

private struct Placeholder: View {
    let title: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: "hammer",
                description: Text("Coming in 0.1.0.")
            )
            .navigationTitle(title)
        }
    }
}
