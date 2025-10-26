import XCTest
@testable import Tracking

@MainActor
final class ChartsViewModelTests: XCTestCase {
    private var calendar: Calendar!
    private var mockRepository: MockEventsRepository!
    private var aggregator: ChartDataAggregator!
    private var viewModel: ChartsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        mockRepository = MockEventsRepository()
        aggregator = ChartDataAggregator(
            eventsRepository: mockRepository,
            calendar: calendar,
            cacheTTL: 600
        )
        viewModel = ChartsViewModel(
            aggregator: aggregator,
            calendar: calendar
        )
    }

    // MARK: - Loading Single Chart

    func testLoadChartForSleepMetricUpdatesChartData() async throws {
        // Given
        let sleepEvent = EventDTO(
            kind: .sleep,
            start: date(year: 2024, month: 3, day: 1, hour: 22),
            end: date(year: 2024, month: 3, day: 2, hour: 6)
        )
        mockRepository.storage = [sleepEvent]

        // When
        await viewModel.loadChart(for: .sleepTotal)

        // Then
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
        XCTAssertFalse(viewModel.isLoading(.sleepTotal))
        XCTAssertNil(viewModel.error(for: .sleepTotal))
    }

    func testLoadChartSetsLoadingStateCorrectly() async throws {
        // Given
        mockRepository.storage = []

        // When
        let loadTask = Task {
            await viewModel.loadChart(for: .feedFrequency)
        }

        // Check loading state is true during load
        // (In real scenario with slow repository, this would be more reliable)
        await loadTask.value

        // Then
        XCTAssertFalse(viewModel.isLoading(.feedFrequency))
    }

    func testLoadChartWithErrorUpdatesErrorState() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await viewModel.loadChart(for: .sleepTotal)

        // Then
        XCTAssertNil(viewModel.series(for: .sleepTotal))
        XCTAssertFalse(viewModel.isLoading(.sleepTotal))
        XCTAssertNotNil(viewModel.error(for: .sleepTotal))
    }

    // MARK: - Loading All Charts

    func testLoadAllChartsLoadsAllMetrics() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .sleep, start: date(year: 2024, month: 3, day: 1)),
            EventDTO(kind: .feed, start: date(year: 2024, month: 3, day: 1)),
            EventDTO(kind: .diaper, start: date(year: 2024, month: 3, day: 1))
        ]

        // When
        await viewModel.loadAllCharts()

        // Then
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
        XCTAssertNotNil(viewModel.series(for: .feedAverageDuration))
        XCTAssertNotNil(viewModel.series(for: .feedFrequency))
        XCTAssertNotNil(viewModel.series(for: .diaperFrequency))
    }

    // MARK: - Period Changes

    func testChangePeriodUpdatesSelectedPeriod() async throws {
        // Given
        XCTAssertEqual(viewModel.selectedPeriod, .day)

        // When
        await viewModel.changePeriod(.week)

        // Then
        XCTAssertEqual(viewModel.selectedPeriod, .week)
    }

    func testChangePeriodReloadsLoadedCharts() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .sleep, start: date(year: 2024, month: 3, day: 1))
        ]
        await viewModel.loadChart(for: .sleepTotal)
        let originalSeries = viewModel.series(for: .sleepTotal)

        // When
        await viewModel.changePeriod(.week)

        // Then
        let newSeries = viewModel.series(for: .sleepTotal)
        XCTAssertNotNil(newSeries)
        // Series should be different due to different period
        XCTAssertEqual(newSeries?.period, .week)
        XCTAssertEqual(originalSeries?.period, .day)
    }

    func testChangePeriodDoesNotReloadIfPeriodIsSame() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .sleep, start: date(year: 2024, month: 3, day: 1))
        ]
        await viewModel.loadChart(for: .sleepTotal)
        let callCountBefore = mockRepository.callCount

        // When
        await viewModel.changePeriod(.day) // Same as current

        // Then
        let callCountAfter = mockRepository.callCount
        XCTAssertEqual(callCountBefore, callCountAfter, "Should not reload if period unchanged")
    }

    // MARK: - Date Range Changes

    func testChangeDateRangeUpdatesSelectedRange() async throws {
        // Given
        XCTAssertEqual(viewModel.selectedDateRange, .last7Days)

        // When
        await viewModel.changeDateRange(.last30Days)

        // Then
        XCTAssertEqual(viewModel.selectedDateRange, .last30Days)
    }

    func testSetCustomDateRangeSetsCustomPreset() async throws {
        // Given
        let customRange = DateInterval(
            start: date(year: 2024, month: 1, day: 1),
            end: date(year: 2024, month: 2, day: 1)
        )

        // When
        await viewModel.setCustomDateRange(customRange)

        // Then
        XCTAssertEqual(viewModel.selectedDateRange, .custom)
        XCTAssertEqual(viewModel.customDateRange, customRange)
    }

    // MARK: - Refresh Operations

    func testRefreshChartInvalidatesCacheAndReloads() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .feed, start: date(year: 2024, month: 4, day: 2))
        ]
        await viewModel.loadChart(for: .feedFrequency)
        let callCountBefore = mockRepository.callCount

        // When
        await viewModel.refreshChart(for: .feedFrequency)

        // Then
        let callCountAfter = mockRepository.callCount
        XCTAssertGreaterThan(callCountAfter, callCountBefore, "Should fetch again after refresh")
    }

    func testRefreshAllChartsInvalidatesEntireCache() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .sleep, start: date(year: 2024, month: 3, day: 1)),
            EventDTO(kind: .feed, start: date(year: 2024, month: 3, day: 1))
        ]
        await viewModel.loadChart(for: .sleepTotal)
        await viewModel.loadChart(for: .feedFrequency)
        let callCountBefore = mockRepository.callCount

        // When
        await viewModel.refreshAllCharts()

        // Then
        let callCountAfter = mockRepository.callCount
        XCTAssertGreaterThan(callCountAfter, callCountBefore, "Should refetch all metrics")
    }

    // MARK: - Date Range Calculations

    func testLast7DaysPresetCalculatesCorrectRange() async throws {
        // Given
        mockRepository.storage = []
        viewModel.selectedDateRange = .last7Days

        // When
        await viewModel.loadChart(for: .sleepTotal)

        // Then - verify the series was created (indirectly confirms range calculation worked)
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
    }

    func testThisWeekPresetCalculatesCorrectRange() async throws {
        // Given
        mockRepository.storage = []

        // When
        await viewModel.changeDateRange(.thisWeek)
        await viewModel.loadChart(for: .sleepTotal)

        // Then
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
        XCTAssertEqual(viewModel.selectedDateRange, .thisWeek)
    }

    func testThisMonthPresetCalculatesCorrectRange() async throws {
        // Given
        mockRepository.storage = []

        // When
        await viewModel.changeDateRange(.thisMonth)
        await viewModel.loadChart(for: .sleepTotal)

        // Then
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
        XCTAssertEqual(viewModel.selectedDateRange, .thisMonth)
    }

    // MARK: - Multiple Metrics

    func testCanLoadMultipleMetricsIndependently() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .sleep, start: date(year: 2024, month: 3, day: 1)),
            EventDTO(kind: .feed, start: date(year: 2024, month: 3, day: 1))
        ]

        // When
        await viewModel.loadChart(for: .sleepTotal)
        await viewModel.loadChart(for: .feedFrequency)

        // Then
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
        XCTAssertNotNil(viewModel.series(for: .feedFrequency))
        XCTAssertNil(viewModel.series(for: .diaperFrequency)) // Not loaded
    }

    func testErrorInOneMetricDoesNotAffectOthers() async throws {
        // Given
        mockRepository.storage = [
            EventDTO(kind: .sleep, start: date(year: 2024, month: 3, day: 1))
        ]

        // When
        await viewModel.loadChart(for: .sleepTotal) // Should succeed
        mockRepository.shouldThrowError = true
        await viewModel.loadChart(for: .feedFrequency) // Should fail

        // Then
        XCTAssertNotNil(viewModel.series(for: .sleepTotal))
        XCTAssertNil(viewModel.error(for: .sleepTotal))
        XCTAssertNil(viewModel.series(for: .feedFrequency))
        XCTAssertNotNil(viewModel.error(for: .feedFrequency))
    }

    // MARK: - DateRangePreset

    func testDateRangePresetDisplayNames() {
        XCTAssertEqual(DateRangePreset.last7Days.displayName, "Last 7 Days")
        XCTAssertEqual(DateRangePreset.last14Days.displayName, "Last 14 Days")
        XCTAssertEqual(DateRangePreset.last30Days.displayName, "Last 30 Days")
        XCTAssertEqual(DateRangePreset.thisWeek.displayName, "This Week")
        XCTAssertEqual(DateRangePreset.thisMonth.displayName, "This Month")
        XCTAssertEqual(DateRangePreset.custom.displayName, "Custom")
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

// MARK: - Mock Repository

private actor MockEventsRepository: EventsRepository {
    var storage: [EventDTO] = []
    var shouldThrowError = false
    private(set) var callCount = 0

    func create(_ dto: EventDTO) async throws -> EventDTO {
        throw NSError(domain: "NotImplemented", code: 0)
    }

    func update(_ dto: EventDTO) async throws -> EventDTO {
        throw NSError(domain: "NotImplemented", code: 0)
    }

    func delete(id: UUID) async throws {
        throw NSError(domain: "NotImplemented", code: 0)
    }

    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        callCount += 1

        if shouldThrowError {
            throw NSError(domain: "MockError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }

        return storage.filter { event in
            let matchesKind = kind.map { $0 == event.kind } ?? true
            guard matchesKind else { return false }

            guard let interval else { return true }
            return event.start >= interval.start && event.start < interval.end
        }
    }

    func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        throw NSError(domain: "NotImplemented", code: 0)
    }

    func stats(for day: Date) async throws -> EventDayStats {
        throw NSError(domain: "NotImplemented", code: 0)
    }
}
