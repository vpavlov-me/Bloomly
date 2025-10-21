import SwiftUI

public struct SectionHeader: View {
    private let title: String
    private let subtitle: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(title: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                BabyTrackTheme.typography.headline.text(title)
                if let subtitle {
                    BabyTrackTheme.typography.caption.text(subtitle)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(BabyTrackTheme.palette.accent)
            }
        }
        .padding(.horizontal, BabyTrackTheme.spacing.md)
        .padding(.bottom, BabyTrackTheme.spacing.xs)
    }
}

#if DEBUG
struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BabyTrackTheme.spacing.lg) {
            SectionHeader(title: "Today", subtitle: "Tuesday, 12 March")
            SectionHeader(title: "Feedings", actionTitle: "See all", action: {})
        }
        .padding()
        .background(BabyTrackTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
