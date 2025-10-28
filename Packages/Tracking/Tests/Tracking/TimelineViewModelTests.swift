import AppSupport
import XCTest
@testable import Tracking

@MainActor
final class TimelineViewModelTests: XCTestCase {
    private var viewModel: TimelineViewModel!
    private var mockRepository: InMemoryEventsRepository!
    private var mockAnalytics: MockAnalytics!

    override func setUp() async throws {
        mockRepository = InMemoryEventsRepository()
        mockAnalytics = MockAnalytics()
        viewModel = TimelineViewModel(
            repository: mockRepository,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockAnalytics = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.eventGroups.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertNil(viewModel.error)
        XCTAssertNil(viewModel.selectedEvent)
        XCTAssertFalse(viewModel.showDeleteConfirmation)
        XCTAssertNil(viewModel.eventToDelete)
    }

    // MARK: - Load Timeline Tests

    func testLoadTimelineSuccess() async {
        // Create test events
        let event1 = EventDTO(kind: .sleep, start: Date())
        let event2 = EventDTO(kind: .feeding, start: Date().addingTimeInterval(-3600))
        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)

        await viewModel.loadTimeline()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.eventGroups.isEmpty)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("timeline.viewed"))
    }

    func testLoadTimelineEmpty() async {
        await viewModel.loadTimeline()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.eventGroups.isEmpty)
    }

    func testLoadTimelineGroupsByDay() async {
        // Create events on different days
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let event1 = EventDTO(kind: .sleep, start: today)
        let event2 = EventDTO(kind: .feeding, start: yesterday)
        let event3 = EventDTO(kind: .diaper, start: twoDaysAgo)

        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)
        _ = try? await mockRepository.create(event3)

        await viewModel.loadTimeline()

        // Should have 3 groups (Today, Yesterday, 2 days ago)
        XCTAssertEqual(viewModel.eventGroups.count, 3)

        // Verify group titles
        XCTAssertTrue(viewModel.eventGroups[0].title == "Today")
        XCTAssertTrue(viewModel.eventGroups[1].title == "Yesterday")
    }

    func testLoadTimelineSortsDescending() async {
        // Create events with different times
        let now = Date()
        let event1 = EventDTO(kind: .sleep, start: now.addingTimeInterval(-7200)) // 2h ago
        let event2 = EventDTO(kind: .feeding, start: now.addingTimeInterval(-3600)) // 1h ago
        let event3 = EventDTO(kind: .diaper, start: now) // now

        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)
        _ = try? await mockRepository.create(event3)

        await viewModel.loadTimeline()

        XCTAssertEqual(viewModel.eventGroups.count, 1)

        let events = viewModel.eventGroups[0].events

        // Should be sorted newest first
        XCTAssertEqual(events[0].id, event3.id)
        XCTAssertEqual(events[1].id, event2.id)
        XCTAssertEqual(events[2].id, event1.id)
    }

    // MARK: - Refresh Tests

    func testRefresh() async {
        let event = EventDTO(kind: .sleep, start: Date())
        _ = try? await mockRepository.create(event)

        await viewModel.loadTimeline()
        XCTAssertEqual(viewModel.eventGroups[0].events.count, 1)

        // Add another event
        let event2 = EventDTO(kind: .feeding, start: Date())
        _ = try? await mockRepository.create(event2)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.eventGroups[0].events.count, 2)
    }

    // MARK: - Show Details Tests

    func testShowDetails() {
        let event = EventDTO(kind: .sleep, start: Date())

        viewModel.showDetails(for: event)

        XCTAssertEqual(viewModel.selectedEvent, event)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("event.viewed"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "event.viewed" }
        XCTAssertEqual(events.first?.metadata["kind"], "sleep")
    }

    // MARK: - Delete Tests

    func testConfirmDelete() {
        let event = EventDTO(kind: .sleep, start: Date())

        viewModel.confirmDelete(event: event)

        XCTAssertEqual(viewModel.eventToDelete, event)
        XCTAssertTrue(viewModel.showDeleteConfirmation)
    }

    func testCancelDelete() {
        let event = EventDTO(kind: .sleep, start: Date())

        viewModel.confirmDelete(event: event)
        XCTAssertTrue(viewModel.showDeleteConfirmation)

        viewModel.cancelDelete()

        XCTAssertNil(viewModel.eventToDelete)
        XCTAssertFalse(viewModel.showDeleteConfirmation)
    }

    func testDeleteEvent() async {
        // Create event
        let event = EventDTO(kind: .sleep, start: Date())
        _ = try? await mockRepository.create(event)

        await viewModel.loadTimeline()
        XCTAssertEqual(viewModel.eventGroups[0].events.count, 1)

        // Delete
        viewModel.eventToDelete = event
        await viewModel.deleteEvent()

        // Verify deleted
        XCTAssertTrue(viewModel.eventGroups.isEmpty)
        XCTAssertNil(viewModel.eventToDelete)
        XCTAssertFalse(viewModel.showDeleteConfirmation)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("event.deleted"))
    }

    func testDeleteEventUpdatesGroups() async {
        // Create multiple events
        let event1 = EventDTO(kind: .sleep, start: Date())
        let event2 = EventDTO(kind: .feeding, start: Date())
        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)

        await viewModel.loadTimeline()
        XCTAssertEqual(viewModel.eventGroups[0].events.count, 2)

        // Delete one
        viewModel.eventToDelete = event1
        await viewModel.deleteEvent()

        // Should still have 1 event
        XCTAssertEqual(viewModel.eventGroups[0].events.count, 1)
        XCTAssertEqual(viewModel.eventGroups[0].events[0].id, event2.id)
    }

    // MARK: - Relative Time Tests

    func testRelativeTimeJustNow() {
        let now = Date()
        let result = viewModel.relativeTime(for: now)
        XCTAssertEqual(result, "Just now")
    }

    func testRelativeTimeMinutes() {
        let date = Date().addingTimeInterval(-300) // 5 minutes ago
        let result = viewModel.relativeTime(for: date)
        XCTAssertEqual(result, "5 minutes ago")
    }

    func testRelativeTimeOneMinute() {
        let date = Date().addingTimeInterval(-60) // 1 minute ago
        let result = viewModel.relativeTime(for: date)
        XCTAssertEqual(result, "1 minute ago")
    }

    func testRelativeTimeHours() {
        let date = Date().addingTimeInterval(-7200) // 2 hours ago
        let result = viewModel.relativeTime(for: date)
        XCTAssertEqual(result, "2 hours ago")
    }

    func testRelativeTimeOneHour() {
        let date = Date().addingTimeInterval(-3600) // 1 hour ago
        let result = viewModel.relativeTime(for: date)
        XCTAssertEqual(result, "1 hour ago")
    }

    func testRelativeTimeDays() {
        let date = Date().addingTimeInterval(-172800) // 2 days ago
        let result = viewModel.relativeTime(for: date)
        XCTAssertEqual(result, "2 days ago")
    }

    func testRelativeTimeOneDay() {
        let date = Date().addingTimeInterval(-86400) // 1 day ago
        let result = viewModel.relativeTime(for: date)
        XCTAssertEqual(result, "1 day ago")
    }

    // MARK: - Events Group Tests

    func testEventsGroupEquatable() {
        let events1 = [EventDTO(kind: .sleep, start: Date())]
        let events2 = [EventDTO(kind: .sleep, start: Date())]

        let group1 = EventsGroup(date: Date(), title: "Today", events: events1)
        let group2 = EventsGroup(date: Date(), title: "Today", events: events1)

        XCTAssertEqual(group1, group2)
    }

    func testEventsGroupIdentifiable() {
        let group = EventsGroup(date: Date(), title: "Today", events: [])
        XCTAssertEqual(group.id, "Today")
    }

    // MARK: - Multiple Events Same Day Tests

    func testMultipleEventsOnSameDay() async {
        let now = Date()
        let event1 = EventDTO(kind: .sleep, start: now.addingTimeInterval(-3600))
        let event2 = EventDTO(kind: .feeding, start: now.addingTimeInterval(-1800))
        let event3 = EventDTO(kind: .diaper, start: now)

        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)
        _ = try? await mockRepository.create(event3)

        await viewModel.loadTimeline()

        // Should have 1 group with 3 events
        XCTAssertEqual(viewModel.eventGroups.count, 1)
        XCTAssertEqual(viewModel.eventGroups[0].events.count, 3)
        XCTAssertEqual(viewModel.eventGroups[0].title, "Today")
    }

    // MARK: - Analytics Tests

    func testAnalyticsTracksLoad() async {
        await viewModel.loadTimeline()

        XCTAssertTrue(mockAnalytics.wasTracked("timeline.viewed"))
    }

    func testAnalyticsTracksDelete() async {
        let event = EventDTO(kind: .sleep, start: Date())
        _ = try? await mockRepository.create(event)

        viewModel.eventToDelete = event
        await viewModel.deleteEvent()

        XCTAssertTrue(mockAnalytics.wasTracked("event.deleted"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "event.deleted" }
        XCTAssertEqual(events.first?.metadata["kind"], "sleep")
    }
}
