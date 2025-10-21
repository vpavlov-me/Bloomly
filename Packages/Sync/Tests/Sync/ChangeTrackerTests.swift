import CoreData
import XCTest
@testable import Sync

final class ChangeTrackerTests: XCTestCase {
    func testTracksContextChanges() async throws {
        let container = makeContainer()
        let context = container.viewContext
        let tracker = CoreDataChangeTracker(context: context)

        let entity = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue("sleep", forKey: "kind")
        entity.setValue(Date(), forKey: "start")
        entity.setValue(Date(), forKey: "createdAt")
        entity.setValue(Date(), forKey: "updatedAt")
        entity.setValue(false, forKey: "isSynced")
        try context.save()

        let changes = await tracker.pendingChanges(limit: 10)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.entityName, "Event")
    }

    private func makeContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel()

        let event = NSEntityDescription()
        event.name = "Event"
        event.managedObjectClassName = "NSManagedObject"
        event.properties = [
            uuidAttribute("id"),
            stringAttribute("kind"),
            dateAttribute("start"),
            dateAttribute("end", optional: true),
            stringAttribute("notes", optional: true),
            dateAttribute("createdAt"),
            dateAttribute("updatedAt"),
            boolAttribute("isSynced")
        ]

        let measurement = NSEntityDescription()
        measurement.name = "Measurement"
        measurement.managedObjectClassName = "NSManagedObject"
        measurement.properties = [
            uuidAttribute("id"),
            stringAttribute("type"),
            doubleAttribute("value"),
            stringAttribute("unit"),
            dateAttribute("date"),
            boolAttribute("isSynced")
        ]

        model.entities = [event, measurement]

        let container = NSPersistentContainer(name: "BabyTrackModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Store error: \(error)")
            }
        }
        return container
    }
}

private func uuidAttribute(_ name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .UUIDAttributeType
    attribute.isOptional = false
    return attribute
}

private func stringAttribute(_ name: String, optional: Bool = false) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .stringAttributeType
    attribute.isOptional = optional
    return attribute
}

private func dateAttribute(_ name: String, optional: Bool = false) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .dateAttributeType
    attribute.isOptional = optional
    return attribute
}

private func boolAttribute(_ name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .booleanAttributeType
    attribute.isOptional = false
    attribute.defaultValue = false
    return attribute
}

private func doubleAttribute(_ name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .doubleAttributeType
    attribute.isOptional = false
    return attribute
}
