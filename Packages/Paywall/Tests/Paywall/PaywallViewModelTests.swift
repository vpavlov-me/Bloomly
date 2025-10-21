import StoreKit
import XCTest
@testable import Paywall

final class PaywallViewModelTests: XCTestCase {
    func testLoadWithoutProductsSetsError() async {
        let client = StubStoreClient(products: [], purchaseResult: nil, restoreTransactions: [])
        let viewModel = PaywallViewModel(storeClient: client)
        await MainActor.run { viewModel.load() }
        try? await Task.sleep(nanoseconds: 50_000_000)
        await MainActor.run {
            if case .error(.noProducts) = viewModel.state {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected noProducts error")
            }
        }
    }
}

private final class StubStoreClient: StoreClient {
    let productsResult: [Product]
    let purchaseResult: Result<Transaction, Error>?
    let restoreResult: [Transaction]

    init(products: [Product], purchaseResult: Result<Transaction, Error>?, restoreTransactions: [Transaction]) {
        self.productsResult = products
        self.purchaseResult = purchaseResult
        self.restoreResult = restoreTransactions
    }

    func products() async throws -> [Product] { productsResult }

    func purchase(_ product: Product) async throws -> Transaction {
        guard let purchaseResult else {
            throw StoreClientError.underlying("Unavailable")
        }
        return try purchaseResult.get()
    }

    func restore() async throws -> [Transaction] { restoreResult }
}
