import SwiftUI

public struct Card<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    public init(padding: CGFloat = BloomyTheme.spacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BloomyTheme.palette.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: BloomyTheme.radii.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
}

#if DEBUG
struct Card_Previews: PreviewProvider {
    static var previews: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.sm) {
                BloomyTheme.typography.title.text("Sample Card")
                BloomyTheme.typography.body.text("Helpful description for a card component.")
            }
        }
        .padding()
        .background(BloomyTheme.palette.secondaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
#endif
