import XCTest
import SwiftUI
@testable import DesignSystem
import SnapshotTesting

final class DesignSystemTests: XCTestCase {
    func testSpacingValuesArePositive() {
        let spacing = BloomyTheme.spacing
        let values: [CGFloat] = [
            spacing.xxs,
            spacing.xs,
            spacing.sm,
            spacing.md,
            spacing.lg,
            spacing.xl
        ]
        XCTAssertTrue(values.allSatisfy { $0 > 0 })
    }

    #if os(iOS)
    func testHeadingSnapshot() {
        let view = Text("Bloomy")
            .font(BloomyTheme.typography.headline.font)
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }
    #endif
}
