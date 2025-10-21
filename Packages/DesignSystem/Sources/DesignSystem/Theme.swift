import SwiftUI

public enum BabyTrackTheme {
    public static let palette = Palette()
    public static let typography = Typography()
    public static let spacing = Spacing()
    public static let radii = Radii()

    /// Call at app launch to configure global UIKit / AppKit appearance.
    public static func configureAppearance() {
        #if canImport(UIKit)
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? palette.accentDark : palette.accentLight
        }
        #endif
    }
}

public extension BabyTrackTheme {
    struct Palette {
        public let background = Color(.systemBackground)
        public let secondaryBackground = Color(.secondarySystemBackground)
        public let tertiaryBackground = Color(.tertiarySystemBackground)
        public let elevatedSurface = Color.dynamic(light: UIColor.white, dark: UIColor.secondarySystemBackground)
        public let accent = Color.dynamic(light: UIColor(red: 0.99, green: 0.52, blue: 0.57, alpha: 1),
                                          dark: UIColor(red: 0.98, green: 0.44, blue: 0.48, alpha: 1))
        public let success = Color(.systemGreen)
        public let warning = Color(.systemOrange)
        public let destructive = Color(.systemRed)
        public let outline = Color.dynamic(light: UIColor.systemGray4, dark: UIColor.systemGray5)
        public let mutedText = Color(.secondaryLabel)
        public let primaryText = Color(.label)

        #if canImport(UIKit)
        fileprivate let accentLight = UIColor(red: 0.99, green: 0.52, blue: 0.57, alpha: 1)
        fileprivate let accentDark = UIColor(red: 0.98, green: 0.44, blue: 0.48, alpha: 1)
        #endif
    }

    struct Typography {
        public struct TextStyle {
            public let font: Font
            public let color: Color

            public init(font: Font, color: Color) {
                self.font = font
                self.color = color
            }

            public func text(_ value: String) -> some View {
                Text(value)
                    .font(font)
                    .foregroundStyle(color)
            }
        }

        public let largeTitle = TextStyle(font: .system(.largeTitle, design: .rounded).weight(.bold),
                                          color: BabyTrackTheme.palette.primaryText)
        public let title = TextStyle(font: .system(.title2, design: .rounded).weight(.semibold),
                                     color: BabyTrackTheme.palette.primaryText)
        public let headline = TextStyle(font: .system(.headline, design: .rounded),
                                        color: BabyTrackTheme.palette.primaryText)
        public let body = TextStyle(font: .system(.body, design: .rounded),
                                    color: BabyTrackTheme.palette.primaryText)
        public let callout = TextStyle(font: .system(.callout, design: .rounded),
                                       color: BabyTrackTheme.palette.primaryText)
        public let footnote = TextStyle(font: .system(.footnote, design: .rounded),
                                        color: BabyTrackTheme.palette.mutedText)
        public let caption = TextStyle(font: .system(.caption, design: .rounded),
                                       color: BabyTrackTheme.palette.mutedText)
    }

    struct Spacing {
        public let xxs: CGFloat = 4
        public let xs: CGFloat = 8
        public let sm: CGFloat = 12
        public let md: CGFloat = 16
        public let lg: CGFloat = 24
        public let xl: CGFloat = 32
    }

    struct Radii {
        public let pill: CGFloat = 20
        public let soft: CGFloat = 12
        public let card: CGFloat = 18
    }
}

private extension Color {
    #if canImport(UIKit)
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
    #else
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil, dynamicProvider: { appearance in
            appearance.name == .darkAqua ? dark : light
        }))
    }
    #endif
}

#if DEBUG
struct BabyTrackTheme_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.md) {
                BabyTrackTheme.typography.largeTitle.text("Large Title")
                BabyTrackTheme.typography.title.text("Title")
                BabyTrackTheme.typography.body.text("Body")
                BabyTrackTheme.typography.caption.text("Caption")
            }
            .padding(BabyTrackTheme.spacing.lg)
            .background(BabyTrackTheme.palette.background)

            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.md) {
                RoundedRectangle(cornerRadius: BabyTrackTheme.radii.card)
                    .fill(BabyTrackTheme.palette.accent)
                    .frame(height: 80)
                RoundedRectangle(cornerRadius: BabyTrackTheme.radii.card)
                    .fill(BabyTrackTheme.palette.elevatedSurface)
                    .frame(height: 80)
            }
            .padding(BabyTrackTheme.spacing.lg)
            .background(BabyTrackTheme.palette.secondaryBackground)
        }
        .previewLayout(.fixed(width: 320, height: 240))
    }
}
#endif
