//
//  SyncContracts.swift
//  BabyTrack
//
//  Contracts for CloudKit synchronization pipeline.
//

import Foundation
import CloudKit
import Tracking
import Measurements

public protocol RecordMapper: Sendable {
    func record(for event: Event) -> CKRecord
    func record(for measurement: MeasurementSample) -> CKRecord
    func event(from record: CKRecord) throws -> Event
    func measurement(from record: CKRecord) throws -> MeasurementSample
}

public protocol ChangeTracking: Sendable {
    func markSynced(eventIDs: [UUID]) async throws
    func markSynced(measurementIDs: [UUID]) async throws
    func pendingEvents() async throws -> [Event]
    func pendingMeasurements() async throws -> [MeasurementSample]
}

public protocol SyncService: Sendable {
    func pullChanges() async throws
    func pushPending() async throws
    func resolveConflicts(strategy: ConflictStrategy) async throws
}

public enum ConflictStrategy: Sendable {
    case lastWriteWins
}
