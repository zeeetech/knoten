import SwiftUI

enum Theme {
    enum Palette {
        static let canvas = Color(.systemGroupedBackground)
        static let surface = Color(.secondarySystemGroupedBackground)
        static let surfaceHigh = Color(.tertiarySystemGroupedBackground)
        static let separator = Color(.separator)

        static let ide = Color(light: 0x007ACC, dark: 0x3B9EFF)
        static let trust = Color(light: 0x0B7A4B, dark: 0x30D158)

        static let pro = LinearGradient(
            colors: [ide, trust],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Radius {
        static let card: CGFloat = 12
        static let inner: CGFloat = 8
        static let sheet: CGFloat = 28
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 32
    }
}

extension Font {
    /// Hostnames, DIDs, handles, SHAs: anything the eye should scan, not read.
    static func identifier(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .monospaced)
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
