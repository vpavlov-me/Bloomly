import XCTest
@testable import Widgets

final class WidgetsTests: XCTestCase {
    func testSleepSummaryFormatting() {
        let formatted = SleepSummaryFormatter.format(duration: 3 * 3600 + 30 * 60)
        XCTAssertEqual(formatted, "3h 30m")
    }
}
