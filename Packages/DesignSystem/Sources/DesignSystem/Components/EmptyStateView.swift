import SwiftUI

public struct EmptyStateView: View {
    private let icon: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(icon: String = "face.smiling", title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: BabyTrackTheme.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .padding(BabyTrackTheme.spacing.sm)
                .background(
                    Circle()
                        .fill(BabyTrackTheme.palette.secondaryBackground)
                )
                .accessibilityHidden(true)

            BabyTrackTheme.typography.title.text(title)
                .accessibilityAddTraits(.isHeader)

            BabyTrackTheme.typography.caption.text(message)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(.xSmall ... .xxxLarge)

            if let actionTitle, let action {
                PrimaryButton(
                    accessibilityLabel: actionTitle,
                    accessibilityHint: AccessibilityHints.Button.add,
                    action: action
                ) {
                    Text(actionTitle)
                }
                .frame(maxWidth: 220)
            }
        }
        .padding(BabyTrackTheme.spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(transparentBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.EmptyState.message(title: title, description: message))
        .accessibilityIdentifier(AccessibilityIdentifiers.EmptyState.message)
    }

    private var transparentBackground: some View {
        BabyTrackTheme.palette.background.opacity(0.001)
    }
}

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "No Data",
            message: "Start logging events to see insights.",
            actionTitle: "Add first event",
            action: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
