import SwiftUI

struct ServerSettingsView: View {
    @Environment(PurchaseStore.self) private var purchases
    @State private var showPaywall = false

    var body: some View {
        List {
            Section("Instance") {
                LabeledContent("AppView") {
                    Text("tangled.org")
                        .font(.identifier(.subheadline))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Handle") {
                    Text("@zoey.tngl.sh")
                        .font(.identifier(.subheadline))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Status") {
                    HStack(spacing: Theme.Space.sm) {
                        StatusDot()
                        Text("connected")
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.trust)
                    }
                }
            }

            section(title: "Custom Knots", preview: ["git.zoey.dev", "knot.tngl.sh"])
            section(title: "Custom PDS", preview: ["https://pds.zoey.dev", "verify"])
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Server")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationCornerRadius(Theme.Radius.sheet)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func section(title: String, preview: [String]) -> some View {
        Section {
            if purchases.isPro {
                ForEach(preview, id: \.self) { value in
                    Text(value)
                        .font(.identifier(.subheadline))
                }
            } else {
                ForEach(preview, id: \.self) { value in
                    lockedRow(value)
                }
                unlockRow
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                if !purchases.isPro {
                    PROBadge()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.bouncy(duration: 0.45), value: purchases.isPro)
    }

    private func lockedRow(_ value: String) -> some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                LockedPreview {
                    Text(value)
                        .font(.identifier(.subheadline))
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private var unlockRow: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Text("Unlock with Knoten Pro")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(Theme.Palette.trust)
        }
    }
}
