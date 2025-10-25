import Foundation
import SwiftUI

/// Manages onboarding state and flow
@MainActor
public final class OnboardingManager: ObservableObject {
    public static let shared = OnboardingManager()

    @Published public private(set) var hasCompletedOnboarding: Bool
    @Published public private(set) var currentStep: OnboardingStep = .welcome

    private let defaults = UserDefaults.standard
    private let onboardingKey = "app.onboarding.completed"

    private init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)
    }

    // MARK: - Public Methods

    /// Check if user needs to see onboarding
    public var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// Mark onboarding as completed
    public func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: onboardingKey)
    }

    /// Reset onboarding (for testing)
    public func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .welcome
        defaults.removeObject(forKey: onboardingKey)
    }

    /// Move to next step
    public func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .createProfile
        case .createProfile:
            currentStep = .notifications
        case .notifications:
            currentStep = .dashboardIntro
        case .dashboardIntro:
            completeOnboarding()
        }
    }

    /// Skip onboarding
    public func skipOnboarding() {
        completeOnboarding()
    }
}

// MARK: - Onboarding Steps

public enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case createProfile = 1
    case notifications = 2
    case dashboardIntro = 3

    public var title: String {
        switch self {
        case .welcome:
            return "onboarding.welcome.title"
        case .createProfile:
            return "onboarding.profile.title"
        case .notifications:
            return "onboarding.notifications.title"
        case .dashboardIntro:
            return "onboarding.intro.title"
        }
    }

    public var canSkip: Bool {
        switch self {
        case .welcome, .createProfile:
            return false
        case .notifications, .dashboardIntro:
            return true
        }
    }
}
