import StoreKit
import SwiftUI

struct PaywallView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                header
                benefits
                tipJar
            }
            .padding(Theme.Space.xl)
        }
        .background(Theme.Palette.canvas)
        .safeAreaInset(edge: .bottom) { purchaseBar }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.Palette.pro)

            Text("Unlock Knoten Pro")
                .font(.largeTitle.weight(.bold))

            Text("One-time purchase. Yours forever.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            BenefitRow(
                symbol: "server.rack",
                title: "Custom PDS and Knots",
                detail: "Host your code on your own hardware."
            )
            BenefitRow(
                symbol: "personalhotspot",
                title: "Multi-account",
                detail: "Switch between personal and work profiles."
            )
            BenefitRow(
                symbol: "bell.badge",
                title: "Native push for stacked PRs",
                detail: "Real time, once the relay lands."
            )
            BenefitRow(
                symbol: "app.badge",
                title: "CI/CD widgets",
                detail: "Pipeline status on your home screen."
            )
        }
    }

    private var tipJar: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            Text("Not ready for Pro?")
                .font(.headline)
            Text("Buy me a coffee instead.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.sm) {
                    ForEach(ProductID.tips, id: \.self) { id in
                        ProductView(id: id)
                            .productViewStyle(.compact)
                    }
                }
            }
        }
    }

    private var purchaseBar: some View {
        VStack(spacing: Theme.Space.sm) {
            ProductView(id: ProductID.proLifetime)
                .productViewStyle(.large)

            Button("Restore Purchases") {
                Task { try? await AppStore.sync() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text("One-time purchase. Non-consumable.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(Theme.Space.lg)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
