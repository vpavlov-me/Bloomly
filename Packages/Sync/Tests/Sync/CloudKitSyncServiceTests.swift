import CloudKit
import CoreData
import XCTest
@testable import Sync

final class CloudKitSyncServiceTests: XCTestCase {
    func testPushPendingMarksEventsSynced() async throws {
        let container = makeContainer()
        try populateUnsyncedEvent(in: container.viewContext)

        let database = CKDatabaseMock()
        let tokenStore = InMemoryTokenStore()
        let service = CloudKitSyncService(
            persistentContainer: container,
            tokenStore: tokenStore,
            database: database
        )

        await service.pushPending()

        XCTAssertEqual(database.savedRecords.count, 1)
        XCTAssertEqual(database.recordIDsToDelete.count, 0)

        let events = try fetchEvents(in: container.viewContext)
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events.first?.value(forKey: "isSynced") as? Bool ?? false)
    }

    func testPullChangesCreatesLocalEvent() async throws {
        let container = makeContainer()
        let database = CKDatabaseMock()
        let tokenStore = InMemoryTokenStore()
        let service = CloudKitSyncService(
            persistentContainer: container,
            tokenStore: tokenStore,
            database: database
        )

        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: database.zoneID)
        let record = CKRecord(recordType: "Event", recordID: recordID)
        record["kind"] = "sleep" as CKRecordValue
        record["start"] = Date() as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["isDeleted"] = false as CKRecordValue
        database.suppliedRecords = [record]

        await service.pullChanges()

        let events = try fetchEvents(in: container.viewContext)
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events.first?.value(forKey: "isSynced") as? Bool ?? false)
    }

    func testPullChangesMarksEventDeleted() async throws {
        let container = makeContainer()
        let eventID = UUID()
        try populateEvent(id: eventID, in: container.viewContext)

        let database = CKDatabaseMock()
        database.suppliedDeletedIDs = [CKRecord.ID(recordName: eventID.uuidString, zoneID: database.zoneID)]

        let service = CloudKitSyncService(
            persistentContainer: container,
            tokenStore: InMemoryTokenStore(),
            database: database
        )

        await service.pullChanges()

        let events = try fetchEvents(in: container.viewContext)
        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events.first?.value(forKey: "isDeleted") as? Bool ?? false)
        XCTAssertTrue(events.first?.value(forKey: "isSynced") as? Bool ?? false)
    }

    // MARK: - Helpers

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
            boolAttribute("isDeleted"),
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
            stringAttribute("notes", optional: true),
            boolAttribute("isSynced")
        ]

        model.entities = [event, measurement]

        let container = NSPersistentContainer(name: "BabyTrackModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }
        return container
    }

    private func populateUnsyncedEvent(in context: NSManagedObjectContext) throws {
        var capturedError: Error?
        context.performAndWait {
            do {
                let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
                event.setValue(UUID(), forKey: "id")
                event.setValue("sleep", forKey: "kind")
                event.setValue(Date(), forKey: "start")
                event.setValue(Date(), forKey: "createdAt")
                event.setValue(Date(), forKey: "updatedAt")
                event.setValue(false, forKey: "isDeleted")
                event.setValue(false, forKey: "isSynced")
                try context.save()
            } catch {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
    }

    private func populateEvent(id: UUID, in context: NSManagedObjectContext) throws {
        var capturedError: Error?
        context.performAndWait {
            do {
                let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
                event.setValue(id, forKey: "id")
                event.setValue("sleep", forKey: "kind")
                event.setValue(Date(), forKey: "start")
                event.setValue(Date(), forKey: "createdAt")
                event.setValue(Date(), forKey: "updatedAt")
                event.setValue(false, forKey: "isDeleted")
                event.setValue(false, forKey: "isSynced")
                try context.save()
            } catch {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
    }

    private func fetchEvents(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        var result: Result<[NSManagedObject], Error> = .success([])
        context.performAndWait {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
                let events = try context.fetch(request)
                result = .success(events)
            } catch {
                result = .failure(error)
            }
        }
        return try result.get()
    }
}

// MARK: - Test Utilities

private final class InMemoryTokenStore: CloudKitTokenStore {
    var token: CKServerChangeToken?
    var flags: [String: Bool] = [:]

    func serverChangeToken(forKey key: String) -> CKServerChangeToken? { token }
    func setServerChangeToken(_ token: CKServerChangeToken?, forKey key: String) { self.token = token }
    func bool(forKey key: String) -> Bool { flags[key] ?? false }
    func set(_ value: Bool, forKey key: String) { flags[key] = value }
}

extension InMemoryTokenStore: @unchecked Sendable {}

private final class CKDatabaseMock: CKDatabase {
    let zoneID = CKRecordZone.ID(zoneName: "BabyTrackZone", ownerName: CKCurrentUserDefaultName)

    var savedRecords: [CKRecord] = []
    var recordIDsToDelete: [CKRecord.ID] = []
    var suppliedRecords: [CKRecord] = []
    var suppliedDeletedIDs: [CKRecord.ID] = []

    override func add(_ operation: CKDatabaseOperation) {
        switch operation {
        case let modifyZones as CKModifyRecordZonesOperation:
            modifyZones.modifyRecordZonesResultBlock?(.success(()))

        case let modifyRecords as CKModifyRecordsOperation:
            savedRecords = modifyRecords.recordsToSave ?? []
            recordIDsToDelete = modifyRecords.recordIDsToDelete ?? []
            modifyRecords.modifyRecordsResultBlock?(.success(()))

        case let fetchChanges as CKFetchRecordZoneChangesOperation:
            for record in suppliedRecords {
                fetchChanges.recordWasChangedBlock?(record.recordID, .success(record))
            }
            for recordID in suppliedDeletedIDs {
                fetchChanges.recordWithIDWasDeletedBlock?(recordID, "")
            }
            fetchChanges.fetchRecordZoneChangesResultBlock?(.success(()))

        default:
            break
        }
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
