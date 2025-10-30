import XCTest
@testable import Widgets

final class WidgetEntryTests: XCTestCase {
    func testEntryStoresValues() {
        let entry = SmallWidgetEntry(date: Date(), timeSinceLastFeed: "1h", lastFeedType: "Bottle")
        XCTAssertEqual(entry.timeSinceLastFeed, "1h")
        XCTAssertEqual(entry.lastFeedType, "Bottle")
    }
}
