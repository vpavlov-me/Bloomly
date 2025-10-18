//
//  MeasurementsRepository.swift
//  BabyTrack
//
//  Defines access to growth measurements and chart helpers.
//

import Foundation

public enum MeasurementType: String, Codable, Sendable {
    case height
    case weight
    case head
}

public struct MeasurementSample: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: MeasurementType
    public let value: Double
    public let unit: String
    public let date: Date
    public let isSynced: Bool

    public init(
        id: UUID,
        type: MeasurementType,
        value: Double,
        unit: String,
        date: Date,
        isSynced: Bool
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.date = date
        self.isSynced = isSynced
    }
}

public struct MeasurementInput: Sendable {
    public let id: UUID
    public let type: MeasurementType
    public let value: Double
    public let unit: String
    public let date: Date
    public let isSynced: Bool

    public init(
        id: UUID = UUID(),
        type: MeasurementType,
        value: Double,
        unit: String,
        date: Date,
        isSynced: Bool
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.date = date
        self.isSynced = isSynced
    }
}

public protocol MeasurementsRepository: Sendable {
    func measurements(of type: MeasurementType) async throws -> [MeasurementSample]
    func upsert(_ measurement: MeasurementInput) async throws
    func delete(id: UUID) async throws
}

public protocol GrowthChartingService: Sendable {
    func percentile(for type: MeasurementType, ageInMonths: Double, value: Double) -> Double?
    func convert(value: Double, from unit: String, to target: String) -> Double
}
