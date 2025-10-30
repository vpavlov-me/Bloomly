import Content
import SwiftUI

/// User-friendly error presentation view
public struct ErrorView: View {
    private let error: AppError
    private let onRetry: (() -> Void)?
    private let onDismiss: (() -> Void)?

    public init(
        error: AppError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: BloomyTheme.spacing.lg) {
            // Error Icon
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            // Error Title
            Text(error.errorDescription ?? "Error")
                .font(BloomyTheme.typography.title.font)
                .foregroundStyle(BloomyTheme.palette.primaryText)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            // Error Details
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(BloomyTheme.typography.body.font)
                    .foregroundStyle(BloomyTheme.palette.mutedText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action Buttons
            VStack(spacing: BloomyTheme.spacing.sm) {
                if let onRetry = onRetry, error.isRetryable {
                    PrimaryButton(
                        accessibilityLabel: String(localized: "common.tryAgain"),
                        accessibilityHint: "Double tap to try again",
                        action: onRetry
                    ) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                    }
                }

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(BloomyTheme.palette.mutedText)
                    }
                    .minimumTouchTarget()
                }
            }
        }
        .padding(BloomyTheme.spacing.xl)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: BloomyTheme.radii.card)
                .fill(BloomyTheme.palette.elevatedSurface)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
        .padding(BloomyTheme.spacing.md)
    }

    private var iconName: String {
        switch error {
        case .networkUnavailable:
            return "wifi.slash"
        case .permissionDenied, .notificationPermissionDenied:
            return "hand.raised.fill"
        case .storageFailure, .dataCorruption:
            return "externaldrive.badge.exclamationmark"
        case .lowStorage:
            return "externaldrive.fill"
        case .purchaseFailed, .productNotFound:
            return "creditcard.fill"
        case .syncConflict, .cloudKitFailure:
            return "icloud.slash"
        case .validationError, .invalidInput:
            return "exclamationmark.triangle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch error.severity {
        case .critical:
            return BloomyTheme.palette.destructive
        case .error:
            return BloomyTheme.palette.warning
        case .warning:
            return BloomyTheme.palette.warning
        case .info:
            return BloomyTheme.palette.accent
        }
    }
}

// MARK: - Error Alert Modifier

public extension View {
    /// Present an error as an alert
    func errorAlert(error: Binding<AppError?>, onRetry: (() -> Void)? = nil) -> some View {
        alert(
            error.wrappedValue?.errorDescription ?? "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { presentedError in
            if let onRetry = onRetry, presentedError.isRetryable {
                Button(AppCopy.Common.tryAgain, action: onRetry)
            }
            Button(AppCopy.Common.ok, role: .cancel) {
                error.wrappedValue = nil
            }
        } message: { presentedError in
            if let suggestion = presentedError.recoverySuggestion {
                Text(suggestion)
            }
        }
    }

    /// Present an error as a full-screen sheet
    func errorSheet(error: Binding<AppError?>, onRetry: (() -> Void)? = nil) -> some View {
        sheet(
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            )
        ) {
            if let presentedError = error.wrappedValue {
                ErrorView(
                    error: presentedError,
                    onRetry: onRetry,
                    onDismiss: { error.wrappedValue = nil }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Inline Error View

public struct InlineErrorView: View {
    private let error: AppError

    public init(error: AppError) {
        self.error = error
    }

    public var body: some View {
        HStack(spacing: BloomyTheme.spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(BloomyTheme.palette.destructive)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.errorDescription ?? "Error")
                    .font(BloomyTheme.typography.callout.font)
                    .foregroundStyle(BloomyTheme.palette.primaryText)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(BloomyTheme.typography.caption.font)
                        .foregroundStyle(BloomyTheme.palette.mutedText)
                }
            }

            Spacer()
        }
        .padding(BloomyTheme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BloomyTheme.radii.soft)
                .fill(BloomyTheme.palette.destructive.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(error.errorDescription ?? "Error"). \(error.recoverySuggestion ?? "")")
    }
}

// MARK: - Loading State with Error

public struct LoadingStateView<Content: View>: View {
    private let state: LoadingState
    private let content: () -> Content
    private let onRetry: (() -> Void)?

    public init(
        state: LoadingState,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.content = content
        self.onRetry = onRetry
    }

    public var body: some View {
        switch state {
        case .idle:
            EmptyView()

        case .loading:
            VStack(spacing: BloomyTheme.spacing.md) {
                ProgressView()
                    .accessibilityLabel("Loading")
                Text(AppCopy.Common.loading)
                    .font(BloomyTheme.typography.caption.font)
                    .foregroundStyle(BloomyTheme.palette.mutedText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            content()

        case .error(let error):
            ErrorView(error: error, onRetry: onRetry)
        }
    }
}

public enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(AppError)

    public static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.id == rhsError.id
        default:
            return false
        }
    }
}

// MARK: - Previews

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(
                error: .networkUnavailable,
                onRetry: {},
                onDismiss: {}
            )
            .previewDisplayName("Network Error")

            ErrorView(
                error: .storageFailure(underlying: NSError(domain: "", code: 0)),
                onRetry: {},
                onDismiss: {}
            )
            .previewDisplayName("Storage Error")

            InlineErrorView(
                error: .validationError(field: "email", reason: "Invalid format")
            )
            .padding()
            .previewDisplayName("Inline Error")

            LoadingStateView(
                state: .error(.purchaseFailed(reason: "Payment method declined")),
                onRetry: {}
            ) {
                Text("Content")
            }
            .previewDisplayName("Loading State Error")
        }
    }
}
#endif
