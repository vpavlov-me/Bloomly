import SwiftUI

public struct PrimaryButton<Content: View>: View {
    private let action: () -> Void
    private let content: Content
    private let isLoading: Bool
    private let disabled: Bool

    public init(
        isLoading: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Content
    ) {
        self.action = action
        self.content = label()
        self.isLoading = isLoading
        self.disabled = disabled
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                content.opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BabyTrackTheme.spacing.sm)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading || disabled)
    }
}

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, BabyTrackTheme.spacing.md)
            .padding(.vertical, BabyTrackTheme.spacing.sm)
            .background(BabyTrackTheme.palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: BabyTrackTheme.radii.pill, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#if DEBUG
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BabyTrackTheme.spacing.md) {
            PrimaryButton(action: {}) {
                Text("Save")
            }
            PrimaryButton(isLoading: true, action: {}) {
                Text("Loading")
            }
            PrimaryButton(disabled: true, action: {}) {
                Text("Disabled")
            }
        }
        .padding()
        .background(BabyTrackTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
