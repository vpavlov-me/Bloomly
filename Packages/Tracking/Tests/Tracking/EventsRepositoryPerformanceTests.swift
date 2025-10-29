import CoreData
import XCTest
@testable import Tracking

/// Performance tests for EventsRepository
/// Requirements: Queries <100ms for 1000 events, Batch insert 100 events <500ms
final class EventsRepositoryPerformanceTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: CoreDataEventsRepository!

    override func setUpWithError() throws {
        container = NSPersistentContainer(name: "EventModel", managedObjectModel: Self.model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }
        repository = CoreDataEventsRepository(context: container.viewContext)
    }

    override func tearDownWithError() throws {
        repository = nil
        container = nil
    }

    // MARK: - Query Performance Tests

    func testQueryPerformanceWith1000Events() async throws {
        // Setup: Create 1000 events
        let events = (0..<1000).map { index in
            EventDTO(
                kind: EventKind.allCases[index % EventKind.allCases.count],
                start: Date().addingTimeInterval(Double(index * 60)),
                notes: "Event \(index)"
            )
        }

        _ = try await repository.batchCreate(events)

        // Measure query performance
        let startTime = Date()

        let fetched = try await repository.events(in: nil, kind: nil)

        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(fetched.count, 1000)
        XCTAssertLessThan(elapsed, 0.1, "Query took \(elapsed)s, should be <100ms")
    }

    func testQueryPerformanceWithDateRange() async throws {
        // Setup: Create 1000 events over 30 days
        let now = Date()
        let events = (0..<1000).map { index in
            EventDTO(
                kind: .sleep,
                start: now.addingTimeInterval(Double(index * 60 * 60)),
                notes: "Event \(index)"
            )
        }

        _ = try await repository.batchCreate(events)

        // Measure date range query
        let startTime = Date()

        let interval = DateInterval(start: now, end: now.addingTimeInterval(7 * 24 * 60 * 60))
        let fetched = try await repository.events(in: interval, kind: nil)

        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertGreaterThan(fetched.count, 0)
        XCTAssertLessThan(elapsed, 0.1, "Date range query took \(elapsed)s, should be <100ms")
    }

    // MARK: - Batch Insert Performance

    func testBatchInsert100Events() async throws {
        let events = (0..<100).map { index in
            EventDTO(
                kind: EventKind.allCases[index % EventKind.allCases.count],
                start: Date().addingTimeInterval(Double(index * 60)),
                notes: "Batch Event \(index)"
            )
        }

        let startTime = Date()

        let created = try await repository.batchCreate(events)

        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(created.count, 100)
        XCTAssertLessThan(elapsed, 0.5, "Batch insert took \(elapsed)s, should be <500ms")
    }

    func testBatchUpdate100Events() async throws {
        // Setup: Create 100 events
        let events = (0..<100).map { index in
            EventDTO(
                kind: .sleep,
                start: Date().addingTimeInterval(Double(index * 60)),
                notes: "Original \(index)"
            )
        }

        let created = try await repository.batchCreate(events)

        // Update all events
        let updated = created.map { event in
            var modified = event
            modified.notes = "Updated \(event.notes ?? "")"
            return modified
        }

        let startTime = Date()

        let results = try await repository.batchUpdate(updated)

        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(results.count, 100)
        XCTAssertLessThan(elapsed, 0.5, "Batch update took \(elapsed)s, should be <500ms")
    }

    // MARK: - Upsert Performance

    func testUpsertPerformance() async throws {
        let event = EventDTO(kind: .feeding, start: Date(), notes: "Performance test")

        // Measure first upsert (insert)
        let insertStart = Date()
        _ = try await repository.upsert(event)
        let insertElapsed = Date().timeIntervalSince(insertStart)

        // Measure second upsert (update)
        var updated = event
        updated.notes = "Updated"

        let updateStart = Date()
        _ = try await repository.upsert(updated)
        let updateElapsed = Date().timeIntervalSince(updateStart)

        XCTAssertLessThan(insertElapsed, 0.1, "Upsert insert took \(insertElapsed)s")
        XCTAssertLessThan(updateElapsed, 0.1, "Upsert update took \(updateElapsed)s")
    }

    // MARK: - Stress Tests

    func testConcurrentReads() async throws {
        // Setup: Create 100 events
        let events = (0..<100).map { index in
            EventDTO(kind: .sleep, start: Date().addingTimeInterval(Double(index * 60)))
        }
        _ = try await repository.batchCreate(events)

        // Perform concurrent reads
        let startTime = Date()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = try? await self.repository.events(in: nil, kind: nil)
                }
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 1.0, "10 concurrent reads took \(elapsed)s")
    }

    // MARK: - Core Data Model

    private static var model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Event"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let attributes: [String: NSAttributeType] = [
            "id": .UUIDAttributeType,
            "kind": .stringAttributeType,
            "start": .dateAttributeType,
            "end": .dateAttributeType,
            "notes": .stringAttributeType,
            "createdAt": .dateAttributeType,
            "updatedAt": .dateAttributeType,
            "isSynced": .booleanAttributeType,
            "isDeleted": .booleanAttributeType
        ]

        entity.properties = attributes.map { name, type in
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = (name == "end" || name == "notes")
            return attribute
        }

        model.entities = [entity]
        return model
    }()
}
