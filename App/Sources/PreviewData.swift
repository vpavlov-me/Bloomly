//
//  PreviewData.swift
//  BabyTrack
//
//  Supplies preview fixtures for SwiftUI views.
//

import Foundation
import Tracking
import Measurements

enum PreviewData {
    static let events: [Event] = [
        Event(
            id: UUID(),
            kind: .feed,
            start: Date().addingTimeInterval(-3600),
            end: Date().addingTimeInterval(-1800),
            notes: "Bottle 120ml",
            createdAt: Date(),
            updatedAt: Date(),
            isSynced: false
        )
    ]

    static let measurements: [MeasurementSample] = [
        MeasurementSample(
            id: UUID(),
            type: .weight,
            value: 5.6,
            unit: "kg",
            date: Date(),
            isSynced: false
        )
    ]

    static let growthSamples: [GrowthChartSample] = [
        GrowthChartSample(type: .weight, month: 0, value: 3.2),
        GrowthChartSample(type: .weight, month: 3, value: 5.4),
        GrowthChartSample(type: .height, month: 0, value: 49.0),
        GrowthChartSample(type: .height, month: 3, value: 61.0)
    ]
}
