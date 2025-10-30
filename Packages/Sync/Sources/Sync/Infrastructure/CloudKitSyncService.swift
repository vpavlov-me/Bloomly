import CloudKit
import CoreData
import Foundation
import Measurements
import os.log
import Tracking

#if canImport(UIKit) && !os(watchOS)
import BackgroundTasks
#endif

public actor CloudKitSyncService: SyncService {
    private enum RecordType: String {
        case event = "Event"
        case measurement = "Measurement"
    }

    private struct ZoneChanges {
        let records: [CKRecord]
        let deletions: [CKRecord.ID]
        let token: CKServerChangeToken?
    }

    private struct PendingChanges {
        var recordsToSave: [CKRecord]
        var recordIDsToDelete: [CKRecord.ID]
        var eventObjectIDs: [NSManagedObjectID]
        var measurementObjectIDs: [NSManagedObjectID]
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let persistentContainer: NSPersistentContainer
    private let tokenStore: CloudKitTokenStore
    private let logger = Logger(subsystem: "com.vibecoding.bloomly", category: "Sync")
    private let zoneID = CKRecordZone.ID(zoneName: "BloomlyZone", ownerName: CKCurrentUserDefaultName)
    private let backgroundTaskIdentifier = "com.vibecoding.bloomly.sync"

    private let changeTokenKey: String
    private let zoneCreatedKey: String

    public init(
        containerIdentifier: String = "iCloud.com.vibecoding.bloomly",
        persistentContainer: NSPersistentContainer,
        tokenStore: CloudKitTokenStore = UserDefaultsTokenStore(),
        database: CKDatabase? = nil
    ) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = database ?? container.privateCloudDatabase
        self.persistentContainer = persistentContainer
        self.tokenStore = tokenStore
        self.changeTokenKey = "CloudKitSyncService.changeToken.\(containerIdentifier)"
        self.zoneCreatedKey = "CloudKitSyncService.zoneCreated.\(containerIdentifier)"
    }

    // MARK: - SyncService

    public func pullChanges() async {
        do {
            try await ensureZoneExists()
            let changes = try await fetchZoneChanges()

            guard !changes.records.isEmpty || !changes.deletions.isEmpty else {
                logger.info("CloudKit pull finished — no remote changes")
                if let token = changes.token {
                    changeToken = token
                }
                return
            }

            try await applyRemoteChanges(changes.records, deletions: changes.deletions)
            if let token = changes.token {
                changeToken = token
            }
            logger.info("CloudKit pull applied \(changes.records.count) records and \(changes.deletions.count) deletions")
        } catch let error as CKError where error.code == .changeTokenExpired {
            logger.error("CloudKit change token expired — resetting token and retrying pull")
            changeToken = nil
            await pullChanges()
        } catch {
            logger.error("CloudKit pull failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func pushPending() async {
        do {
            try await ensureZoneExists()
            let changes = try await fetchPendingChanges()

            guard !changes.recordsToSave.isEmpty || !changes.recordIDsToDelete.isEmpty else {
                logger.info("CloudKit push skipped — no pending local changes")
                return
            }

            try await modifyRecords(recordsToSave: changes.recordsToSave, recordIDsToDelete: changes.recordIDsToDelete)
            try await markChangesAsSynced(changes)
            logger.info("CloudKit push completed — saved \(changes.recordsToSave.count) records, deleted \(changes.recordIDsToDelete.count)")
        } catch {
            logger.error("CloudKit push failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func resolveConflicts(_ strategy: ConflictResolutionStrategy) async {
        switch strategy {
        case .lastWriteWins:
            logger.info("Resolving CloudKit conflicts with last-write-wins strategy")
            await pullChanges()
            await pushPending()
        }
    }

    public func registerBackgroundSync() {
        #if canImport(UIKit) && !os(watchOS)
        Task { @MainActor in
            let identifier = backgroundTaskIdentifier
            BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
                guard let refreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                self.handleBackgroundTask(refreshTask)
            }
            scheduleBackgroundSync()
        }
        #endif
    }

    // MARK: - Zone & Token Management

    private var changeToken: CKServerChangeToken? {
        get { tokenStore.serverChangeToken(forKey: changeTokenKey) }
        set { tokenStore.setServerChangeToken(newValue, forKey: changeTokenKey) }
    }

    private var zoneCreated: Bool {
        get { tokenStore.bool(forKey: zoneCreatedKey) }
        set { tokenStore.set(newValue, forKey: zoneCreatedKey) }
    }

    private func ensureZoneExists() async throws {
        guard !zoneCreated else { return }

        let database = self.database
        let zoneID = self.zoneID
        let logger = self.logger

        try await withCheckedThrowingContinuation { continuation in
            let zone = CKRecordZone(zoneID: zoneID)
            let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
            operation.qualityOfService = .userInitiated
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    logger.info("CloudKit zone ensured")
                    Task { await self.setZoneCreatedFlag(true) }
                    continuation.resume()
                case .failure(let error):
                    if let ckError = error as? CKError, ckError.code == .zoneAlreadyExists {
                        logger.info("CloudKit zone already exists")
                        Task { await self.setZoneCreatedFlag(true) }
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
            database.add(operation)
        }
    }

    private func fetchZoneChanges() async throws -> ZoneChanges {
        let database = self.database
        let zoneID = self.zoneID
        let logger = self.logger
        let previousToken = changeToken

        return try await withCheckedThrowingContinuation { continuation in
            let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: previousToken)
            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zoneID],
                configurationsByRecordZoneID: [zoneID: configuration]
            )
            operation.fetchAllChanges = true
            operation.qualityOfService = .userInitiated

            var changedRecords: [CKRecord] = []
            var deletedRecordIDs: [CKRecord.ID] = []
            var newToken: CKServerChangeToken?

            operation.recordWasChangedBlock = { _, result in
                switch result {
                case .success(let record):
                    changedRecords.append(record)
                case .failure(let error):
                    logger.error("Failed to fetch changed record: \(error.localizedDescription, privacy: .public)")
                }
            }

            operation.recordWithIDWasDeletedBlock = { recordID, _ in
                deletedRecordIDs.append(recordID)
            }

            operation.recordZoneFetchResultBlock = { _, result in
                switch result {
                case .success(let metadata):
                    newToken = metadata.serverChangeToken
                case .failure(let error):
                    logger.error("Zone fetch result error: \(error.localizedDescription, privacy: .public)")
                }
            }

            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ZoneChanges(
                        records: changedRecords,
                        deletions: deletedRecordIDs,
                        token: newToken
                    ))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            database.add(operation)
        }
    }

    // MARK: - Apply Pull Results

    private func applyRemoteChanges(_ records: [CKRecord], deletions: [CKRecord.ID]) async throws {
        try await performBackgroundTask { context in
            let logger = self.logger

            for record in records {
                switch RecordType(rawValue: record.recordType) {
                case .event:
                    try upsertEventRecord(record, in: context)
                case .measurement:
                    try upsertMeasurementRecord(record, in: context)
                case .none:
                    logger.debug("Skipping unsupported record type: \(record.recordType, privacy: .public)")
                }
            }

            for recordID in deletions {
                try handleDeletion(recordID, in: context)
            }
        }
    }

    nonisolated private func upsertEventRecord(_ record: CKRecord, in context: NSManagedObjectContext) throws {
        guard
            let uuid = UUID(uuidString: record.recordID.recordName),
            let kindString = record["kind"] as? String,
            let kind = EventKind(rawValue: kindString),
            let start = record["start"] as? Date,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return
        }

        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Event")
        fetch.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        fetch.fetchLimit = 1

        let object = try context.fetch(fetch).first ?? NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
        object.setValue(uuid, forKey: "id")
        object.setValue(kind.rawValue, forKey: "kind")
        object.setValue(start, forKey: "start")
        object.setValue(record["end"] as? Date, forKey: "end")
        object.setValue(record["notes"] as? String, forKey: "notes")
        object.setValue(createdAt, forKey: "createdAt")
        object.setValue(updatedAt, forKey: "updatedAt")
        object.setValue(record["isDeleted"] as? Bool ?? false, forKey: "isDeleted")
        object.setValue(true, forKey: "isSynced")
    }

    nonisolated private func upsertMeasurementRecord(_ record: CKRecord, in context: NSManagedObjectContext) throws {
        guard
            let uuid = UUID(uuidString: record.recordID.recordName),
            let typeString = record["type"] as? String,
            let type = MeasurementType(rawValue: typeString),
            let value = record["value"] as? Double,
            let unit = record["unit"] as? String,
            let date = record["date"] as? Date
        else {
            return
        }

        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        fetch.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        fetch.fetchLimit = 1

        let object = try context.fetch(fetch).first ?? NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        object.setValue(uuid, forKey: "id")
        object.setValue(type.rawValue, forKey: "type")
        object.setValue(value, forKey: "value")
        object.setValue(unit, forKey: "unit")
        object.setValue(date, forKey: "date")
        object.setValue(record["notes"] as? String, forKey: "notes")
        object.setValue(true, forKey: "isSynced")
    }

    nonisolated private func handleDeletion(_ recordID: CKRecord.ID, in context: NSManagedObjectContext) throws {
        guard let uuid = UUID(uuidString: recordID.recordName) else { return }

        if try markEventDeleted(uuid, in: context) {
            return
        }

        let measurementFetch = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        measurementFetch.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        measurementFetch.fetchLimit = 1
        if let measurement = try context.fetch(measurementFetch).first {
            context.delete(measurement)
        }
    }

    nonisolated private func markEventDeleted(_ id: UUID, in context: NSManagedObjectContext) throws -> Bool {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Event")
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetch.fetchLimit = 1

        guard let event = try context.fetch(fetch).first else {
            return false
        }

        event.setValue(true, forKey: "isDeleted")
        event.setValue(true, forKey: "isSynced")
        event.setValue(Date(), forKey: "updatedAt")
        return true
    }

    private func setZoneCreatedFlag(_ value: Bool) {
        zoneCreated = value
    }

    // MARK: - Push Helpers

    private func fetchPendingChanges() async throws -> PendingChanges {
        try await performBackgroundTask { context in
            var recordsToSave: [CKRecord] = []
            var recordIDsToDelete: [CKRecord.ID] = []
            var eventObjectIDs: [NSManagedObjectID] = []
            var measurementObjectIDs: [NSManagedObjectID] = []

            let eventRequest = NSFetchRequest<NSManagedObject>(entityName: "Event")
            eventRequest.predicate = NSPredicate(format: "isSynced == NO")
            let unsyncedEvents = try context.fetch(eventRequest)

            for object in unsyncedEvents {
                guard let uuid = object.value(forKey: "id") as? UUID,
                      let kind = object.value(forKey: "kind") as? String,
                      let start = object.value(forKey: "start") as? Date,
                      let createdAt = object.value(forKey: "createdAt") as? Date
                else { continue }

                let isDeleted = object.value(forKey: "isDeleted") as? Bool ?? false
                eventObjectIDs.append(object.objectID)

                let recordID = CKRecord.ID(recordName: uuid.uuidString, zoneID: zoneID)

                if isDeleted {
                    recordIDsToDelete.append(recordID)
                    continue
                }

                let record = CKRecord(recordType: RecordType.event.rawValue, recordID: recordID)
                record["kind"] = kind as CKRecordValue
                record["start"] = start as CKRecordValue
                record["end"] = object.value(forKey: "end") as? Date
                record["notes"] = object.value(forKey: "notes") as? String
                record["createdAt"] = createdAt as CKRecordValue
                record["updatedAt"] = (object.value(forKey: "updatedAt") as? Date ?? Date()) as CKRecordValue
                record["isDeleted"] = isDeleted as CKRecordValue
                recordsToSave.append(record)
            }

            let measurementRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
            measurementRequest.predicate = NSPredicate(format: "isSynced == NO")
            let unsyncedMeasurements = try context.fetch(measurementRequest)

            for object in unsyncedMeasurements {
                guard let uuid = object.value(forKey: "id") as? UUID,
                      let type = object.value(forKey: "type") as? String,
                      let value = object.value(forKey: "value") as? Double,
                      let unit = object.value(forKey: "unit") as? String,
                      let date = object.value(forKey: "date") as? Date
                else { continue }

                measurementObjectIDs.append(object.objectID)

                let recordID = CKRecord.ID(recordName: uuid.uuidString, zoneID: zoneID)
                let record = CKRecord(recordType: RecordType.measurement.rawValue, recordID: recordID)
                record["type"] = type as CKRecordValue
                record["value"] = value as CKRecordValue
                record["unit"] = unit as CKRecordValue
                record["date"] = date as CKRecordValue
                record["notes"] = object.value(forKey: "notes") as? String
                recordsToSave.append(record)
            }

            return PendingChanges(
                recordsToSave: recordsToSave,
                recordIDsToDelete: recordIDsToDelete,
                eventObjectIDs: eventObjectIDs,
                measurementObjectIDs: measurementObjectIDs
            )
        }
    }

    private func modifyRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecord.ID]) async throws {
        let database = self.database
        let logger = self.logger

        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    logger.error("Modify records failed: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    private func markChangesAsSynced(_ changes: PendingChanges) async throws {
        try await performBackgroundTask { context in
            for objectID in changes.eventObjectIDs {
                if let object = try? context.existingObject(with: objectID) {
                    object.setValue(true, forKey: "isSynced")
                }
            }

            for objectID in changes.measurementObjectIDs {
                if let object = try? context.existingObject(with: objectID) {
                    object.setValue(true, forKey: "isSynced")
                }
            }
        }
    }

    // MARK: - Core Data Helpers

    private func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = persistentContainer.newBackgroundContext()
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let result = try block(context)
                    try context.saveIfNeeded()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    #if canImport(UIKit) && !os(watchOS)
    private func scheduleBackgroundSync() {
        let logger = self.logger
        let identifier = backgroundTaskIdentifier

        Task { @MainActor in
            let request = BGAppRefreshTaskRequest(identifier: identifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
            do {
                try BGTaskScheduler.shared.submit(request)
                logger.info("Scheduled background CloudKit sync")
            } catch {
                logger.error("Failed to schedule background sync: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        scheduleBackgroundSync()

        task.expirationHandler = {
            Task { @MainActor in
                task.setTaskCompleted(success: false)
            }
        }

        Task {
            await self.pullChanges()
            await self.pushPending()
            await MainActor.run {
                task.setTaskCompleted(success: true)
            }
        }
    }
    #endif
}

private extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}
