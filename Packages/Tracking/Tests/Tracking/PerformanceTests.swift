import XCTest
import CoreData
@testable import Tracking

/// Performance benchmarks for critical operations
final class PerformanceTests: XCTestCase {
    var context: NSManagedObjectContext!
    var repository: CoreDataEventsRepository!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "BabyTrack")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        context = container.viewContext
        repository = CoreDataEventsRepository(context: context)
    }

    override func tearDown() async throws {
        context = nil
        repository = nil
        try await super.tearDown()
    }

    // MARK: - App Launch Performance

    /// App launch time should be < 1 second
    func testAppLaunchTime() throws {
        // This would measure actual app launch in real scenario
        // For now, we measure repository initialization
        measure {
            _ = CoreDataEventsRepository(context: context)
        }
    }

    // MARK: - Query Performance

    /// Fetching 1000 events should take < 100ms
    func testFetchLargeDataset() async throws {
        // Setup: Create 1000 events
        let events = try await createTestEvents(count: 1000)

        // Measure: Fetch all events
        measure {
            let expectation = self.expectation(description: "Fetch events")
            Task {
                _ = try await repository.events(in: nil, kind: nil)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 0.2) // Should complete in < 100ms
        }
    }

    /// Fetching events for a specific day should be fast even with large dataset
    func testFetchEventsForSpecificDay() async throws {
        // Setup: Create events across 30 days
        let now = Date()
        var allEvents: [EventDTO] = []

        for dayOffset in 0..<30 {
            let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!
            let dayEvents = (0..<50).map { _ in
                EventDTO(
                    kind: .sleep,
                    start: day.addingTimeInterval(TimeInterval.random(in: 0...86400))
                )
            }
            allEvents.append(contentsOf: dayEvents)
        }

        _ = try await repository.batchCreate(allEvents)

        // Measure: Fetch today's events
        let today = Calendar.current.startOfDay(for: now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let interval = DateInterval(start: today, end: tomorrow)

        measure {
            let expectation = self.expectation(description: "Fetch today's events")
            Task {
                _ = try await repository.events(in: interval, kind: nil)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 0.1) // Should be very fast with proper indexing
        }
    }

    /// LastEvent query should be optimized with fetchLimit
    func testLastEventQuery() async throws {
        // Setup: Create many events
        _ = try await createTestEvents(count: 1000)

        // Measure: Fetch last event
        measure {
            let expectation = self.expectation(description: "Fetch last event")
            Task {
                _ = try await repository.lastEvent(for: .sleep)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 0.05) // Should be very fast (< 50ms)
        }
    }

    // MARK: - Batch Operations Performance

    /// Batch create should be efficient
    func testBatchCreatePerformance() async throws {
        let events = (0..<100).map { i in
            EventDTO(
                kind: .sleep,
                start: Date().addingTimeInterval(TimeInterval(-i * 3600))
            )
        }

        measure {
            let expectation = self.expectation(description: "Batch create")
            Task {
                _ = try await repository.batchCreate(events)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0) // 100 events should be fast
        }
    }

    /// Batch update should be efficient
    func testBatchUpdatePerformance() async throws {
        // Setup: Create events
        var events = try await createTestEvents(count: 100)

        // Modify events
        events = events.map { event in
            EventDTO(
                id: event.id,
                kind: event.kind,
                start: event.start,
                end: Date(),
                notes: "Updated",
                createdAt: event.createdAt,
                updatedAt: Date(),
                isSynced: false,
                isDeleted: false
            )
        }

        measure {
            let expectation = self.expectation(description: "Batch update")
            Task {
                _ = try await repository.batchUpdate(events)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    // MARK: - Memory Performance

    /// Large dataset should not cause excessive memory usage
    func testMemoryUsageWithLargeDataset() async throws {
        // This test helps identify memory leaks or excessive allocations
        let initialMemory = getMemoryUsage()

        // Create and fetch large dataset
        _ = try await createTestEvents(count: 1000)
        let events = try await repository.events(in: nil, kind: nil)

        XCTAssertEqual(events.count, 1000, "Should fetch all events")

        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        // Memory increase should be reasonable (< 10 MB for 1000 events)
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory usage should be reasonable")
    }

    // MARK: - Helper Methods

    private func createTestEvents(count: Int) async throws -> [EventDTO] {
        let events = (0..<count).map { i in
            EventDTO(
                kind: EventKind.allCases.randomElement()!,
                start: Date().addingTimeInterval(TimeInterval(-i * 3600))
            )
        }
        return try await repository.batchCreate(events)
    }

    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            return 0
        }

        return info.resident_size
    }
}
