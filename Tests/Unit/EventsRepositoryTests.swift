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
}
