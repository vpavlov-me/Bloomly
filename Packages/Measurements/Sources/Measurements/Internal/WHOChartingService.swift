//
//  WHOChartingService.swift
//  BabyTrack
//
//  Interpolates WHO percentile curves for growth charts.
//

import Foundation

public final class WHOChartingService: GrowthChartingService {
    public enum UnitConverter {
        public static func kilogramsToPounds(_ value: Double) -> Double {
            value * 2.20462
        }

        public static func poundsToKilograms(_ value: Double) -> Double {
            value / 2.20462
        }

        public static func centimetersToInches(_ value: Double) -> Double {
            value / 2.54
        }

        public static func inchesToCentimeters(_ value: Double) -> Double {
            value * 2.54
        }
    }

    private let percentileTable: [MeasurementType: [Double: [Double]]]

    public init(percentileTable: [MeasurementType: [Double: [Double]]] = Self.defaultTable) {
        self.percentileTable = percentileTable
    }

    public func percentile(for type: MeasurementType, ageInMonths: Double, value: Double) -> Double? {
        guard let table = percentileTable[type] else { return nil }
        let sortedAges = table.keys.sorted()
        guard let lowerAge = sortedAges.last(where: { $0 <= ageInMonths }), let upperAge = sortedAges.first(where: { $0 >= ageInMonths }) else {
            return nil
        }
        let percentiles = stride(from: 3.0, through: 97.0, by: 1.0).map { $0 }
        let lowerValues = table[lowerAge] ?? []
        let upperValues = table[upperAge] ?? []
        guard lowerValues.count == upperValues.count, lowerValues.count == percentiles.count else { return nil }
        let ageRatio = upperAge == lowerAge ? 0 : (ageInMonths - lowerAge) / (upperAge - lowerAge)
        for index in percentiles.indices {
            let interpolatedValue = lowerValues[index] + (upperValues[index] - lowerValues[index]) * ageRatio
            if value <= interpolatedValue {
                return percentiles[index]
            }
        }
        return percentiles.last
    }

    public func convert(value: Double, from unit: String, to target: String) -> Double {
        switch (unit.lowercased(), target.lowercased()) {
        case ("kg", "lbs"): return UnitConverter.kilogramsToPounds(value)
        case ("lbs", "kg"): return UnitConverter.poundsToKilograms(value)
        case ("cm", "in"): return UnitConverter.centimetersToInches(value)
        case ("in", "cm"): return UnitConverter.inchesToCentimeters(value)
        default: return value
        }
    }

    private static let defaultTable: [MeasurementType: [Double: [Double]]] = [
        .weight: [
            0: Array(stride(from: 3.0, through: 97.0, by: 1.0)),
            6: Array(stride(from: 3.5, through: 97.5, by: 1.0))
        ],
        .height: [
            0: Array(stride(from: 45.0, through: 75.0, by: 1.0)),
            6: Array(stride(from: 55.0, through: 85.0, by: 1.0))
        ],
        .head: [
            0: Array(stride(from: 30.0, through: 40.0, by: 1.0)),
            6: Array(stride(from: 32.0, through: 42.0, by: 1.0))
        ]
    ]
}
