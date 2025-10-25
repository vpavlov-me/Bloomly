import CoreData
import SwiftUI

@main
struct BabyTrackApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.shouldShowOnboarding {
                    OnboardingView(container: container)
                } else {
                    MainTabView(container: container)
                }
            }
            .environment(\.eventsRepository, container.eventsRepository)
            .environment(\.measurementsRepository, container.measurementsRepository)
            .environment(\.storeClient, container.storeClient)
            .environment(\.analytics, container.analytics)
            .environment(\.premiumState, container.premiumState)
            .environment(\.syncService, container.syncService)
            .environment(\.notificationManager, container.notificationManager)
            .environment(\.managedObjectContext, container.persistence.viewContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                Task { await container.syncService.pushPending() }
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
