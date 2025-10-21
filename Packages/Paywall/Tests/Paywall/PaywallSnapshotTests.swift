import SnapshotTesting
import SwiftUI
import XCTest
@testable import Paywall

final class PaywallSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    func testEmptyPaywallSnapshot() throws {
        let viewModel = PaywallViewModel(storeClient: StubStoreClient())
        let view = PaywallView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    private func referenceExists(for testName: String) -> Bool {
        let testClass = String(describing: type(of: self))
        let snapshotsPath = "__Snapshots__/\(testClass)/\(testName).png"
        return FileManager.default.fileExists(atPath: snapshotsPath)
    }
}

private final class StubStoreClient: StoreClient {
    func products() async throws -> [Product] { [] }
    func purchase(_ product: Product) async throws -> Transaction { throw StoreClientError.productMissing }
    func restore() async throws -> [Transaction] { [] }
}
