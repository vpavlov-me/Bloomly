import AppSupport
import Foundation
import os.log

/// Grouped events by day
public struct EventsGroup: Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let title: String
    public let events: [EventDTO]

    public init(date: Date, title: String, events: [EventDTO]) {
        self.id = title
        self.date = date
        self.title = title
        self.events = events
    }
}

/// ViewModel for timeline screen
@MainActor
public final class TimelineViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var eventGroups: [EventsGroup] = []
    @Published public var isLoading: Bool = false
    @Published public var isLoadingMore: Bool = false
    @Published public var error: String?
    @Published public var selectedEvent: EventDTO?
    @Published public var showDeleteConfirmation: Bool = false
    @Published public var eventToDelete: EventDTO?

    // MARK: - Dependencies

    private let repository: EventsRepository
    private let analytics: Analytics
    private let logger = Logger(subsystem: "com.vibecoding.bloomly", category: "Timeline")
    private let calendar: Calendar

    // MARK: - Pagination

    private var currentPage: Int = 0
    private let pageSize: Int = 50
    private var hasMorePages: Bool = true
    private var allLoadedEvents: [EventDTO] = []

    // MARK: - Initialization

    public init(
        repository: EventsRepository,
        analytics: Analytics,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.analytics = analytics
        self.calendar = calendar
    }

    // MARK: - Public Methods

    /// Load initial timeline events
    public func loadTimeline() async {
        guard !isLoading else { return }

        logger.info("Loading timeline")

        isLoading = true
        error = nil
        currentPage = 0
        hasMorePages = true
        allLoadedEvents = []

        do {
            // Load first page
            let events = try await repository.events(in: nil, kind: nil)
            allLoadedEvents = events
            eventGroups = groupEventsByDay(events)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .timelineViewed,
                metadata: ["eventCount": String(events.count)]
            ))

            logger.info("Timeline loaded: \(events.count) events")
            isLoading = false
        } catch {
            logger.error("Failed to load timeline: \(error.localizedDescription)")
            self.error = "Failed to load timeline. Please try again."
            isLoading = false
        }
    }

    /// Load more events (pagination)
    public func loadMore() async {
        guard !isLoadingMore && hasMorePages else { return }

        logger.debug("Loading more events")

        isLoadingMore = true

        // Simulate pagination (in real app, use offset/limit from repository)
        do {
            // For now, we load all at once, so no more pages
            hasMorePages = false
            isLoadingMore = false
        } catch {
            logger.error("Failed to load more: \(error.localizedDescription)")
            isLoadingMore = false
        }
    }

    /// Refresh timeline
    public func refresh() async {
        await loadTimeline()
    }

    /// Show event details
    public func showDetails(for event: EventDTO) {
        logger.debug("Showing details for event: \(event.id)")
        selectedEvent = event

        analytics.track(AnalyticsEvent(
            name: "event_viewed",
            metadata: ["kind": event.kind.rawValue]
        ))
    }

    /// Prepare to delete event
    public func confirmDelete(event: EventDTO) {
        logger.debug("Confirming delete for event: \(event.id)")
        eventToDelete = event
        showDeleteConfirmation = true
    }

    /// Delete event
    public func deleteEvent() async {
        guard let event = eventToDelete else { return }

        logger.info("Deleting event: \(event.id)")

        do {
            try await repository.delete(id: event.id)

            // Remove from local cache
            allLoadedEvents.removeAll { $0.id == event.id }
            eventGroups = groupEventsByDay(allLoadedEvents)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .eventDeleted,
                metadata: ["kind": event.kind.rawValue]
            ))

            logger.info("Event deleted successfully")

            // Reset state
            eventToDelete = nil
            showDeleteConfirmation = false
        } catch {
            logger.error("Failed to delete event: \(error.localizedDescription)")
            self.error = "Failed to delete event. Please try again."
        }
    }

    /// Cancel delete
    public func cancelDelete() {
        eventToDelete = nil
        showDeleteConfirmation = false
    }

    /// Get relative time string
    public func relativeTime(for date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours == 0 {
            if minutes == 0 {
                return "Just now"
            } else if minutes == 1 {
                return "1 minute ago"
            } else {
                return "\(minutes) minutes ago"
            }
        } else if hours == 1 {
            return "1 hour ago"
        } else if hours < 24 {
            return "\(hours) hours ago"
        } else {
            let days = hours / 24
            if days == 1 {
                return "1 day ago"
            } else {
                return "\(days) days ago"
            }
        }
    }

    // MARK: - Private Helpers

    private func groupEventsByDay(_ events: [EventDTO]) -> [EventsGroup] {
        let sortedEvents = events.sorted { $0.start > $1.start }

        var groups: [Date: [EventDTO]] = [:]

        for event in sortedEvents {
            let dayStart = calendar.startOfDay(for: event.start)
            groups[dayStart, default: []].append(event)
        }

        return groups.keys.sorted(by: >).map { date in
            let title = dateGroupTitle(for: date)
            let events = groups[date]!.sorted { $0.start > $1.start }
            return EventsGroup(date: date, title: title, events: events)
        }
    }

    private func dateGroupTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}
