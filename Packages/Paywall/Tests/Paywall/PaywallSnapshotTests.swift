import XCTest
import SwiftUI
import SnapshotTesting
@testable import Paywall

final class PaywallSnapshotTests: XCTestCase {
    #if os(iOS)
    func testPaywallIdleSnapshot() {
        let viewModel = PaywallViewModel(storeClient: StubStoreClient())
        viewModel.overrideProductsForTesting([StoreProduct(id: "1", displayName: "Monthly", description: "", displayPrice: "$1.99", period: .monthly)])
        let view = PaywallView(viewModel: viewModel)
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }
    #endif

    private final class StubStoreClient: StoreClient {
        func products() async throws -> [StoreProduct] { [] }
        func purchase(_ product: StoreProduct) async throws -> StoreTransactionResult { .success }
        func restore() async throws -> StoreTransactionResult { .success }
    }
}
