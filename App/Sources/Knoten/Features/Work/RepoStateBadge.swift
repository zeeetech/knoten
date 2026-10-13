import SwiftUI

/// The state bobbin derives for a pull or an issue, as a small capsule. The
/// palette stays on the two accents the app already uses.
struct RepoStateBadge: View {
    let state: String

    var body: some View {
        Text(state)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private var tint: Color {
        switch state {
        case "open": return Theme.Palette.trust
        case "merged": return Theme.Palette.ide
        default: return .secondary
        }
    }
}
