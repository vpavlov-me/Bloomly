import CoreData
import XCTest
@testable import Tracking

final class TrackingRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: CoreDataEventsRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = makeContainer()
        repository = CoreDataEventsRepository(context: container.viewContext)
    }

    override func tearDownWithError() throws {
        container = nil
        repository = nil
        try super.tearDownWithError()
    }

    func testSaveAndFetchEvent() async throws {
        let draft = EventDraft(kind: .feed, start: Date(), notes: "120ml")
        let saved = try await repository.save(draft: draft)
        XCTAssertEqual(saved.kind, .feed)

        let fetched = try await repository.fetchEvent(withID: saved.id)
        XCTAssertEqual(fetched?.id, saved.id)
    }

    func testTimelineBuilderGroupsOverlappingEvents() {
        let builder = SequentialTimelineBuilder()
        let now = Date()
        let events = [
            Event(id: UUID(), kind: .sleep, start: now, end: now.addingTimeInterval(3600), notes: nil, createdAt: now, updatedAt: now, isSynced: false),
            Event(id: UUID(), kind: .feed, start: now.addingTimeInterval(600), end: now.addingTimeInterval(900), notes: nil, createdAt: now, updatedAt: now, isSynced: false)
        ]

        let items = builder.buildTimeline(from: events)
        XCTAssertEqual(items.count, 1)
        if case let .range(range) = items[0].type {
            XCTAssertEqual(range.count, 2)
        } else {
            XCTFail("Expected range item")
        }
    }

    private func makeContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Event"
        entity.managedObjectClassName = "EventEntity"

        let attributes: [String: NSAttributeDescription] = [
            "id": UUIDAttributeDescription(name: "id"),
            "kind": StringAttributeDescription(name: "kind"),
            "start": DateAttributeDescription(name: "start"),
            "end": DateAttributeDescription(name: "end", isOptional: true),
            "notes": StringAttributeDescription(name: "notes", isOptional: true),
            "createdAt": DateAttributeDescription(name: "createdAt"),
            "updatedAt": DateAttributeDescription(name: "updatedAt"),
            "isSynced": BooleanAttributeDescription(name: "isSynced")
        ]
        entity.properties = Array(attributes.values)
        model.entities = [entity]

        let container = NSPersistentContainer(name: "BabyTrackModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }
        return container
    }
}

private func UUIDAttributeDescription(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .UUIDAttributeType
    attribute.isOptional = false
    return attribute
}

private func StringAttributeDescription(name: String, isOptional: Bool = false) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .stringAttributeType
    attribute.isOptional = isOptional
    return attribute
}

private func DateAttributeDescription(name: String, isOptional: Bool = false) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .dateAttributeType
    attribute.isOptional = isOptional
    return attribute
}

private func BooleanAttributeDescription(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .booleanAttributeType
    attribute.isOptional = false
    attribute.defaultValue = false
    return attribute
}
