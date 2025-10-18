import XCTest
@testable import BabyTrack

final class BabyTrackTests: XCTestCase {
    func testEnvironmentUsesSharedPersistence() {
        let environment = AppEnvironment()
        XCTAssertTrue(environment.persistenceController.container.persistentStoreDescriptions.isEmpty == false)
    }
}
