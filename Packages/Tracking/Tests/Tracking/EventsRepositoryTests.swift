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

    func testUpsertCreatesRecord() async throws {
        let now = Date()
        let input = EventInput(
            kind: .sleep,
            start: now,
            end: now.addingTimeInterval(1800),
            notes: "Nap",
            createdAt: now,
            updatedAt: now,
            isSynced: false
        )
        try await repository.upsert(input)
        let events = try await repository.events(in: nil, of: nil)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.notes, "Nap")
    }

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
            "isSynced": .booleanAttributeType
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
