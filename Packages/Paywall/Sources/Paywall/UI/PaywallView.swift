import Content
import DesignSystem
import StoreKit
import SwiftUI

public struct PaywallView: View {
    @ObservedObject private var premiumState: PremiumState
    @StateObject private var viewModel: ViewModel

    public init(storeClient: StoreClient, premiumState: PremiumState) {
        _premiumState = ObservedObject(wrappedValue: premiumState)
        _viewModel = StateObject(wrappedValue: ViewModel(storeClient: storeClient))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.lg) {
                    hero
                    features
                    if viewModel.isLoading {
                        ProgressView(AppCopy.string(for: "paywall.loading"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        productButtons
                    }
                    restore
                    if let message = viewModel.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(BabyTrackTheme.palette.destructive)
                    }
                }
                .padding(BabyTrackTheme.spacing.lg)
            }
            .background(BabyTrackTheme.palette.background.ignoresSafeArea())
            .navigationTitle(Text(AppCopy.PaywallCopy.title))
            .task { await viewModel.loadProducts() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
            BabyTrackTheme.typography.title.text(AppCopy.string(for: "paywall.subtitle"))
            Tag(
                title: premiumState.isPremium ? AppCopy.string(for: "settings.premium.active") : AppCopy.string(for: "settings.premium.inactive"),
                color: premiumState.isPremium ? BabyTrackTheme.palette.success : BabyTrackTheme.palette.warning,
                icon: Symbols.premium
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
            featureRow(icon: Symbols.chart, title: AppCopy.string(for: "paywall.feature.charts"))
            featureRow(icon: "externaldrive", title: AppCopy.string(for: "paywall.feature.export"))
            featureRow(icon: "icloud", title: AppCopy.string(for: "paywall.feature.sync"))
            // TODO: Integrate WHO percentiles when data source is plugged in.
        }
        .padding()
        .background(BabyTrackTheme.palette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: BabyTrackTheme.radii.card, style: .continuous))
    }

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(BabyTrackTheme.palette.accent)
            Text(title)
                .font(.system(.body, design: .rounded))
            Spacer()
        }
    }

    private var productButtons: some View {
        VStack(spacing: BabyTrackTheme.spacing.sm) {
            ForEach(viewModel.products, id: \.id) { product in
                PrimaryButton(isLoading: viewModel.currentPurchaseID == product.id, action: {
                    Task { await purchase(product: product) }
                }) {
                    HStack {
                        Text(product.displayName)
                        Spacer()
                        Text(product.displayPrice)
                    }
                }
            }
        }
    }

    private var restore: some View {
        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.xs) {
            Button(AppCopy.string(for: "paywall.restore")) {
                Task { await restorePurchases() }
            }
            .buttonStyle(.plain)
            .foregroundStyle(BabyTrackTheme.palette.accent)

            Text(AppCopy.string(for: "paywall.restore.description"))
                .font(.footnote)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
        }
    }

    private func purchase(product: Product) async {
        let transaction = await viewModel.purchase(id: product.id)
        premiumState.apply(transaction: transaction)
    }

    private func restorePurchases() async {
        let transaction = await viewModel.restore()
        if let transaction {
            premiumState.apply(transaction: transaction)
            viewModel.message = AppCopy.string(for: "paywall.restore.success")
        }
    }
}

extension PaywallView {
    final class ViewModel: ObservableObject {
        @Published var products: [Product] = []
        @Published var isLoading = false
        @Published var currentPurchaseID: String?
        @Published var message: String?

        private let client: StoreClient

        init(storeClient: StoreClient) {
            self.client = storeClient
        }

        @MainActor
        func loadProducts() async {
            isLoading = true
            message = nil
            defer { isLoading = false }
            do {
                products = try await client.loadProducts().sorted(by: { $0.displayPrice < $1.displayPrice })
            } catch {
                message = AppCopy.string(for: "paywall.error.generic")
            }
        }

        @MainActor
        func purchase(id: String) async -> StoreKit.Transaction? {
            message = nil
            currentPurchaseID = id
            defer { currentPurchaseID = nil }
            do {
                return try await client.purchase(id)
            } catch {
                message = AppCopy.string(for: "errors.purchase.failed")
                return nil
            }
        }

        @MainActor
        func restore() async -> StoreKit.Transaction? {
            message = nil
            do {
                return try await client.restore()
            } catch {
                message = AppCopy.string(for: "paywall.error.generic")
                return nil
            }
        }
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(storeClient: .mock, premiumState: PremiumState())
    }
}
#endif
