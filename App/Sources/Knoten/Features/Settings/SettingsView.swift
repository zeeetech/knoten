import SwiftUI

struct SettingsView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(SessionModel.self) private var session

    var body: some View {
        List {
            Section {
                if case .signedIn(let account) = session.state {
                    HStack(spacing: Theme.Space.md) {
                        if let services = session.account {
                            AvatarView(
                                blob: session.avatar,
                                did: services.did,
                                pds: services.pds,
                                loader: services.blobs
                            )
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.handle ?? account.did)
                                .font(.identifier(.subheadline))
                            Text("Signed in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
