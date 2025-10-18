//
//  DefaultRecordMapper.swift
//  BabyTrack
//
//  Maps between Core Data models and CloudKit records.
//

import CloudKit
import Foundation
import Tracking
import Measurements

public struct DefaultRecordMapper: RecordMapper {
    private enum Keys {
        static let id = "id"
        static let payload = "payload"
        static let updatedAt = "updatedAt"
    }

    public init() {}

    public func record(for event: Event) -> CKRecord {
        let recordID = CKRecord.ID(recordName: event.id.uuidString)
        let record = CKRecord(recordType: "Event", recordID: recordID)
        record[Keys.payload] = try? JSONEncoder().encode(event)
        record[Keys.updatedAt] = event.updatedAt as NSDate
        return record
    }

    public func record(for measurement: MeasurementSample) -> CKRecord {
        let recordID = CKRecord.ID(recordName: measurement.id.uuidString)
        let record = CKRecord(recordType: "Measurement", recordID: recordID)
        record[Keys.payload] = try? JSONEncoder().encode(measurement)
        record[Keys.updatedAt] = measurement.date as NSDate
        return record
    }

    public func event(from record: CKRecord) throws -> Event {
        guard
            let data = record[Keys.payload] as? Data
        else { throw MappingError.invalidPayload }
        return try JSONDecoder().decode(Event.self, from: data)
    }

    public func measurement(from record: CKRecord) throws -> MeasurementSample {
        guard
            let data = record[Keys.payload] as? Data
        else { throw MappingError.invalidPayload }
        return try JSONDecoder().decode(MeasurementSample.self, from: data)
    }

    private enum MappingError: Error {
        case invalidPayload
    }
}
