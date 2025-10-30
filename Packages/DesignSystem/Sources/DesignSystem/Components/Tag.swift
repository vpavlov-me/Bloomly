import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct Tag: View {
    private let title: String
    private let color: Color
    private let icon: String?

    public init(
        title: String,
        color: Color = BloomyTheme.palette.accent,
        icon: String? = nil
    ) {
        self.title = title
        self.color = color
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: BloomyTheme.spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, BloomyTheme.spacing.sm)
        .padding(.vertical, BloomyTheme.spacing.xs)
        .foregroundStyle(color.accessibleTextColor)
        .background(color)
        .clipShape(Capsule())
    }
}

private extension Color {
    var accessibleTextColor: Color {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.6 ? .black : .white
        #elseif canImport(AppKit)
        guard let converted = NSColor(self).usingColorSpace(.deviceRGB) else {
            return .white
        }
        let redComponent = converted.redComponent
        let greenComponent = converted.greenComponent
        let blueComponent = converted.blueComponent
        let luminance = 0.299 * redComponent + 0.587 * greenComponent + 0.114 * blueComponent
        return luminance > 0.6 ? .black : .white
        #else
        return .white
        #endif
    }
}

#if DEBUG
struct Tag_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BloomyTheme.spacing.sm) {
            Tag(title: "Sleep", icon: "moon.fill")
            Tag(title: "Feeding", color: .blue, icon: "bottle.fill")
            Tag(title: "Diaper", color: .green)
        }
        .padding()
        .background(BloomyTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
