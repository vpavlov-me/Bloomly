//
//  CloudKitSyncService.swift
//  BabyTrack
//
//  Orchestrates CloudKit sync for events and measurements.
//

import CloudKit
import Foundation
import Tracking
import Measurements

public final class CloudKitSyncService: SyncService {
    private let database: CKDatabase
    private let mapper: RecordMapper
    private let tracker: ChangeTracking
    private let zoneID: CKRecordZone.ID

    public init(
        database: CKDatabase = CKContainer.default().privateCloudDatabase,
        mapper: RecordMapper,
        tracker: ChangeTracking,
        zoneID: CKRecordZone.ID = CKRecordZone.ID(zoneName: "BabyTrackZone", ownerName: CKCurrentUserDefaultName)
    ) {
        self.database = database
        self.mapper = mapper
        self.tracker = tracker
        self.zoneID = zoneID
    }

    public func pullChanges() async throws {
        let query = CKQuery(recordType: "Event", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        try await database.run(operation: operation)
        // Placeholder: downstream integration with repositories happens in app layer.
    }

    public func pushPending() async throws {
        let events = try await tracker.pendingEvents()
        let measurements = try await tracker.pendingMeasurements()
        let eventRecords = events.map(mapper.record)
        let measurementRecords = measurements.map(mapper.record)
        let modifyOp = CKModifyRecordsOperation(recordsToSave: eventRecords + measurementRecords, recordIDsToDelete: nil)
        modifyOp.savePolicy = .changedKeys
        try await database.run(operation: modifyOp)
        try await tracker.markSynced(eventIDs: events.map(\.id))
        try await tracker.markSynced(measurementIDs: measurements.map(\.id))
    }

    public func resolveConflicts(strategy: ConflictStrategy) async throws {
        guard strategy == .lastWriteWins else { return }
        // Last-write-wins provided by CloudKit record change tags, so no-op for scaffold.
    }
}

private extension CKDatabase {
    func run(operation: CKDatabaseOperation) async throws {
        try await withCheckedThrowingContinuation { continuation in
            if let modifyOperation = operation as? CKModifyRecordsOperation {
                modifyOperation.modifyRecordsCompletionBlock = { _, _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } else if let queryOperation = operation as? CKQueryOperation {
                queryOperation.queryCompletionBlock = { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } else {
                operation.completionBlock = {
                    continuation.resume(returning: ())
                }
            }
            add(operation)
        }
    }
}
