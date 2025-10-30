import XCTest

final class BabyTrackUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons.count >= 1)
    }
}
