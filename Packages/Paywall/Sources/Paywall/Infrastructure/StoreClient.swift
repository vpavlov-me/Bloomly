import Combine
import Foundation
import StoreKit
import SwiftUI

public struct StoreClient: Sendable {
    public var loadProducts: @Sendable () async throws -> [Product]
    public var purchase: @Sendable (_ productID: String) async throws -> Transaction?
    public var restore: @Sendable () async throws -> Transaction?
    public var isEntitled: @Sendable () async -> Bool

    public init(
        loadProducts: @escaping @Sendable () async throws -> [Product],
        purchase: @escaping @Sendable (_: String) async throws -> Transaction?,
        restore: @escaping @Sendable () async throws -> Transaction?,
        isEntitled: @escaping @Sendable () async -> Bool
    ) {
        self.loadProducts = loadProducts
        self.purchase = purchase
        self.restore = restore
        self.isEntitled = isEntitled
    }

    public static func live() -> StoreClient {
        StoreClient(
            loadProducts: {
                try await Product.products(for: ProductIDs.all)
            },
            purchase: { productID in
                let products = try await Product.products(for: [productID])
                guard let product = products.first else { return nil }
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try verification.payloadValue
                    await transaction.finish()
                    return transaction
                case .userCancelled, .pending: return nil
                @unknown default: return nil
                }
            },
            restore: {
                for await result in Transaction.currentEntitlements {
                    guard case .verified(let transaction) = result else { continue }
                    if ProductIDs.all.contains(transaction.productID) {
                        return transaction
                    }
                }
                return nil
            },
            isEntitled: {
                for await result in Transaction.currentEntitlements {
                    guard case .verified(let transaction) = result else { continue }
                    if ProductIDs.all.contains(transaction.productID) {
                        return true
                    }
                }
                return false
            }
        )
    }

    public static let mock = StoreClient(
        loadProducts: { [] },
        purchase: { _ in nil },
        restore: { nil },
        isEntitled: { false }
    )
}

@MainActor
public final class PremiumState: ObservableObject {
    @AppStorage("isPremium") private var storage: Bool = false
    @Published public private(set) var isPremium: Bool

    private var updatesTask: Task<Void, Never>?

    public init() {
        self.isPremium = storage
        observeTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    public func refresh(using client: StoreClient) async {
        let entitled = await client.isEntitled()
        updatePremium(entitled)
    }

    public func apply(transaction: Transaction?) {
        guard let transaction else { return }
        let entitled = ProductIDs.all.contains(transaction.productID)
        updatePremium(entitled)
    }

    private func updatePremium(_ value: Bool) {
        storage = value
        isPremium = value
    }

    private func observeTransactions() {
        updatesTask = Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if ProductIDs.all.contains(transaction.productID) {
                    updatePremium(true)
                }
            }
        }
    }
}
