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
}
