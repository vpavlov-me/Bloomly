import SnapshotTesting
import SwiftUI
import XCTest
@testable import Measurements

final class GrowthChartViewTests: XCTestCase {
    #if os(iOS)
    func testChartFallback() {
        let view = GrowthChartView(samples: [], showCharts: true)
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }
    #endif
}
