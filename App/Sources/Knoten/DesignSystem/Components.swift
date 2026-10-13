import SwiftUI

struct PROBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.Palette.pro, in: Capsule())
    }
}

struct StatusDot: View {
    var color: Color = Theme.Palette.trust

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

struct BenefitRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Theme.Palette.ide)
                .frame(width: 32, height: 32)
                .background(Theme.Palette.ide.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Greys a preview of a locked feature without pretending the content is
/// missing. Interaction belongs to whatever wraps it.
struct LockedPreview<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .blur(radius: 3)
            .saturation(0.5)
            .opacity(0.55)
    }
}
