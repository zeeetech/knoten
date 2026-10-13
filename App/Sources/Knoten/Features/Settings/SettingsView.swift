import SwiftUI

struct SettingsView: View {
    @Environment(PurchaseStore.self) private var purchases

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ServerSettingsView()
                } label: {
                    Label("Server", systemImage: "server.rack")
                }
                NavigationLink {
                    TipJarView()
                } label: {
                    Label("Buy me a coffee", systemImage: "cup.and.saucer")
                }
            }

            if !purchases.isPro {
                Section {
                    NavigationLink {
                        PaywallView()
                    } label: {
                        HStack {
                            Label("Knoten Pro", systemImage: "sparkles")
                            Spacer()
                            PROBadge()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
    }
}
