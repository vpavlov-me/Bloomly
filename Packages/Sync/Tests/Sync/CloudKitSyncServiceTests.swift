import CloudKit
import XCTest
@testable import Sync

final class CloudKitSyncServiceTests: XCTestCase {
    func testPushPendingMarksSynced() async throws {
        let tracker = TrackerMock()
        let service = CloudKitSyncService(database: CKDatabaseMock(), mapper: MapperMock(), tracker: tracker)
        try await service.pushPending()
        XCTAssertTrue(tracker.markedEvents)
        XCTAssertTrue(tracker.markedMeasurements)
    }

    private final class MapperMock: RecordMapper {
        func record(for event: Tracking.Event) -> CKRecord { CKRecord(recordType: "Event") }
        func record(for measurement: Measurements.MeasurementSample) -> CKRecord { CKRecord(recordType: "Measurement") }
        func event(from record: CKRecord) throws -> Tracking.Event { throw NSError(domain: "", code: 0) }
        func measurement(from record: CKRecord) throws -> Measurements.MeasurementSample { throw NSError(domain: "", code: 0) }
    }

    private final class TrackerMock: ChangeTracking {
        var markedEvents = false
        var markedMeasurements = false

        func markSynced(eventIDs: [UUID]) async throws { markedEvents = true }
        func markSynced(measurementIDs: [UUID]) async throws { markedMeasurements = true }
        func pendingEvents() async throws -> [Tracking.Event] { [] }
        func pendingMeasurements() async throws -> [Measurements.MeasurementSample] { [] }
    }

    private final class CKDatabaseMock: CKDatabase {
        override func add(_ operation: CKDatabaseOperation) {
            if let modifyOperation = operation as? CKModifyRecordsOperation {
                modifyOperation.modifyRecordsCompletionBlock?(modifyOperation.recordsToSave ?? [], nil, nil)
            } else if let queryOperation = operation as? CKQueryOperation {
                queryOperation.queryCompletionBlock?(nil, nil)
            }
        }
    }
}
