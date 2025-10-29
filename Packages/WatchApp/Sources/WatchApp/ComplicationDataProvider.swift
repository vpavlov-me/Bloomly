import ClockKit
import Foundation
import Tracking

#if os(watchOS)

/// Helper for providing real complication data from events
public final class ComplicationDataProvider {
    private let store: WatchDataStore

    public init(store: WatchDataStore = .shared) {
        self.store = store
    }

    // MARK: - Data Fetching

    public func getLastFeedTimeAgo() -> String {
        guard let lastFeed = store.lastFeed else {
            return "—"
        }

        let interval = Date().timeIntervalSince(lastFeed.start)
        return formatTimeInterval(interval)
    }

    public func getLastSleepDuration() -> String {
        guard let lastSleep = store.lastSleep,
              let duration = lastSleep.duration else {
            return "—"
        }

        return formatDuration(duration)
    }

    public func getTodayEventsCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return store.recentEvents.filter { event in
            event.start >= today && event.start < tomorrow
        }.count
    }

    public func getTodaySleepTotal() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let totalSleep = store.recentEvents
            .filter { $0.kind == .sleep && $0.start >= today && $0.start < tomorrow }
            .compactMap { $0.duration }
            .reduce(0, +)

        return formatDuration(totalSleep)
    }

    // MARK: - Formatting Helpers

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#endif
