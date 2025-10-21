import XCTest
@testable import Widgets

final class WidgetEntryTests: XCTestCase {
    func testEntryStoresValues() {
        let entry = BabyTrackEntry(date: Date(), lastFeed: "1h", sleepSummary: "6h")
        XCTAssertEqual(entry.lastFeed, "1h")
        XCTAssertEqual(entry.sleepSummary, "6h")
    }
}
