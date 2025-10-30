import Foundation

/// Mock analytics implementation for testing and preview
public final class MockAnalytics: Analytics, @unchecked Sendable {
    public private(set) var trackedEvents: [AnalyticsEvent] = []
    private let lock = NSLock()

    public init() {}

    public func track(_ event: AnalyticsEvent) {
        lock.lock()
        defer { lock.unlock() }
        trackedEvents.append(event)
    }

    /// Clear all tracked events (useful for tests)
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        trackedEvents.removeAll()
    }

    /// Check if a specific event was tracked
    public func wasTracked(_ eventName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return trackedEvents.contains { $0.name == eventName }
    }

    /// Count how many times an event was tracked
    public func count(for eventName: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return trackedEvents.filter { $0.name == eventName }.count
    }
}
