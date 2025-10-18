//
//  PaywallView.swift
//  BabyTrack
//
//  Minimal paywall UI backed by StoreClient.
//

import SwiftUI
import Content
import DesignSystem

public enum PaywallState: Equatable {
    case idle
    case loading
    case purchased
    case error(String)
}

@MainActor
public final class PaywallViewModel: ObservableObject {
    @Published public private(set) var state: PaywallState = .idle
    @Published public private(set) var products: [StoreProduct] = []

    private let storeClient: StoreClient

    public init(storeClient: StoreClient) {
        self.storeClient = storeClient
    }

    public func load() async {
        state = .loading
        do {
            products = try await storeClient.products()
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func overrideProductsForTesting(_ products: [StoreProduct]) {
        self.products = products
    }

    public func purchase(_ product: StoreProduct) async {
        state = .loading
        do {
            let result = try await storeClient.purchase(product)
            switch result {
            case .success:
                state = .purchased
            case .userCancelled:
                state = .idle
            case .pending:
                state = .error("Pending confirmation")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func restore() async {
        state = .loading
        do {
            _ = try await storeClient.restore()
            state = .purchased
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

public struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel

    public init(viewModel: @autoclosure @escaping () -> PaywallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: BabyTrackSpacing.large.rawValue) {
            Text(L10n.paywallTitle())
                .font(BabyTrackFont.heading(28))
            Text(L10n.paywallSubtitle())
                .font(BabyTrackFont.body(17))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            productList
            actionButtons
        }
        .padding()
        .task { await viewModel.load() }
        .overlay(alignment: .center) {
            if viewModel.state == .loading {
                ProgressView()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var productList: some View {
        VStack(spacing: BabyTrackSpacing.medium.rawValue) {
            ForEach(viewModel.products) { product in
                Button {
                    Task { await viewModel.purchase(product) }
                } label: {
                    VStack(alignment: .leading) {
                        Text(product.displayName)
                            .font(BabyTrackFont.heading(20))
                        Text(product.displayPrice)
                            .font(BabyTrackFont.body(17))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Restore") {
                Task { await viewModel.restore() }
            }
            .buttonStyle(.bordered)
        }
    }
}
