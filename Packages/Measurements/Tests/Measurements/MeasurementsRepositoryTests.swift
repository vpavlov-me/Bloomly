import CoreData
import XCTest
@testable import Measurements

final class MeasurementsRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: CoreDataMeasurementsRepository!

    override func setUpWithError() throws {
        container = NSPersistentContainer(name: "MeasurementModel", managedObjectModel: Self.model)
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
        repository = CoreDataMeasurementsRepository(context: container.viewContext)
    }

    func testUpsertStoresMeasurement() async throws {
        let input = MeasurementInput(
            type: .weight,
            value: 5.2,
            unit: "kg",
            date: Date(),
            isSynced: false
        )
        try await repository.upsert(input)
        let samples = try await repository.measurements(of: .weight)
        XCTAssertEqual(samples.count, 1)
        XCTAssertEqual(samples.first?.value, 5.2, accuracy: 0.001)
    }

    func testUnitConversion() {
        let service = WHOChartingService()
        XCTAssertEqual(service.convert(value: 1, from: "kg", to: "lbs"), 2.20462, accuracy: 0.0001)
    }

    private static var model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Measurement"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        let attributes: [String: NSAttributeType] = [
            "id": .UUIDAttributeType,
            "type": .stringAttributeType,
            "value": .doubleAttributeType,
            "unit": .stringAttributeType,
            "date": .dateAttributeType,
            "isSynced": .booleanAttributeType
        ]
        entity.properties = attributes.map { key, type in
            let attribute = NSAttributeDescription()
            attribute.name = key
            attribute.attributeType = type
            attribute.isOptional = key == "isSynced" ? true : false
            if key == "isSynced" { attribute.defaultValue = false }
            return attribute
        }
        model.entities = [entity]
        return model
    }()
}
