import XCTest
import Tracking
@testable import WatchApp

final class WatchDataStoreTests: XCTestCase {
    func testLogAddsEvent() async {
        let repository = InMemoryEventsRepository()
        let store = await MainActor.run { WatchDataStore(repository: repository) }
        await MainActor.run {
            store.log(draft: EventDraft(kind: .feed, start: Date()))
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        await MainActor.run {
            XCTAssertEqual(store.recentEvents.count, 1)
        }
    }
}
