import SnapshotTesting
import SwiftUI
import XCTest
@testable import Measurements

final class GrowthChartsViewTests: XCTestCase {
    private let isRecording = false

    func testChartsRendering() {
        let samples = stride(from: 0, through: 6, by: 1).map { offset -> MeasurementDTO in
            MeasurementDTO(type: .height, value: 50 + Double(offset) * 1.5, unit: "cm", date: Date().addingTimeInterval(Double(offset) * 86400))
        }
        let view = GrowthChartsView(measurements: samples, isPremium: true)
            .frame(width: 390, height: 300)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Mini)), record: isRecording)
    }
}
