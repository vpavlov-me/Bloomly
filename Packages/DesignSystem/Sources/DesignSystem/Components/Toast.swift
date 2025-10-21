import SwiftUI

/// Toast message type
public enum ToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return BabyTrackTheme.palette.success
        case .error: return BabyTrackTheme.palette.destructive
        case .warning: return BabyTrackTheme.palette.warning
        case .info: return BabyTrackTheme.palette.accent
        }
    }
}

/// Toast message model
public struct ToastMessage: Identifiable, Equatable {
    public let id = UUID()
    public let type: ToastType
    public let message: String
    public let duration: TimeInterval

    public init(type: ToastType, message: String, duration: TimeInterval = 3.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }

    public static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// Toast view component
public struct ToastView: View {
    private let toast: ToastMessage

    public init(toast: ToastMessage) {
        self.toast = toast
    }

    public var body: some View {
        HStack(spacing: BabyTrackTheme.spacing.sm) {
            Image(systemName: toast.type.icon)
                .foregroundStyle(toast.type.color)
                .font(.system(size: 20, weight: .semibold))

            Text(toast.message)
                .font(BabyTrackTheme.typography.body.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(BabyTrackTheme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft)
                .fill(BabyTrackTheme.palette.elevatedSurface)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, BabyTrackTheme.spacing.md)
    }
}

/// Toast modifier for presenting toast messages
public struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1000)
                        .padding(.top, BabyTrackTheme.spacing.sm)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                                withAnimation(.easeInOut) {
                                    self.toast = nil
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast != nil)
    }
}

public extension View {
    /// Present toast messages
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BabyTrackTheme.spacing.lg) {
            ToastView(toast: ToastMessage(type: .success, message: "Event saved successfully"))
            ToastView(toast: ToastMessage(type: .error, message: "Failed to delete measurement"))
            ToastView(toast: ToastMessage(type: .warning, message: "Check your internet connection"))
            ToastView(toast: ToastMessage(type: .info, message: "Syncing data..."))
        }
        .padding()
        .background(BabyTrackTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
