import XCTest
@testable import Content

final class ContentStringsTests: XCTestCase {
    func testLocalizedReturnsKeyWhenMissing() {
        XCTAssertEqual(ContentStrings.localized("missing.key"), "missing.key")
    }
}
