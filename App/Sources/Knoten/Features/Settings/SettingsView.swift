import SwiftUI

struct SettingsView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(SessionModel.self) private var session

    var body: some View {
        List {
            Section {
                if case .signedIn(let account) = session.state {
                    LabeledContent("Account") {
                        Text(account.handle ?? account.did)
                            .font(.identifier(.subheadline))
                    }
                    Button("Sign out", role: .destructive) {
                        Task { await session.logout() }
                    }
                } else {
                    NavigationLink {
                        LoginView()
                    } label: {
                        Label("Sign in", systemImage: "person")
                    }
                }
            }

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
