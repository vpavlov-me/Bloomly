import SwiftUI

// MARK: - Minimum Touch Target Size

public extension View {
    /// Ensures the view meets the minimum 44x44pt touch target size requirement
    func minimumTouchTarget() -> some View {
        frame(minWidth: 44, minHeight: 44)
    }

    /// Ensures the view meets the minimum touch target size with custom dimensions
    func minimumTouchTarget(width: CGFloat = 44, height: CGFloat = 44) -> some View {
        frame(minWidth: width, minHeight: height)
    }
}

// MARK: - Dynamic Type Support

public extension View {
    /// Limits Dynamic Type scaling to a specific range
    func limitedDynamicType() -> some View {
        self.dynamicTypeSize(.xSmall ... .xxxLarge)
    }
}

// MARK: - Reduced Motion Support

public extension View {
    /// Conditionally applies animation based on user's reduced motion preference
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if AccessibilitySettings.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }

    /// Conditionally applies transition based on user's reduced motion preference
    @ViewBuilder
    func accessibleTransition(_ transition: AnyTransition) -> some View {
        if AccessibilitySettings.isReduceMotionEnabled {
            self.transition(.identity)
        } else {
            self.transition(transition)
        }
    }
}

// MARK: - Semantic Grouping

public extension View {
    /// Groups related accessibility elements together
    func accessibilityGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .modify { view in
                if let hint = hint {
                    view.accessibilityHint(hint)
                } else {
                    view
                }
            }
    }
}

// MARK: - Custom Actions

public struct AccessibilityCustomAction {
    let name: String
    let action: () -> Bool

    public init(name: String, action: @escaping () -> Bool) {
        self.name = name
        self.action = action
    }
}

// Note: Multiple accessibility actions should be added individually using .accessibilityAction(named:)

// MARK: - Trait Helpers

public extension View {
    /// Marks a view as a button for accessibility
    func accessibilityButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .modify { view in
                if let hint = hint {
                    view.accessibilityHint(hint)
                } else {
                    view
                }
            }
    }

    /// Marks a view as a header for accessibility
    func accessibilityHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - High Contrast Support

public extension View {
    /// Adjusts colors for high contrast mode
    func highContrastAdjusted(color: Color, highContrastColor: Color) -> some View {
        self.foregroundColor(
            AccessibilitySettings.isHighContrastEnabled ? highContrastColor : color
        )
    }
}

// MARK: - Conditional Modifier Helper

public extension View {
    @ViewBuilder
    func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

// MARK: - Accessibility Settings

public struct AccessibilitySettings {
    /// Check if reduce motion is enabled
    public static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Check if voice over is running
    public static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Check if switch control is running
    public static var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }

    /// Check if reduce transparency is enabled
    public static var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    /// Check if increase contrast is enabled
    public static var isHighContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    /// Check if bold text is enabled
    public static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    /// Current content size category
    public static var contentSizeCategory: UIContentSizeCategory {
        UIApplication.shared.preferredContentSizeCategory
    }

    /// Check if using an accessibility content size
    public static var isAccessibilitySizeCategory: Bool {
        contentSizeCategory.isAccessibilityCategory
    }
}

// MARK: - Loading State Accessibility

public extension View {
    /// Announces loading state changes to VoiceOver users
    func accessibleLoadingState(isLoading: Bool, message: String = "Loading") -> some View {
        self.accessibilityElement(children: .contain)
            .accessibilityLabel(isLoading ? message : "")
            .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}
