import CoreData
import XCTest
@testable import Measurements

final class MeasurementsRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: CoreDataMeasurementsRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = makeContainer()
        repository = CoreDataMeasurementsRepository(context: container.viewContext)
    }

    override func tearDownWithError() throws {
        container = nil
        repository = nil
        try super.tearDownWithError()
    }

    func testSaveAndFetchWeight() async throws {
        let draft = MeasurementDraft(type: .weight, value: 5.2, unit: "kg", date: Date())
        let saved = try await repository.save(draft: draft)
        XCTAssertEqual(saved.value, 5.2)

        let fetched = try await repository.fetchMeasurements(for: .weight, limit: 1)
        XCTAssertEqual(fetched.first?.id, saved.id)
    }

    func testStreamYieldsInitialData() async throws {
        let expectation = expectation(description: "stream")
        let stream = repository.measurementsStream(for: .height)
        Task {
            for await items in stream {
                if items.isEmpty {
                    expectation.fulfill()
                }
                break
            }
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    private func makeContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Measurement"
        entity.managedObjectClassName = "MeasurementEntity"

        let attributes: [NSAttributeDescription] = [
            uuidAttribute(name: "id"),
            stringAttribute(name: "type"),
            doubleAttribute(name: "value"),
            stringAttribute(name: "unit"),
            dateAttribute(name: "date"),
            boolAttribute(name: "isSynced")
        ]
        entity.properties = attributes
        model.entities = [entity]

        let container = NSPersistentContainer(name: "BabyTrackModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Store failed: \(error)")
            }
        }
        return container
    }
}

private func uuidAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .UUIDAttributeType
    attribute.isOptional = false
    return attribute
}

private func stringAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .stringAttributeType
    attribute.isOptional = false
    return attribute
}

private func doubleAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .doubleAttributeType
    attribute.isOptional = false
    return attribute
}

private func dateAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .dateAttributeType
    attribute.isOptional = false
    return attribute
}

private func boolAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .booleanAttributeType
    attribute.isOptional = false
    attribute.defaultValue = false
    return attribute
}
