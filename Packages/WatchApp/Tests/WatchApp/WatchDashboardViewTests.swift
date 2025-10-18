import XCTest
@testable import WatchApp
import Tracking

final class WatchDashboardViewTests: XCTestCase {
    func testTriggerInvokesAction() {
        var invokedKind: EventKind?
        var view = WatchDashboardView(events: []) { kind in
            invokedKind = kind
        }
        view.trigger(kind: .sleep)
        XCTAssertEqual(invokedKind, .sleep)
    }
}
