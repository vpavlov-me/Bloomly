import CoreData
import XCTest
@testable import Tracking

final class EventsRepositoryTests: XCTestCase {
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

    // MARK: - Create Tests

    func testCreateSleepEvent() async throws {
        let now = Date()
        let event = EventDTO(
            kind: .sleep,
            start: now,
            end: now.addingTimeInterval(1800),
            notes: "Nap time"
        )

        let created = try await repository.create(event)

        XCTAssertEqual(created.kind, .sleep)
        XCTAssertEqual(created.notes, "Nap time")
        XCTAssertFalse(created.isDeleted)
        XCTAssertFalse(created.isSynced)
    }

    func testCreateFeedingEvent() async throws {
        let now = Date()
        let event = EventDTO(
            kind: .feeding,
            start: now,
            end: now.addingTimeInterval(600),
            notes: "Bottle 120ml"
        )

        let created = try await repository.create(event)

        XCTAssertEqual(created.kind, .feed)
        XCTAssertEqual(created.notes, "Bottle 120ml")
    }

    // MARK: - Read Tests

    func testReadEvent() async throws {
        let event = EventDTO(kind: .diaper, start: Date(), notes: "Wet")
        let created = try await repository.create(event)

        let read = try await repository.read(id: created.id)

        XCTAssertEqual(read.id, created.id)
        XCTAssertEqual(read.kind, .diaper)
        XCTAssertEqual(read.notes, "Wet")
    }

    func testReadNonExistentEvent() async throws {
        do {
            _ = try await repository.read(id: UUID())
            XCTFail("Should throw notFound error")
        } catch EventsRepositoryError.notFound {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Update Tests

    func testUpdateEvent() async throws {
        let event = EventDTO(kind: .sleep, start: Date(), notes: "Short nap")
        let created = try await repository.create(event)

        var updated = created
        updated.notes = "Long nap"
        updated.end = Date().addingTimeInterval(3600)

        let result = try await repository.update(updated)

        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.notes, "Long nap")
        XCTAssertNotNil(result.end)
    }

    // MARK: - Delete Tests

    func testDeleteEvent() async throws {
        let event = EventDTO(kind: .feeding, start: Date())
        let created = try await repository.create(event)

        try await repository.delete(id: created.id)

        // Should not be found in normal queries (soft deleted)
        let events = try await repository.events(in: nil, kind: nil)
        XCTAssertFalse(events.contains(where: { $0.id == created.id }))
    }

    // MARK: - Upsert Tests

    func testUpsertCreatesNewEvent() async throws {
        let event = EventDTO(kind: .sleep, start: Date(), notes: "New event")

        let result = try await repository.upsert(event)

        XCTAssertEqual(result.id, event.id)
        XCTAssertEqual(result.notes, "New event")
    }

    func testUpsertUpdatesExistingEvent() async throws {
        let event = EventDTO(kind: .pumping, start: Date(), notes: "Original")
        let created = try await repository.create(event)

        var updated = created
        updated.notes = "Updated"

        let result = try await repository.upsert(updated)

        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.notes, "Updated")

        // Verify only one event exists
        let all = try await repository.events(in: nil, kind: .pumping)
        XCTAssertEqual(all.count, 1)
    }

    func testIdempotentUpsert() async throws {
        let event = EventDTO(kind: .diaper, start: Date(), notes: "First")

        // First upsert creates
        let first = try await repository.upsert(event)

        // Second upsert with same ID updates
        var updated = event
        updated.notes = "Second"
        let second = try await repository.upsert(updated)

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(second.notes, "Second")

        // Verify only one event exists
        let all = try await repository.events(in: nil, kind: .diaper)
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - Fetch Events Tests

    func testFetchEventsInDateRange() async throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 60 * 60)
        let tomorrow = now.addingTimeInterval(24 * 60 * 60)

        // Create events at different times
        _ = try await repository.create(EventDTO(kind: .sleep, start: yesterday))
        _ = try await repository.create(EventDTO(kind: .feeding, start: now))
        _ = try await repository.create(EventDTO(kind: .diaper, start: tomorrow))

        // Fetch only today and future
        let interval = DateInterval(start: now.addingTimeInterval(-60), end: tomorrow.addingTimeInterval(60))
        let events = try await repository.events(in: interval, kind: nil)

        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.contains(where: { $0.kind == .feeding }))
        XCTAssertTrue(events.contains(where: { $0.kind == .diaper }))
    }

    func testFetchEventsForBaby() async throws {
        let babyID = UUID()
        _ = try await repository.create(EventDTO(kind: .sleep, start: Date()))
        _ = try await repository.create(EventDTO(kind: .feeding, start: Date()))

        // Note: Baby relationship not yet implemented, so this returns all events
        let events = try await repository.events(for: babyID, in: nil)
        XCTAssertEqual(events.count, 2)
    }

    // MARK: - Batch Operations Tests

    func testBatchCreate() async throws {
        let events = [
            EventDTO(kind: .sleep, start: Date(), notes: "Event 1"),
            EventDTO(kind: .feeding, start: Date().addingTimeInterval(100), notes: "Event 2"),
            EventDTO(kind: .diaper, start: Date().addingTimeInterval(200), notes: "Event 3")
        ]

        let created = try await repository.batchCreate(events)

        XCTAssertEqual(created.count, 3)
        XCTAssertTrue(created.contains(where: { $0.notes == "Event 1" }))
        XCTAssertTrue(created.contains(where: { $0.notes == "Event 2" }))
        XCTAssertTrue(created.contains(where: { $0.notes == "Event 3" }))
    }

    func testBatchUpdate() async throws {
        // Create initial events
        let event1 = try await repository.create(EventDTO(kind: .sleep, start: Date(), notes: "Original 1"))
        let event2 = try await repository.create(EventDTO(kind: .feeding, start: Date(), notes: "Original 2"))

        // Update them
        var updated1 = event1
        updated1.notes = "Updated 1"
        var updated2 = event2
        updated2.notes = "Updated 2"

        let results = try await repository.batchUpdate([updated1, updated2])

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.notes == "Updated 1" }))
        XCTAssertTrue(results.contains(where: { $0.notes == "Updated 2" }))
    }

    // MARK: - Timezone Handling Tests

    func testTimezoneHandling() async throws {
        let calendar = Calendar.current
        let now = Date()

        let event = EventDTO(kind: .sleep, start: now)
        _ = try await repository.create(event)

        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let interval = DateInterval(start: startOfDay, end: endOfDay)

        let events = try await repository.events(in: interval, kind: nil)

        XCTAssertEqual(events.count, 1)
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
