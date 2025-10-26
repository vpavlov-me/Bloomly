import Combine
import Foundation

/// ViewModel for the Dashboard screen.
///
/// Responsibilities:
/// - Fetch and display today's summary statistics
/// - Track active events (ongoing sleep/feeding)
/// - Provide "time since last" information for each event type
/// - Manage loading and error states
/// - Handle quick action taps
@MainActor
public final class DashboardViewModel: ObservableObject {
    // MARK: - Published State

    /// Loading state for the dashboard
    @Published public private(set) var isLoading = false

    /// Error message if loading fails
    @Published public private(set) var errorMessage: String?

    /// Active/ongoing events (sleep, feeding)
    @Published public private(set) var activeEvents: [EventDTO] = []

    /// Today's summary statistics
    @Published public private(set) var todayStats: DashboardStats?

    /// Time since last event for each type
    @Published public private(set) var lastEventTimes: [EventKind: Date] = [:]

    // MARK: - Dependencies

    private let eventsRepository: any EventsRepository
    private let calendar: Calendar
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    // MARK: - Initialization

    public init(
        eventsRepository: any EventsRepository,
        calendar: Calendar = .current
    ) {
        self.eventsRepository = eventsRepository
        self.calendar = calendar

        setupRefreshTimer()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - Public API

    /// Loads dashboard data (today's stats, active events, last event times)
    public func load() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch today's events
            let todayInterval = calendar.dateInterval(of: .day, for: Date())!
            let todayEvents = try await eventsRepository.events(in: todayInterval, kind: nil)

            // Calculate stats
            todayStats = calculateStats(from: todayEvents)

            // Find active events
            activeEvents = todayEvents.filter { $0.isOngoing }

            // Get last event time for each kind
            for kind in EventKind.allCases {
                if let lastEvent = try await eventsRepository.lastEvent(for: kind) {
                    lastEventTimes[kind] = lastEvent.start
                }
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Refreshes dashboard data
    public func refresh() async {
        await load()
    }

    /// Returns the active event for a specific kind, if any
    public func activeEvent(for kind: EventKind) -> EventDTO? {
        activeEvents.first { $0.kind == kind }
    }

    /// Returns time since last event for a specific kind
    public func timeSinceLastEvent(for kind: EventKind) -> TimeInterval? {
        guard let lastTime = lastEventTimes[kind] else { return nil }
        return Date().timeIntervalSince(lastTime)
    }

    // MARK: - Private Methods

    private func setupRefreshTimer() {
        // Refresh every minute to update "time since" displays
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    private func calculateStats(from events: [EventDTO]) -> DashboardStats {
        var sleepCount = 0
        var sleepDuration: TimeInterval = 0
        var feedingCount = 0
        var feedingDuration: TimeInterval = 0
        var diaperCount = 0
        var pumpingCount = 0

        for event in events {
            switch event.kind {
            case .sleep:
                sleepCount += 1
                sleepDuration += event.duration
            case .feed:
                feedingCount += 1
                feedingDuration += event.duration
            case .diaper:
                diaperCount += 1
            case .pumping:
                pumpingCount += 1
            }
        }

        return DashboardStats(
            sleepCount: sleepCount,
            totalSleepDuration: sleepDuration,
            feedingCount: feedingCount,
            totalFeedingDuration: feedingDuration,
            diaperCount: diaperCount,
            pumpingCount: pumpingCount
        )
    }
}

// MARK: - Supporting Types

/// Statistics for today's activity
public struct DashboardStats: Equatable, Sendable {
    public let sleepCount: Int
    public let totalSleepDuration: TimeInterval
    public let feedingCount: Int
    public let totalFeedingDuration: TimeInterval
    public let diaperCount: Int
    public let pumpingCount: Int

    public init(
        sleepCount: Int,
        totalSleepDuration: TimeInterval,
        feedingCount: Int,
        totalFeedingDuration: TimeInterval,
        diaperCount: Int,
        pumpingCount: Int
    ) {
        self.sleepCount = sleepCount
        self.totalSleepDuration = totalSleepDuration
        self.feedingCount = feedingCount
        self.totalFeedingDuration = totalFeedingDuration
        self.diaperCount = diaperCount
        self.pumpingCount = pumpingCount
    }
}
