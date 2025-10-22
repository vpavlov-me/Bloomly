import Combine
import XCTest
import Tracking
@testable import WatchApp

final class WatchDataStoreTests: XCTestCase {
    func testLogAddsEvent() async {
        let repository = InMemoryEventsRepository()
        let store = await MainActor.run { WatchDataStore(eventsRepository: repository) }
        let expectation = expectation(description: "recent events updated")

        var cancellable: AnyCancellable?
        await MainActor.run {
            cancellable = store.$recentEvents
                .dropFirst()
                .sink { events in
                    if !events.isEmpty {
                        expectation.fulfill()
                    }
                }
            store.log(draft: EventDraft(kind: .feed, start: Date()))
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(await MainActor.run { store.recentEvents.count }, 1)
        cancellable?.cancel()
    }
}
