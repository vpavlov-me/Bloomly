import SnapshotTesting
import SwiftUI
import XCTest
@testable import Paywall

final class PaywallViewTests: XCTestCase {
    private let isRecording = false

    func testPaywallRendering() {
        let premiumState = PremiumState()
        premiumState.apply(transaction: nil)
        let client = StoreClient(
            loadProducts: { [] },
            purchase: { _ in nil },
            restore: { nil },
            isEntitled: { false }
        )
        let view = PaywallView(storeClient: client, premiumState: premiumState)
            .frame(width: 390, height: 844)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Mini)), record: isRecording)
    }
}
