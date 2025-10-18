import XCTest
@testable import Content

final class LocalizationTests: XCTestCase {
    func testStringsArePresent() {
        XCTAssertFalse(L10n.paywallTitle().isEmpty)
        XCTAssertFalse(L10n.timelineEmptyState().isEmpty)
    }
}
