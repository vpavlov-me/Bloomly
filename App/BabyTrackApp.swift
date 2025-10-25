import CoreData
import SwiftUI

@main
struct BabyTrackApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var widgetDeepLink: WidgetDeepLink?

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.shouldShowOnboarding {
                    OnboardingView(container: container)
                } else {
                    MainTabView(container: container, widgetDeepLink: $widgetDeepLink)
                }
            }
            .environment(\.eventsRepository, container.eventsRepository)
            .environment(\.measurementsRepository, container.measurementsRepository)
            .environment(\.storeClient, container.storeClient)
            .environment(\.analytics, container.analytics)
            .environment(\.premiumState, container.premiumState)
            .environment(\.syncService, container.syncService)
            .environment(\.notificationManager, container.notificationManager)
            .environment(\.chartAggregator, container.chartAggregator)
            .environment(\.managedObjectContext, container.persistence.viewContext)
            .handleWidgetDeepLinks { deepLink in
                widgetDeepLink = deepLink
                container.analytics.track(AnalyticsEvent(
                    name: "widget_tapped",
                    metadata: ["destination": deepLink.rawValue]
                ))
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                Task {
                    await container.syncService.pushPending()
                    // Reload widgets when app goes to background
                    WidgetReloader.shared.reloadAll()
                }
            case .active:
                Task {
                    await container.syncService.pullChanges()
                    container.notificationManager.checkNotificationStatus()
                }
            default:
                break
            }
        }
    }
}
