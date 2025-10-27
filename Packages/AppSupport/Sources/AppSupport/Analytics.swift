import Foundation

/// Represents an analytics event with name and metadata
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let metadata: [String: String]

    public init(name: String, metadata: [String: String] = [:]) {
        self.name = name
        self.metadata = metadata
    }
}

/// Protocol for analytics tracking
/// All implementations must be privacy-first and GDPR compliant
public protocol Analytics: Sendable {
    /// Track an analytics event
    /// - Parameter event: The event to track
    func track(_ event: AnalyticsEvent)
}

// MARK: - Convenience Extensions

public extension Analytics {
    /// Track app lifecycle events
    func trackAppLaunched() {
        track(AnalyticsEvent(type: .appLaunched))
    }

    func trackAppBackgrounded() {
        track(AnalyticsEvent(type: .appBackgrounded))
    }

    func trackAppForegrounded() {
        track(AnalyticsEvent(type: .appForegrounded))
    }

    /// Track screen views
    func trackScreenView(_ screenName: String) {
        track(AnalyticsEvent.screenViewed(screenName))
    }

    /// Track feature usage
    func trackFeatureUsed(_ featureName: String) {
        track(AnalyticsEvent.featureUsed(featureName))
    }

    /// Track errors (anonymized - no PII)
    func trackError(_ error: Error, domain: String = "app") {
        let errorType = String(describing: type(of: error))
        track(AnalyticsEvent.error(errorType, domain: domain))
    }
}
