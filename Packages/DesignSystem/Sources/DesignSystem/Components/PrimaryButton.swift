import SwiftUI

public struct PrimaryButton<Content: View>: View {
    private let action: () -> Void
    private let content: Content
    private let isLoading: Bool
    private let disabled: Bool
    private let accessibilityLabel: String?
    private let accessibilityHint: String?

    public init(
        isLoading: Bool = false,
        disabled: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Content
    ) {
        self.action = action
        self.content = label()
        self.isLoading = isLoading
        self.disabled = disabled
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    public var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                content.opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .accessibilityLabel("Loading")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BloomyTheme.spacing.sm)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading || disabled)
        .minimumTouchTarget()
        .accessibilityElement(children: .combine)
        .modify { view in
            if let label = accessibilityLabel {
                view.accessibilityLabel(label)
            } else {
                view
            }
        }
        .modify { view in
            if let hint = accessibilityHint {
                view.accessibilityHint(hint)
            } else {
                view
            }
        }
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
        .accessibilityRemoveTraits(disabled ? [] : .isButton)
        .accessibilityAddTraits(.isButton)
    }
}

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, BloomyTheme.spacing.md)
            .padding(.vertical, BloomyTheme.spacing.sm)
            .background(BloomyTheme.palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: BloomyTheme.radii.pill, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .accessibleAnimation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#if DEBUG
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BloomyTheme.spacing.md) {
            PrimaryButton {
                // Action
            } label: {
                Text("Save")
            }
            PrimaryButton(isLoading: true) {
                // Action
            } label: {
                Text("Loading")
            }
            PrimaryButton(disabled: true) {
                // Action
            } label: {
                Text("Disabled")
            }
        }
        .padding()
        .background(BloomyTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
