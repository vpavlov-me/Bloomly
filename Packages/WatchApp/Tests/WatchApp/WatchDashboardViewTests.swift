import CoreData
import XCTest
@testable import WatchApp
import Tracking

final class WatchDashboardViewTests: XCTestCase {
    func testLogInvokesOverride() {
        final class StubStore: WatchDataStore {
            private(set) var logged: EventKind?

            init() {
                let model = NSManagedObjectModel()
                let container = NSPersistentCloudKitContainer(name: "Stub", managedObjectModel: model)
                super.init(container: container)
            }

            override func log(kind: EventKind) {
                logged = kind
            }
        }

        let store = StubStore()
        let view = WatchDashboardView(store: store)
        store.log(kind: .sleep)
        XCTAssertEqual(store.logged, .sleep)
        _ = view.body
    }
}
