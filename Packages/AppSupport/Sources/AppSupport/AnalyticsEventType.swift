import Foundation

/// Predefined analytics event types for the app
public enum AnalyticsEventType: String, Sendable {
    // MARK: - App Lifecycle
    case appLaunched = "app.launched"
    case appBackgrounded = "app.backgrounded"
    case appForegrounded = "app.foregrounded"
    case appTerminated = "app.terminated"

    // MARK: - Feature Usage
    case featureUsed = "feature.used"
    case sleepTrackingStarted = "tracking.sleep.started"
    case sleepTrackingStopped = "tracking.sleep.stopped"
    case feedingTracked = "tracking.feeding.tracked"
    case diaperTracked = "tracking.diaper.tracked"
    case pumpingTracked = "tracking.pumping.tracked"

    // MARK: - Screen Views
    case screenViewed = "screen.viewed"
    case dashboardViewed = "screen.dashboard.viewed"
    case timelineViewed = "screen.timeline.viewed"
    case chartsViewed = "screen.charts.viewed"
    case settingsViewed = "screen.settings.viewed"
    case babyProfileViewed = "screen.babyProfile.viewed"

    // MARK: - User Actions
    case eventCreated = "event.created"
    case eventUpdated = "event.updated"
    case eventDeleted = "event.deleted"
    case babyProfileCreated = "baby.created"
    case babyProfileUpdated = "baby.updated"
    case photoAdded = "baby.photo.added"

    // MARK: - Errors (anonymized)
    case errorOccurred = "error.occurred"
    case syncFailed = "sync.failed"
    case dataLoadFailed = "data.loadFailed"

    // MARK: - Settings
    case analyticsOptedOut = "settings.analytics.optedOut"
    case analyticsOptedIn = "settings.analytics.optedIn"
    case notificationsEnabled = "settings.notifications.enabled"
    case notificationsDisabled = "settings.notifications.disabled"

    // MARK: - Onboarding
    case onboardingStarted = "onboarding.started"
    case onboardingCompleted = "onboarding.completed"
    case onboardingSkipped = "onboarding.skipped"

    // MARK: - Apple Watch
    case watchAppOpened = "watch.app.opened"
    case watchEventLogged = "watch.event.logged"
    case watchQuickActionUsed = "watch.quickAction.used"
    case watchComplicationTapped = "watch.complication.tapped"
    case watchSyncCompleted = "watch.sync.completed"
}

public extension AnalyticsEvent {
    /// Create an event from a predefined type
    init(type: AnalyticsEventType, metadata: [String: String] = [:]) {
        self.init(name: type.rawValue, metadata: metadata)
    }

    /// Create an event for feature usage
    static func featureUsed(_ featureName: String) -> AnalyticsEvent {
        AnalyticsEvent(
            type: .featureUsed,
            metadata: ["feature": featureName]
        )
    }

    /// Create an event for screen view
    static func screenViewed(_ screenName: String) -> AnalyticsEvent {
        AnalyticsEvent(
            type: .screenViewed,
            metadata: ["screen": screenName]
        )
    }

    /// Create an event for error (anonymized)
    static func error(_ errorType: String, domain: String) -> AnalyticsEvent {
        AnalyticsEvent(
            type: .errorOccurred,
            metadata: [
                "errorType": errorType,
                "domain": domain
            ]
        )
    }

    /// Create an event for event tracking
    static func eventTracked(kind: String) -> AnalyticsEvent {
        AnalyticsEvent(
            type: .eventCreated,
            metadata: ["eventKind": kind]
        )
    }
}
