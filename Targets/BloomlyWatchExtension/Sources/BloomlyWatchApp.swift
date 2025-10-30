import SwiftUI
import WatchApp
import Tracking

@main
struct BloomlyWatchExtensionApp: App {
    @StateObject private var store = WatchDataStore()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(store: store)
        }
    }
}
