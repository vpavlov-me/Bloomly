import XCTest

final class BloomyUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons.count >= 1)
    }
}
