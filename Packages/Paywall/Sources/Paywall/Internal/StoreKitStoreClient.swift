//
//  StoreKitStoreClient.swift
//  BabyTrack
//
//  StoreKit 2 backed implementation.
//

import Foundation
import StoreKit

public final class StoreKitStoreClient: StoreClient {
    private let productIds: [String]

    public init(productIds: [String] = [ProductIDs.monthly, ProductIDs.annual]) {
        self.productIds = productIds
    }

    public func products() async throws -> [StoreProduct] {
        let storeProducts = try await Product.products(for: productIds)
        return storeProducts.map { product in
            StoreProduct(
                id: product.id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice,
                period: product.subscription?.subscriptionPeriod.unit == .year ? .annual : .monthly
            )
        }
    }

    public func purchase(_ product: StoreProduct) async throws -> StoreTransactionResult {
        guard let storeProduct = try await Product.products(for: [product.id]).first else {
            throw StoreError.productUnavailable
        }
        let result = try await storeProduct.purchase()
        switch result {
        case .success(let verificationResult):
            let transaction = try verificationResult.payloadValue
            await transaction.finish()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        @unknown default:
            return .pending
        }
    }

    public func restore() async throws -> StoreTransactionResult {
        try await AppStore.sync()
        return .success
    }

    private enum StoreError: Error {
        case productUnavailable
    }
}
