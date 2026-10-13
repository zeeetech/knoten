import StoreKit
import SwiftUI

struct TipJarView: View {
    @State private var session = FocusSession(cleared: 47, minutes: 4)

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(session.headline)
                        .font(.subheadline.weight(.semibold))
                        .contentTransition(.numericText())
                    Text(session.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .animation(.smooth, value: session)
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.md) {
                        ForEach(ProductID.tips, id: \.self) { id in
                            TipCard(id: id)
                        }
                    }
                    .padding(.vertical, Theme.Space.xs)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Buy me a coffee")
    }
}

private struct TipCard: View {
    let id: String

    var body: some View {
        VStack(spacing: Theme.Space.sm) {
            Text(emoji)
                .font(.title)
            ProductView(id: id)
                .productViewStyle(.compact)
        }
        .frame(width: 150)
        .padding(Theme.Space.lg)
        .background(Theme.Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.Palette.separator)
        }
    }

    private var emoji: String {
        switch id {
        case "knoten.tip.espresso": "☕️"
        case "knoten.tip.cappuccino": "🥛"
        case "knoten.tip.coldbrew": "🧊"
        default: "☕️"
        }
    }
}
