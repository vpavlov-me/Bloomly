import XCTest
@testable import Paywall

final class PaywallViewModelTests: XCTestCase {
    func testLoadPopulatesProducts() async {
        let viewModel = PaywallViewModel(storeClient: StubStoreClient())
        await viewModel.load()
        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.state, .idle)
    }

    private struct StubStoreClient: StoreClient {
        func products() async throws -> [StoreProduct] {
            [StoreProduct(id: "1", displayName: "Monthly", description: "", displayPrice: "$1", period: .monthly)]
        }

        func purchase(_ product: StoreProduct) async throws -> StoreTransactionResult { .success }
        func restore() async throws -> StoreTransactionResult { .success }
    }
}
