import XCTest
@testable import WatchApp
import Tracking

final class WatchDashboardViewTests: XCTestCase {
    func testViewInitialisesWithStore() async {
        let repository = InMemoryEventsRepository()
        let store = await MainActor.run { WatchDataStore(eventsRepository: repository) }
        let view = WatchDashboardView(store: store)
        _ = view.body
    }
}
