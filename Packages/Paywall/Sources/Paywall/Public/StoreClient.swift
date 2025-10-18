//
//  StoreClient.swift
//  BabyTrack
//
//  Abstractions over StoreKit 2 purchases.
//

import Foundation

public struct StoreProduct: Identifiable, Sendable {
    public enum Period: Sendable {
        case monthly
        case annual
    }

    public let id: String
    public let displayName: String
    public let description: String
    public let displayPrice: String
    public let period: Period

    public init(id: String, displayName: String, description: String, displayPrice: String, period: Period) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.period = period
    }
}

public enum StoreTransactionResult: Sendable {
    case success
    case userCancelled
    case pending
}

public protocol StoreClient: Sendable {
    func products() async throws -> [StoreProduct]
    func purchase(_ product: StoreProduct) async throws -> StoreTransactionResult
    func restore() async throws -> StoreTransactionResult
}

public enum ProductIDs {
    public static let monthly = "com.example.babytrack.premium.monthly"
    public static let annual = "com.example.babytrack.premium.annual"
}
