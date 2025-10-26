import XCTest
import Tracking
import Measurements
@testable import Timeline

@MainActor
final class TimelineViewModelTests: XCTestCase {
    private var eventsRepo: MockEventsRepository!
    private var measurementsRepo: MockMeasurementsRepository!
    private var viewModel: TimelineViewModel!
    private var calendar: Calendar!

    override func setUp() async throws {
        try await super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        eventsRepo = MockEventsRepository()
        measurementsRepo = MockMeasurementsRepository()
        viewModel = TimelineViewModel(
            eventsRepository: eventsRepo,
            measurementsRepository: measurementsRepo,
            calendar: calendar
        )
    }

    // MARK: - Refresh Tests

    func testRefreshBuildsSections() async throws {
        // Given
        let event = EventDTO(kind: .feed, start: Date())
        eventsRepo.events = [event]

        // When
        await viewModel.refresh()

        // Then
        XCTAssertFalse(viewModel.sections.isEmpty)
        XCTAssertEqual(viewModel.sections.count, 1)
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
    }

    func testRefreshGroupsEventsByDay() async throws {
        // Given
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let event1 = EventDTO(kind: .sleep, start: today)
        let event2 = EventDTO(kind: .feed, start: today)
        let event3 = EventDTO(kind: .diaper, start: yesterday)

        eventsRepo.events = [event1, event2, event3]

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.sections.count, 2, "Should have 2 day sections")
        XCTAssertEqual(viewModel.sections.first?.items.count, 2, "Today should have 2 events")
        XCTAssertEqual(viewModel.sections.last?.items.count, 1, "Yesterday should have 1 event")
    }

    func testRefreshSortsSectionsInReverseChronologicalOrder() async throws {
        // Given
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        eventsRepo.events = [
            EventDTO(kind: .sleep, start: twoDaysAgo),
            EventDTO(kind: .feed, start: today),
            EventDTO(kind: .diaper, start: yesterday)
        ]

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.sections.count, 3)
        XCTAssertTrue(viewModel.sections[0].date > viewModel.sections[1].date)
        XCTAssertTrue(viewModel.sections[1].date > viewModel.sections[2].date)
    }

    func testRefreshCombinesEventsAndMeasurements() async throws {
        // Given
        let event = EventDTO(kind: .sleep, start: Date())
        let measurement = MeasurementDTO(type: .height, value: 50, unit: "cm", date: Date())

        eventsRepo.events = [event]
        measurementsRepo.measurements = [measurement]

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 2, "Should have both event and measurement")
    }

    func testRefreshSetsLoadingState() async throws {
        // Given
        XCTAssertFalse(viewModel.isLoading)

        // When
        let refreshTask = Task {
            await viewModel.refresh()
        }

        // Give it a moment to start loading
        try await Task.sleep(nanoseconds: 10_000_000)

        // Loading should have been true at some point (now might be false if refresh completed)
        await refreshTask.value

        // Then - after completion, should not be loading
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Filter Tests

    func testFilterAllShowsAllItems() async throws {
        // Given
        eventsRepo.events = [EventDTO(kind: .sleep, start: Date())]
        measurementsRepo.measurements = [MeasurementDTO(type: .height, value: 50, unit: "cm", date: Date())]
        await viewModel.refresh()

        // When
        viewModel.filter = .all

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 2)
    }

    func testFilterEventsShowsOnlyEvents() async throws {
        // Given
        eventsRepo.events = [EventDTO(kind: .sleep, start: Date())]
        measurementsRepo.measurements = [MeasurementDTO(type: .height, value: 50, unit: "cm", date: Date())]
        await viewModel.refresh()

        // When
        viewModel.filter = .events

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
        guard case .event = viewModel.sections.first?.items.first else {
            XCTFail("Should be an event")
            return
        }
    }

    func testFilterMeasurementsShowsOnlyMeasurements() async throws {
        // Given
        eventsRepo.events = [EventDTO(kind: .sleep, start: Date())]
        measurementsRepo.measurements = [MeasurementDTO(type: .height, value: 50, unit: "cm", date: Date())]
        await viewModel.refresh()

        // When
        viewModel.filter = .measurements

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
        guard case .measurement = viewModel.sections.first?.items.first else {
            XCTFail("Should be a measurement")
            return
        }
    }

    // MARK: - Search Tests

    func testSearchByEventKind() async throws {
        // Given
        eventsRepo.events = [
            EventDTO(kind: .sleep, start: Date()),
            EventDTO(kind: .feed, start: Date())
        ]
        await viewModel.refresh()

        // When
        viewModel.searchText = "sleep"
        viewModel.applyFilters()

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
        if case let .event(event) = viewModel.sections.first?.items.first {
            XCTAssertEqual(event.kind, .sleep)
        } else {
            XCTFail("Should be a sleep event")
        }
    }

    func testSearchByEventNotes() async throws {
        // Given
        eventsRepo.events = [
            EventDTO(kind: .sleep, start: Date(), notes: "Great sleep"),
            EventDTO(kind: .feed, start: Date(), notes: "Quick feeding")
        ]
        await viewModel.refresh()

        // When
        viewModel.searchText = "Great"
        viewModel.applyFilters()

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
    }

    func testSearchIsCaseInsensitive() async throws {
        // Given
        eventsRepo.events = [
            EventDTO(kind: .sleep, start: Date(), notes: "GREAT SLEEP")
        ]
        await viewModel.refresh()

        // When
        viewModel.searchText = "great"
        viewModel.applyFilters()

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
    }

    func testSearchReturnsEmptyWhenNoMatch() async throws {
        // Given
        eventsRepo.events = [
            EventDTO(kind: .sleep, start: Date(), notes: "Good sleep")
        ]
        await viewModel.refresh()

        // When
        viewModel.searchText = "nonexistent"
        viewModel.applyFilters()

        // Then
        XCTAssertTrue(viewModel.sections.isEmpty)
    }

    // MARK: - Delete and Undo Tests

    func testDeleteRemovesItem() async throws {
        // Given
        let event = EventDTO(kind: .sleep, start: Date())
        eventsRepo.events = [event]
        await viewModel.refresh()
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)

        // When
        await viewModel.delete(.event(event))

        // Then
        XCTAssertTrue(viewModel.sections.isEmpty)
    }

    func testUndoDeleteRestoresItem() async throws {
        // Given
        let event = EventDTO(kind: .sleep, start: Date())
        eventsRepo.events = [event]
        await viewModel.refresh()

        // When
        await viewModel.delete(.event(event))
        XCTAssertTrue(viewModel.sections.isEmpty, "Should be empty after delete")

        await viewModel.undoDelete()

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1, "Should restore after undo")
    }

    func testDeleteMeasurementRemovesItem() async throws {
        // Given
        let measurement = MeasurementDTO(type: .height, value: 50, unit: "cm", date: Date())
        measurementsRepo.measurements = [measurement]
        await viewModel.refresh()
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)

        // When
        await viewModel.delete(.measurement(measurement))

        // Then
        XCTAssertTrue(viewModel.sections.isEmpty)
    }

    // MARK: - Append Tests

    func testAppendAddsEventToCache() async throws {
        // Given
        await viewModel.refresh()
        XCTAssertTrue(viewModel.sections.isEmpty)

        // When
        let event = EventDTO(kind: .feed, start: Date())
        viewModel.append(event: event)

        // Then
        XCTAssertEqual(viewModel.sections.first?.items.count, 1)
    }

    // MARK: - Section Title Tests

    func testSectionTitleForToday() async throws {
        // Given
        let today = Date()
        eventsRepo.events = [EventDTO(kind: .sleep, start: today)]

        // When
        await viewModel.refresh()

        // Then
        // The title should be "Today" (or localized equivalent)
        XCTAssertTrue(viewModel.sections.first?.title.localizedCaseInsensitiveContains("today") ?? false)
    }

    func testSectionTitleForYesterday() async throws {
        // Given
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        eventsRepo.events = [EventDTO(kind: .sleep, start: yesterday)]

        // When
        await viewModel.refresh()

        // Then
        XCTAssertTrue(viewModel.sections.first?.title.localizedCaseInsensitiveContains("yesterday") ?? false)
    }

    // MARK: - Edge Cases

    func testRefreshWithEmptyRepositories() async throws {
        // Given
        eventsRepo.events = []
        measurementsRepo.measurements = []

        // When
        await viewModel.refresh()

        // Then
        XCTAssertTrue(viewModel.sections.isEmpty)
    }

    func testForceRefreshReloadsEvenWhenLoading() async throws {
        // Given
        eventsRepo.events = [EventDTO(kind: .sleep, start: Date())]

        // When
        await viewModel.refresh()
        await viewModel.refresh(force: true)

        // Then
        XCTAssertFalse(viewModel.sections.isEmpty)
    }
}

// MARK: - Mock Repositories

private actor MockEventsRepository: EventsRepository {
    var events: [EventDTO] = []
    var shouldThrowError = false

    func create(_ dto: EventDTO) async throws -> EventDTO {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        events.append(dto)
        return dto
    }

    func update(_ dto: EventDTO) async throws -> EventDTO {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        if let index = events.firstIndex(where: { $0.id == dto.id }) {
            events[index] = dto
        }
        return dto
    }

    func delete(id: UUID) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        events.removeAll { $0.id == id }
    }

    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        return events.filter { event in
            let matchesKind = kind.map { $0 == event.kind } ?? true
            guard matchesKind else { return false }

            guard let interval else { return true }
            return event.start >= interval.start && event.start < interval.end
        }
    }

    func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        events.filter { $0.kind == kind }.sorted { $0.start > $1.start }.first
    }

    func stats(for day: Date) async throws -> EventDayStats {
        EventDayStats(sleepCount: 0, feedCount: 0, diaperCount: 0)
    }
}

private actor MockMeasurementsRepository: MeasurementsRepository {
    var measurements: [MeasurementDTO] = []
    var shouldThrowError = false

    func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        measurements.append(dto)
        return dto
    }

    func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        if let index = measurements.firstIndex(where: { $0.id == dto.id }) {
            measurements[index] = dto
        }
        return dto
    }

    func delete(id: UUID) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        measurements.removeAll { $0.id == id }
    }

    func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        return measurements.filter { measurement in
            let matchesType = type.map { $0 == measurement.type } ?? true
            guard matchesType else { return false }

            guard let interval else { return true }
            return measurement.date >= interval.start && measurement.date < interval.end
        }
    }
}
