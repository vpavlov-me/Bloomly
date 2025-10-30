import Foundation
import TelemetryDeck
import os.log

/// TelemetryDeck implementation of Analytics protocol
/// Privacy-first analytics with GDPR compliance
public final class TelemetryDeckAnalytics: Analytics, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vibecoding.bloomly", category: "Analytics")
    private var isEnabled: Bool
    private let userDefaults: UserDefaults
    private let analyticsEnabledKey = "AnalyticsEnabled"

    /// Initialize TelemetryDeck analytics
    /// - Parameters:
    ///   - appID: TelemetryDeck app ID
    ///   - userDefaults: UserDefaults for storing opt-out preference
    public init(appID: String, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Check if user has opted out (default: enabled)
        if userDefaults.object(forKey: analyticsEnabledKey) == nil {
            userDefaults.set(true, forKey: analyticsEnabledKey)
        }
        self.isEnabled = userDefaults.bool(forKey: analyticsEnabledKey)

        // Initialize TelemetryDeck
        let configuration = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: configuration)

        logger.info("TelemetryDeck initialized (enabled: \(self.isEnabled))")
    }

    /// Track an analytics event
    /// - Parameter event: The event to track
    public func track(_ event: AnalyticsEvent) {
        guard isEnabled else {
            logger.debug("Analytics disabled, skipping event: \(event.name)")
            return
        }

        // Send to TelemetryDeck with metadata
        TelemetryDeck.signal(
            event.name,
            parameters: event.metadata
        )

        logger.debug("Tracked event: \(event.name) with metadata: \(event.metadata.description)")
    }

    /// Enable analytics tracking
    public func enable() {
        isEnabled = true
        userDefaults.set(true, forKey: analyticsEnabledKey)
        logger.info("Analytics enabled")

        // Track opt-in event
        track(AnalyticsEvent(type: .analyticsOptedIn))
    }

    /// Disable analytics tracking (user opt-out)
    public func disable() {
        // Track opt-out event before disabling
        track(AnalyticsEvent(type: .analyticsOptedOut))

        isEnabled = false
        userDefaults.set(false, forKey: analyticsEnabledKey)
        logger.info("Analytics disabled")
    }

    /// Check if analytics is currently enabled
    public var enabled: Bool {
        isEnabled
    }
}
