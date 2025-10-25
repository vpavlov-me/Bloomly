import AppSupport
import Content
import Measurements
import SwiftUI
import Tracking

public struct WatchDashboardView: View {
    @ObservedObject private var store: WatchDataStore

    public init(store: WatchDataStore) {
        self._store = ObservedObject(wrappedValue: store)
    }

    public var body: some View {
        TabView {
            QuickLogView()
                .tabItem { Label(AppCopy.WatchApp.tabLog, systemImage: Symbols.add) }

            RecentEventsView()
                .tabItem { Label(AppCopy.WatchApp.tabHistory, systemImage: Symbols.timeline) }

            AddMeasurementView()
                .tabItem { Label(AppCopy.WatchApp.tabMeasure, systemImage: Symbols.measurement) }
        }
        .environment(\.eventsRepository, store.eventsRepository)
        .environment(\.measurementsRepository, store.measurementsRepository)
        .environment(\.analytics, store.analytics)
        .task {
            store.refresh()
        }
    }
}

#if DEBUG
struct WatchDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WatchDashboardView(store: WatchDataStore())
    }
}
#endif
