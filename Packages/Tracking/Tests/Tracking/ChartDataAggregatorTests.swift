import XCTest
@testable import Tracking

final class ChartDataAggregatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testSleepAggregationSplitsAcrossDays() async throws {
        let events = [
            EventDTO(
                kind: .sleep,
                start: date(year: 2024, month: 3, day: 1, hour: 22),
                end: date(year: 2024, month: 3, day: 2, hour: 6)
            ),
            EventDTO(
                kind: .sleep,
                start: date(year: 2024, month: 3, day: 2, hour: 12),
                end: date(year: 2024, month: 3, day: 2, hour: 13, minute: 30)
            )
        ]
        let repository = CountingEventsRepository(events: events)
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar, cacheTTL: 600)

        let range = DateInterval(
            start: date(year: 2024, month: 3, day: 1),
            end: date(year: 2024, month: 3, day: 3)
        )
        let series = try await aggregator.series(for: .sleepTotal, in: range, period: .day)

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points[0].interval.start, date(year: 2024, month: 3, day: 1))
        XCTAssertEqual(series.points[1].interval.start, date(year: 2024, month: 3, day: 2))
        XCTAssertEqual(series.points[0].value, 2, accuracy: 0.001, "Should count first 2 hours on day one")
        XCTAssertEqual(series.points[1].value, 7.5, accuracy: 0.001, "Should include remaining sleep plus nap")
        XCTAssertEqual(series.statistics.total, 9.5, accuracy: 0.001)
        XCTAssertEqual(series.statistics.sampleCount, 2)
        XCTAssertEqual(series.statistics.average, 4.75, accuracy: 0.001, "Average hours per day with data")
    }

    func testFeedAverageDurationProducesCorrectTotalsAndStatistics() async throws {
        let events = [
            EventDTO(
                kind: .feed,
                start: date(year: 2024, month: 3, day: 4, hour: 8),
                end: date(year: 2024, month: 3, day: 4, hour: 8, minute: 20)
            ),
            EventDTO(
                kind: .feed,
                start: date(year: 2024, month: 3, day: 4, hour: 12),
                end: date(year: 2024, month: 3, day: 4, hour: 12, minute: 10)
            ),
            EventDTO(
                kind: .feed,
                start: date(year: 2024, month: 3, day: 5, hour: 9),
                end: date(year: 2024, month: 3, day: 5, hour: 9, minute: 15)
            )
        ]
        let repository = CountingEventsRepository(events: events)
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar, cacheTTL: 600)

        let range = DateInterval(
            start: date(year: 2024, month: 3, day: 4),
            end: date(year: 2024, month: 3, day: 6)
        )
        let series = try await aggregator.series(for: .feedAverageDuration, in: range, period: .day)

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points[0].value, 15, accuracy: 0.001, "First day average duration should be 15 minutes")
        XCTAssertEqual(series.points[1].value, 15, accuracy: 0.001, "Second day average should be 15 minutes")
        XCTAssertEqual(series.statistics.total, 45, accuracy: 0.001, "Total minutes across all events")
        XCTAssertEqual(series.statistics.sampleCount, 3)
        XCTAssertEqual(series.statistics.average, 15, accuracy: 0.001, "Average per feeding event")
        XCTAssertEqual(series.statistics.minimum, 15, accuracy: 0.001)
        XCTAssertEqual(series.statistics.maximum, 15, accuracy: 0.001)
    }

    func testFeedFrequencyWeeklyAggregation() async throws {
        let events = [
            EventDTO(kind: .feed, start: date(year: 2024, month: 3, day: 3, hour: 7)),
            EventDTO(kind: .feed, start: date(year: 2024, month: 3, day: 4, hour: 8)),
            EventDTO(kind: .feed, start: date(year: 2024, month: 3, day: 10, hour: 9))
        ]
        let repository = CountingEventsRepository(events: events)
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar, cacheTTL: 600)

        let range = DateInterval(
            start: date(year: 2024, month: 3, day: 3),
            end: date(year: 2024, month: 3, day: 17)
        )
        let series = try await aggregator.series(for: .feedFrequency, in: range, period: .week)

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points[0].value, 2)
        XCTAssertEqual(series.points[1].value, 1)
        XCTAssertEqual(series.statistics.total, 3)
        XCTAssertEqual(series.statistics.sampleCount, 3)
        XCTAssertEqual(series.statistics.average, 1.5, accuracy: 0.001, "Average per week with data")
        XCTAssertEqual(series.statistics.maximum, 2)
        XCTAssertEqual(series.statistics.minimum, 1)
    }

    func testDiaperFrequencyMonthlyAggregationProducesZeroesForEmptyBuckets() async throws {
        let events = [
            EventDTO(kind: .diaper, start: date(year: 2024, month: 1, day: 2)),
            EventDTO(kind: .diaper, start: date(year: 2024, month: 1, day: 18)),
            EventDTO(kind: .diaper, start: date(year: 2024, month: 2, day: 6))
        ]
        let repository = CountingEventsRepository(events: events)
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar, cacheTTL: 600)

        let range = DateInterval(
            start: date(year: 2024, month: 1, day: 1),
            end: date(year: 2024, month: 3, day: 1)
        )
        let series = try await aggregator.series(for: .diaperFrequency, in: range, period: .month)

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points[0].value, 2)
        XCTAssertEqual(series.points[1].value, 1)
        XCTAssertEqual(series.points[0].sampleCount, 2)
        XCTAssertEqual(series.points[1].sampleCount, 1)
        XCTAssertEqual(series.statistics.total, 3)
        XCTAssertEqual(series.statistics.sampleCount, 3)
        XCTAssertEqual(series.statistics.average, 1.5, accuracy: 0.001)
    }

    func testCachingAvoidsRepeatedRepositoryCalls() async throws {
        let events = [
            EventDTO(kind: .feed, start: date(year: 2024, month: 4, day: 2)),
            EventDTO(kind: .feed, start: date(year: 2024, month: 4, day: 3))
        ]
        let repository = CountingEventsRepository(events: events)
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar, cacheTTL: 600)

        let range = DateInterval(
            start: date(year: 2024, month: 4, day: 1),
            end: date(year: 2024, month: 4, day: 5)
        )
        _ = try await aggregator.series(for: .feedFrequency, in: range, period: .day)
        let firstCount = await repository.eventsCallCount()
        _ = try await aggregator.series(for: .feedFrequency, in: range, period: .day)
        let secondCount = await repository.eventsCallCount()

        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 1, "Second call should be served from cache")
    }

    func testCacheInvalidationForMetricForcesNewFetch() async throws {
        let events = [
            EventDTO(kind: .feed, start: date(year: 2024, month: 4, day: 2))
        ]
        let repository = CountingEventsRepository(events: events)
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar, cacheTTL: 600)

        let range = DateInterval(
            start: date(year: 2024, month: 4, day: 1),
            end: date(year: 2024, month: 4, day: 5)
        )
        _ = try await aggregator.series(for: .feedFrequency, in: range, period: .day)
        await aggregator.invalidateCache(metric: .feedFrequency)
        _ = try await aggregator.series(for: .feedFrequency, in: range, period: .day)

        let callCount = await repository.eventsCallCount()
        XCTAssertEqual(callCount, 2, "Should fetch again after invalidation")
    }

    func testInvalidRangeThrows() async {
        let repository = CountingEventsRepository(events: [])
        let aggregator = ChartDataAggregator(eventsRepository: repository, calendar: calendar)
        let range = DateInterval(start: date(year: 2024, month: 5, day: 1), end: date(year: 2024, month: 5, day: 1))

        await XCTAssertThrowsErrorAsync(
            try await aggregator.series(for: .feedFrequency, in: range, period: .day)
        )
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

private extension ChartDataAggregatorTests {
    actor CountingEventsRepository: EventsRepository {
        private let storage: [EventDTO]
        private var counter = 0

        init(events: [EventDTO]) {
            self.storage = events.sorted { $0.start < $1.start }
        }

        func create(_ dto: EventDTO) async throws -> EventDTO {
            fatalError("Not implemented")
        }

        func update(_ dto: EventDTO) async throws -> EventDTO {
            fatalError("Not implemented")
        }

        func delete(id: UUID) async throws {
            fatalError("Not implemented")
        }

        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
            counter += 1
            return storage.filter { event in
                let matchesKind = kind.map { $0 == event.kind } ?? true
                guard matchesKind else { return false }

                guard let interval else { return true }
                return event.start >= interval.start && event.start < interval.end
            }
        }

        func lastEvent(for kind: EventKind) async throws -> EventDTO? {
            fatalError("Not implemented")
        }

        func stats(for day: Date) async throws -> EventDayStats {
            fatalError("Not implemented")
        }

        func eventsCallCount() -> Int {
            counter
        }
    }
}

private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error", file: file, line: line)
        } catch {
            // expected
        }
    }
}
