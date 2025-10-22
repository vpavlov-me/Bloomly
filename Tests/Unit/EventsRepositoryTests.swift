import CoreData
import XCTest
@testable import BabyTrack
@testable import Tracking

final class EventsRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var repository: CoreDataEventsRepository!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        repository = CoreDataEventsRepository(context: persistence.viewContext)
    }

    override func tearDown() {
        persistence = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Basic CRUD Tests

    func testCreateAndFetchEvents() async throws {
        let event = EventDTO(kind: .sleep, start: Date(), end: Date().addingTimeInterval(1800))
        let created = try await repository.create(event)
        XCTAssertEqual(created.kind, .sleep)

        let fetched = try await repository.events(in: nil, kind: nil)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, created.id)
    }

    func testUpdateEvent() async throws {
        let event = EventDTO(kind: .feed, start: Date(), end: Date().addingTimeInterval(1200))
        var created = try await repository.create(event)
        created.notes = "Updated"
        created.end = created.start.addingTimeInterval(1500)

        let updated = try await repository.update(created)
        XCTAssertEqual(updated.notes, "Updated")
        XCTAssertEqual(updated.end, created.start.addingTimeInterval(1500))
    }

    func testDeleteEvent() async throws {
        let event = EventDTO(kind: .diaper, start: Date())
        let created = try await repository.create(event)
        try await repository.delete(id: created.id)

        let fetched = try await repository.events(in: nil, kind: nil)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - Edge Cases Tests

    func testFetchEventsWhenEmpty() async throws {
        let fetched = try await repository.events(in: nil, kind: nil)
        XCTAssertTrue(fetched.isEmpty, "Should return empty array when no events exist")
    }

    func testCreateEventWithoutEnd() async throws {
        let event = EventDTO(kind: .sleep, start: Date(), end: nil)
        let created = try await repository.create(event)

        XCTAssertNil(created.end, "End should be nil for ongoing events")
        XCTAssertTrue(created.isOngoing, "Event without end should be marked as ongoing")
    }

    func testCreateEventWithLongNotes() async throws {
        let longNotes = String(repeating: "Test note ", count: 100)
        let event = EventDTO(kind: .feed, start: Date(), notes: longNotes)
        let created = try await repository.create(event)

        XCTAssertEqual(created.notes, longNotes, "Should handle long notes correctly")
    }

    func testCreateEventWithEmptyNotes() async throws {
        let event = EventDTO(kind: .diaper, start: Date(), notes: "")
        let created = try await repository.create(event)

        XCTAssertEqual(created.notes, "", "Should preserve empty string notes")
    }

    func testFetchEventsWithLargeDataset() async throws {
        // Create 100 events
        for i in 0..<100 {
            let start = Date().addingTimeInterval(TimeInterval(-i * 3600))
            let event = EventDTO(kind: .sleep, start: start, end: start.addingTimeInterval(1800))
            _ = try await repository.create(event)
        }

        let fetched = try await repository.events(in: nil, kind: nil)
        XCTAssertEqual(fetched.count, 100, "Should handle large datasets")

        // Verify sorting (newest first)
        for i in 0..<fetched.count - 1 {
            XCTAssertGreaterThanOrEqual(fetched[i].start, fetched[i + 1].start, "Events should be sorted by start date descending")
        }
    }

    func testFetchEventsWithDateInterval() async throws {
        let now = Date()
        let calendar = Calendar.current

        // Create events for different days
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!

        _ = try await repository.create(EventDTO(kind: .sleep, start: yesterday))
        _ = try await repository.create(EventDTO(kind: .feed, start: now))
        _ = try await repository.create(EventDTO(kind: .diaper, start: tomorrow))

        // Fetch only today's events
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let interval = DateInterval(start: startOfDay, end: endOfDay)

        let todayEvents = try await repository.events(in: interval, kind: nil)
        XCTAssertEqual(todayEvents.count, 1, "Should only fetch events in the specified interval")
        XCTAssertEqual(todayEvents.first?.kind, .feed)
    }

    func testFetchEventsByKind() async throws {
        _ = try await repository.create(EventDTO(kind: .sleep, start: Date()))
        _ = try await repository.create(EventDTO(kind: .sleep, start: Date().addingTimeInterval(-100)))
        _ = try await repository.create(EventDTO(kind: .feed, start: Date()))

        let sleepEvents = try await repository.events(in: nil, kind: .sleep)
        XCTAssertEqual(sleepEvents.count, 2, "Should filter events by kind")
        XCTAssertTrue(sleepEvents.allSatisfy { $0.kind == .sleep })
    }

    func testLastEventForKind() async throws {
        let older = try await repository.create(EventDTO(kind: .sleep, start: Date().addingTimeInterval(-3600)))
        let newer = try await repository.create(EventDTO(kind: .sleep, start: Date()))
        _ = try await repository.create(EventDTO(kind: .feed, start: Date()))

        let lastSleep = try await repository.lastEvent(for: .sleep)
        XCTAssertNotNil(lastSleep)
        XCTAssertEqual(lastSleep?.id, newer.id, "Should return the most recent event of the specified kind")
    }

    func testLastEventForKindWhenNoneExist() async throws {
        let lastEvent = try await repository.lastEvent(for: .sleep)
        XCTAssertNil(lastEvent, "Should return nil when no events of the specified kind exist")
    }

    func testStatsForDay() async throws {
        let now = Date()
        let calendar = Calendar.current

        // Create multiple events for today
        _ = try await repository.create(EventDTO(kind: .sleep, start: now, end: now.addingTimeInterval(1800)))
        _ = try await repository.create(EventDTO(kind: .feed, start: now, end: now.addingTimeInterval(900)))

        // Create event for yesterday (should not be included)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        _ = try await repository.create(EventDTO(kind: .sleep, start: yesterday, end: yesterday.addingTimeInterval(1800)))

        let stats = try await repository.stats(for: now)
        XCTAssertEqual(stats.totalEvents, 2, "Should count only today's events")
        XCTAssertEqual(stats.totalDuration, 2700, accuracy: 1, "Should sum durations correctly")
    }

    // MARK: - Error Handling Tests

    func testUpdateNonExistentEvent() async throws {
        let event = EventDTO(kind: .sleep, start: Date())

        do {
            _ = try await repository.update(event)
            XCTFail("Should throw notFound error")
        } catch let error as EventsRepositoryError {
            if case .notFound = error {
                // Expected error
            } else {
                XCTFail("Should throw notFound error, got \(error)")
            }
        }
    }

    func testDeleteNonExistentEvent() async throws {
        let nonExistentId = UUID()

        do {
            try await repository.delete(id: nonExistentId)
            XCTFail("Should throw notFound error")
        } catch let error as EventsRepositoryError {
            if case .notFound = error {
                // Expected error
            } else {
                XCTFail("Should throw notFound error, got \(error)")
            }
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentReads() async throws {
        // Create some events first
        for i in 0..<10 {
            _ = try await repository.create(EventDTO(kind: .sleep, start: Date().addingTimeInterval(TimeInterval(-i * 100))))
        }

        // Perform multiple concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let events = try await self.repository.events(in: nil, kind: nil)
                        XCTAssertEqual(events.count, 10, "Concurrent reads should return consistent results")
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }

    func testConcurrentWrites() async throws {
        // Perform multiple concurrent writes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        let event = EventDTO(kind: .sleep, start: Date().addingTimeInterval(TimeInterval(-i * 100)))
                        _ = try await self.repository.create(event)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
        }

        // Verify all events were created
        let events = try await repository.events(in: nil, kind: nil)
        XCTAssertEqual(events.count, 20, "All concurrent writes should succeed")
    }

    func testConcurrentReadAndWrite() async throws {
        // Create initial event
        _ = try await repository.create(EventDTO(kind: .sleep, start: Date()))

        // Perform concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Add readers
            for _ in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.repository.events(in: nil, kind: nil)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }

            // Add writers
            for i in 0..<5 {
                group.addTask {
                    do {
                        let event = EventDTO(kind: .feed, start: Date().addingTimeInterval(TimeInterval(-i * 100)))
                        _ = try await self.repository.create(event)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
        }

        // Verify final state
        let finalEvents = try await repository.events(in: nil, kind: nil)
        XCTAssertEqual(finalEvents.count, 6, "Should have initial event plus 5 new events")
    }

    // MARK: - Performance Tests

    func testCreatePerformance() throws {
        measure {
            Task {
                for _ in 0..<50 {
                    let event = EventDTO(kind: .sleep, start: Date())
                    _ = try? await self.repository.create(event)
                }
            }
        }
    }

    func testFetchPerformance() async throws {
        // Create 100 events
        for i in 0..<100 {
            let event = EventDTO(kind: .sleep, start: Date().addingTimeInterval(TimeInterval(-i * 100)))
            _ = try await repository.create(event)
        }

        measure {
            Task {
                _ = try? await self.repository.events(in: nil, kind: nil)
            }
        }
    }

    func testQueryPerformanceWithLargeDataset() async throws {
        // Create 500 events
        for i in 0..<500 {
            let kinds: [EventKind] = [.sleep, .feed, .diaper]
            let kind = kinds[i % 3]
            let event = EventDTO(kind: kind, start: Date().addingTimeInterval(TimeInterval(-i * 100)))
            _ = try await repository.create(event)
        }

        // Measure filtered query performance
        let start = Date()
        _ = try await repository.events(in: nil, kind: .sleep)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.1, "Query should complete in under 100ms")
    }
}
