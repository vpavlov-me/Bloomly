import CoreData
import XCTest
@testable import Tracking

final class BabyRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: CoreDataBabyRepository!

    override func setUpWithError() throws {
        container = NSPersistentContainer(name: "BabyModel", managedObjectModel: Self.model)
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

        repository = CoreDataBabyRepository(context: container.viewContext)
    }

    override func tearDownWithError() throws {
        repository = nil
        container = nil
    }

    // MARK: - Create Tests

    func testCreateBaby() async throws {
        let baby = BabyDTO(
            name: "Alice",
            birthDate: Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        )

        let created = try await repository.create(baby)

        XCTAssertEqual(created.name, "Alice")
        XCTAssertEqual(created.birthDate, baby.birthDate)
        XCTAssertNotNil(created.id)
    }

    func testCreateBabyWithPhoto() async throws {
        // Create a simple 1x1 pixel image data
        let photoData = createTestImageData()

        let baby = BabyDTO(
            name: "Bob",
            birthDate: Date().addingTimeInterval(-60 * 24 * 60 * 60), // 60 days ago
            photoData: photoData
        )

        let created = try await repository.create(baby)

        XCTAssertEqual(created.name, "Bob")
        XCTAssertNotNil(created.photoData)
        // Photo should be processed (compressed)
        XCTAssertTrue((created.photoData?.count ?? 0) > 0)
    }

    func testCreateBabyWithEmptyName() async throws {
        let baby = BabyDTO(
            name: "",
            birthDate: Date()
        )

        do {
            _ = try await repository.create(baby)
            XCTFail("Should throw validation error")
        } catch BabyRepositoryError.validationFailed {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testCreateBabyWithFutureBirthDate() async throws {
        let baby = BabyDTO(
            name: "Charlie",
            birthDate: Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
        )

        do {
            _ = try await repository.create(baby)
            XCTFail("Should throw validation error")
        } catch BabyRepositoryError.validationFailed {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Read Tests

    func testReadBaby() async throws {
        let baby = BabyDTO(name: "David", birthDate: Date())
        let created = try await repository.create(baby)

        let read = try await repository.read(id: created.id)

        XCTAssertEqual(read.id, created.id)
        XCTAssertEqual(read.name, "David")
    }

    func testReadNonExistentBaby() async throws {
        do {
            _ = try await repository.read(id: UUID())
            XCTFail("Should throw notFound error")
        } catch BabyRepositoryError.notFound {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Update Tests

    func testUpdateBaby() async throws {
        let baby = BabyDTO(name: "Eve", birthDate: Date())
        let created = try await repository.create(baby)

        var updated = created
        updated.name = "Eve Updated"

        let result = try await repository.update(updated)

        XCTAssertEqual(result.id, created.id)
        XCTAssertEqual(result.name, "Eve Updated")
        XCTAssertNotEqual(result.updatedAt, created.updatedAt)
    }

    func testUpdateBabyPhoto() async throws {
        let baby = BabyDTO(name: "Frank", birthDate: Date())
        let created = try await repository.create(baby)

        var updated = created
        updated.photoData = createTestImageData()

        let result = try await repository.update(updated)

        XCTAssertNotNil(result.photoData)
    }

    func testUpdateNonExistentBaby() async throws {
        let baby = BabyDTO(id: UUID(), name: "Ghost", birthDate: Date())

        do {
            _ = try await repository.update(baby)
            XCTFail("Should throw notFound error")
        } catch BabyRepositoryError.notFound {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Delete Tests

    func testDeleteBaby() async throws {
        let baby = BabyDTO(name: "Grace", birthDate: Date())
        let created = try await repository.create(baby)

        try await repository.delete(id: created.id)

        do {
            _ = try await repository.read(id: created.id)
            XCTFail("Baby should be deleted")
        } catch BabyRepositoryError.notFound {
            // Expected
        }
    }

    func testDeleteNonExistentBaby() async throws {
        do {
            try await repository.delete(id: UUID())
            XCTFail("Should throw notFound error")
        } catch BabyRepositoryError.notFound {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Fetch All Tests

    func testFetchAllBabies() async throws {
        let baby1 = BabyDTO(name: "Hannah", birthDate: Date())
        let baby2 = BabyDTO(name: "Isaac", birthDate: Date())

        _ = try await repository.create(baby1)
        _ = try await repository.create(baby2)

        let all = try await repository.fetchAll()

        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains { $0.name == "Hannah" })
        XCTAssertTrue(all.contains { $0.name == "Isaac" })
    }

    func testFetchAllWhenEmpty() async throws {
        let all = try await repository.fetchAll()
        XCTAssertEqual(all.count, 0)
    }

    // MARK: - Fetch Active Tests

    func testFetchActiveBaby() async throws {
        let baby = BabyDTO(name: "Jack", birthDate: Date())
        let created = try await repository.create(baby)

        let active = try await repository.fetchActive()

        XCTAssertNotNil(active)
        XCTAssertEqual(active?.id, created.id)
        XCTAssertEqual(active?.name, "Jack")
    }

    func testFetchActiveWhenMultipleBabiesReturnsFirst() async throws {
        let baby1 = BabyDTO(name: "Kate", birthDate: Date())
        let baby2 = BabyDTO(name: "Liam", birthDate: Date())

        let created1 = try await repository.create(baby1)
        _ = try await repository.create(baby2)

        let active = try await repository.fetchActive()

        XCTAssertNotNil(active)
        XCTAssertEqual(active?.id, created1.id)
        XCTAssertEqual(active?.name, "Kate")
    }

    func testFetchActiveWhenEmpty() async throws {
        let active = try await repository.fetchActive()
        XCTAssertNil(active)
    }

    // MARK: - BabyDTO Tests

    func testBabyAgeInMonths() {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let baby = BabyDTO(name: "Test", birthDate: threeMonthsAgo)

        XCTAssertEqual(baby.ageInMonths, 3)
    }

    func testBabyAgeInDays() {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let baby = BabyDTO(name: "Test", birthDate: tenDaysAgo)

        XCTAssertEqual(baby.ageInDays, 10)
    }

    func testBabyFormattedAge() {
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let baby1 = BabyDTO(name: "Test", birthDate: twoYearsAgo)
        XCTAssertEqual(baby1.formattedAge, "2 years")

        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let baby2 = BabyDTO(name: "Test", birthDate: threeMonthsAgo)
        XCTAssertEqual(baby2.formattedAge, "3 months")

        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let baby3 = BabyDTO(name: "Test", birthDate: tenDaysAgo)
        XCTAssertEqual(baby3.formattedAge, "1 week")
    }

    // MARK: - Helper Methods

    private func createTestImageData() -> Data {
        #if canImport(UIKit)
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image.jpegData(compressionQuality: 1.0)!
        #elseif canImport(AppKit)
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let tiffData = image.tiffRepresentation!
        let bitmap = NSBitmapImageRep(data: tiffData)!
        return bitmap.representation(using: .jpeg, properties: [:])!
        #else
        return Data()
        #endif
    }

    // MARK: - Core Data Model

    private static var model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Baby"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let attributes: [String: NSAttributeType] = [
            "id": .UUIDAttributeType,
            "name": .stringAttributeType,
            "birthDate": .dateAttributeType,
            "photoData": .binaryDataAttributeType,
            "createdAt": .dateAttributeType,
            "updatedAt": .dateAttributeType
        ]

        entity.properties = attributes.map { name, type in
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = (name == "photoData")
            return attribute
        }

        model.entities = [entity]
        return model
    }()
}
