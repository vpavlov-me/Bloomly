import SwiftUI

public enum BloomyTheme {
    public static let palette = Palette()
    public static let typography = Typography()
    public static let spacing = Spacing()
    public static let radii = Radii()
    public static let animation = Animation()

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

public extension BloomyTheme {
    struct Palette {
        // Base colors
        public let background = Color(.systemBackground)
        public let secondaryBackground = Color(.secondarySystemBackground)
        public let tertiaryBackground = Color(.tertiarySystemBackground)
        public let elevatedSurface = Color.dynamic(
            light: UIColor.white,
            dark: UIColor.secondarySystemBackground
        )
        public let accent = Color.dynamic(
            light: UIColor(red: 0.99, green: 0.52, blue: 0.57, alpha: 1),
            dark: UIColor(red: 0.98, green: 0.44, blue: 0.48, alpha: 1)
        )
        public let accentContrast = Color.white
        public let success = Color(.systemGreen)
        public let warning = Color(.systemOrange)
        public let destructive = Color(.systemRed)
        public let outline = Color.dynamic(
            light: UIColor.systemGray4,
            dark: UIColor.systemGray5
        )
        public let mutedText = Color(.secondaryLabel)
        public let primaryText = Color(.label)

        // Event-specific colors
        /// Soft blue for sleep events
        public let sleep = Color(hex: "#667BC6")
        /// Warm pink for feeding events
        public let feeding = Color(hex: "#DA7297")
        /// Soft yellow for diaper events
        public let diaper = Color(hex: "#FFDC7F")
        /// Light blue for pumping events
        public let pumping = Color(hex: "#7BA8E5")
        /// Purple for measurement events
        public let measurement = Color(hex: "#9B85C9")
        /// Green for medication events
        public let medication = Color(hex: "#82C997")
        /// Gray for note events
        public let note = Color(hex: "#95A5A6")

        #if canImport(UIKit)
        fileprivate let accentLight = UIColor(red: 0.99, green: 0.52, blue: 0.57, alpha: 1)
        fileprivate let accentDark = UIColor(red: 0.98, green: 0.44, blue: 0.48, alpha: 1)
        #endif
    }

    struct Typography {
        public let largeTitle = TextStyle(
            font: .system(.largeTitle, design: .rounded).weight(.bold),
            color: BloomyTheme.palette.primaryText
        )
        public let title = TextStyle(
            font: .system(.title2, design: .rounded).weight(.semibold),
            color: BloomyTheme.palette.primaryText
        )
        public let title3 = TextStyle(
            font: .system(.title3, design: .rounded).weight(.semibold),
            color: BloomyTheme.palette.primaryText
        )
        public let headline = TextStyle(
            font: .system(.headline, design: .rounded),
            color: BloomyTheme.palette.primaryText
        )
        public let body = TextStyle(
            font: .system(.body, design: .rounded),
            color: BloomyTheme.palette.primaryText
        )
        public let callout = TextStyle(
            font: .system(.callout, design: .rounded),
            color: BloomyTheme.palette.primaryText
        )
        public let footnote = TextStyle(
            font: .system(.footnote, design: .rounded),
            color: BloomyTheme.palette.mutedText
        )
        public let caption = TextStyle(
            font: .system(.caption, design: .rounded),
            color: BloomyTheme.palette.mutedText
        )
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

    struct Animation {
        /// Fast animation for micro-interactions (0.2s)
        public let fast: SwiftUI.Animation = .easeInOut(duration: 0.2)
        /// Standard animation for most UI changes (0.3s)
        public let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)
        /// Slow animation for larger transitions (0.4s)
        public let slow: SwiftUI.Animation = .easeInOut(duration: 0.4)
        /// Spring animation for bouncy effects
        public let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.7)
        /// Smooth animation for smooth transitions
        public let smooth: SwiftUI.Animation = .smooth(duration: 0.3)
    }
}

public extension BloomyTheme.Typography {
    struct TextStyle {
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
}

private extension Color {
    /// Initialize Color from hex string (e.g., "#667BC6")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let red, green, blue: UInt64
        switch hex.count {
        case 6:  // RGB (24-bit)
            (red, green, blue) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (red, green, blue) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }

    #if canImport(UIKit)
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
    #else
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.name == .darkAqua ? dark : light
        })
    }
    #endif
}

#if DEBUG
struct BloomyTheme_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Typography preview
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.largeTitle.text("Large Title")
                BloomyTheme.typography.title.text("Title")
                BloomyTheme.typography.body.text("Body")
                BloomyTheme.typography.caption.text("Caption")
            }
            .padding(BloomyTheme.spacing.lg)
            .background(BloomyTheme.palette.background)

            // Base colors preview
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                RoundedRectangle(cornerRadius: BloomyTheme.radii.card)
                    .fill(BloomyTheme.palette.accent)
                    .frame(height: 60)
                    .overlay(
                        Text("Accent").foregroundStyle(.white).font(.headline)
                    )
                RoundedRectangle(cornerRadius: BloomyTheme.radii.card)
                    .fill(BloomyTheme.palette.elevatedSurface)
                    .frame(height: 60)
                    .overlay(
                        Text("Elevated")
                            .foregroundStyle(BloomyTheme.palette.primaryText)
                            .font(.headline)
                    )
            }
            .padding(BloomyTheme.spacing.lg)
            .background(BloomyTheme.palette.secondaryBackground)

            // Event colors preview
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.sm) {
                Text("Event Colors").font(.headline)
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: BloomyTheme.spacing.sm
                ) {
                    EventColorCard(
                        title: "Sleep",
                        color: BloomyTheme.palette.sleep,
                        icon: "moon.fill"
                    )
                    EventColorCard(
                        title: "Feeding",
                        color: BloomyTheme.palette.feeding,
                        icon: "bottle.fill"
                    )
                    EventColorCard(
                        title: "Diaper",
                        color: BloomyTheme.palette.diaper,
                        icon: "sparkles"
                    )
                    EventColorCard(
                        title: "Pumping",
                        color: BloomyTheme.palette.pumping,
                        icon: "drop.fill"
                    )
                    EventColorCard(
                        title: "Measurement",
                        color: BloomyTheme.palette.measurement,
                        icon: "ruler"
                    )
                    EventColorCard(
                        title: "Medication",
                        color: BloomyTheme.palette.medication,
                        icon: "pills"
                    )
                }
            }
            .padding(BloomyTheme.spacing.lg)
            .background(BloomyTheme.palette.background)
        }
        .previewLayout(.sizeThatFits)
    }

    private struct EventColorCard: View {
        let title: String
        let color: Color
        let icon: String

        var body: some View {
            VStack(spacing: BloomyTheme.spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(BloomyTheme.spacing.md)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: BloomyTheme.radii.soft))
        }
    }
}
#endif
