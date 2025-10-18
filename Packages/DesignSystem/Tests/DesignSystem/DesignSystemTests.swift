import XCTest
import SwiftUI
@testable import DesignSystem
import SnapshotTesting

final class DesignSystemTests: XCTestCase {
    func testSpacingValuesArePositive() {
        XCTAssertTrue(BabyTrackSpacing.allCases.allSatisfy { $0.rawValue > 0 })
    }

    #if os(iOS)
    func testHeadingSnapshot() {
        let view = Text("BabyTrack").font(BabyTrackFont.heading(24))
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }
    #endif
}
