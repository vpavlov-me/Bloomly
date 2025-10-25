import AppSupport
import Combine
import DesignSystem
import Foundation
import Measurements
import Paywall
import Sync
import Tracking
import SwiftUI

#if os(iOS)
import WatchApp
#endif

@MainActor
public final class DependencyContainer: ObservableObject {
    public let persistence: PersistenceController
    public let eventsRepository: any EventsRepository
    public let measurementsRepository: any MeasurementsRepository
    public let storeClient: StoreClient
    public let syncService: any SyncService
    public let analytics: any Analytics
    public let premiumState: PremiumState
    public let notificationManager: NotificationManager

    private var cancellables = Set<AnyCancellable>()

    public init(
        persistence: PersistenceController = .shared,
        eventsRepository: (any EventsRepository)? = nil,
        measurementsRepository: (any MeasurementsRepository)? = nil,
        storeClient: StoreClient? = nil,
        syncService: (any SyncService)? = nil,
        analytics: (any Analytics)? = nil,
        notificationManager: NotificationManager? = nil
    ) {
        BabyTrackTheme.configureAppearance()

        self.persistence = persistence
        let viewContext = persistence.viewContext

        self.eventsRepository = eventsRepository ?? CoreDataEventsRepository(context: viewContext)
        self.measurementsRepository = measurementsRepository ?? CoreDataMeasurementsRepository(context: viewContext)
        self.storeClient = storeClient ?? StoreClient.live()
        self.syncService = syncService ?? CloudKitSyncService()
        self.analytics = analytics ?? AnalyticsLogger()
        self.premiumState = PremiumState()
        self.notificationManager = notificationManager ?? NotificationManager()

        setupSyncBindings()
    }

    private func setupSyncBindings() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                Task { await self?.syncService.pullChanges() }
            }
            .store(in: &cancellables)

        #if os(iOS)
        // Setup Watch Connectivity to receive events from Apple Watch
        NotificationCenter.default.publisher(for: NSNotification.Name("watchEventReceived"))
            .sink { [weak self] notification in
                Task { [weak self] in
                    await self?.handleWatchEvent(notification)
                }
            }
            .store(in: &cancellables)

        // Send recent events to watch when data changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.syncEventsToWatch()
                }
            }
            .store(in: &cancellables)
        #endif
    }

    #if os(iOS)
    private func handleWatchEvent(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let kind = userInfo["kind"] as? EventKind,
              let start = userInfo["start"] as? Date else {
            return
        }

        let end = userInfo["end"] as? Date
        let notes = userInfo["notes"] as? String

        let dto = EventDTO(kind: kind, start: start, end: end, notes: notes)

        do {
            _ = try await eventsRepository.create(dto)
        } catch {
            debugPrint("Failed to save event from watch: \(error)")
        }
    }

    private func syncEventsToWatch() async {
        do {
            let interval = DateInterval(
                start: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                end: Date()
            )
            let events = try await eventsRepository.events(in: interval, kind: nil)
            let recentEvents = Array(events.prefix(10))

            WatchConnectivityService.shared.sendRecentEvents(recentEvents)
        } catch {
            debugPrint("Failed to sync events to watch: \(error)")
        }
    }
    #endif
}

// MARK: - Environment keys

private struct EventsRepositoryKey: EnvironmentKey {
    static let defaultValue: any EventsRepository = NullEventsRepository()
}

private struct MeasurementsRepositoryKey: EnvironmentKey {
    static let defaultValue: any MeasurementsRepository = NullMeasurementsRepository()
}

private struct StoreClientKey: EnvironmentKey {
    static let defaultValue: StoreClient = .mock
}

private struct PremiumStateKey: EnvironmentKey {
    static let defaultValue: PremiumState = PremiumState()
}

private struct AnalyticsKey: EnvironmentKey {
    static let defaultValue: any Analytics = AnalyticsLogger()
}

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: any SyncService = CloudKitSyncService()
}

private struct NotificationManagerKey: EnvironmentKey {
    static let defaultValue: NotificationManager = NotificationManager()
}

public extension EnvironmentValues {
    var eventsRepository: any EventsRepository {
        get { self[EventsRepositoryKey.self] }
        set { self[EventsRepositoryKey.self] = newValue }
    }

    var measurementsRepository: any MeasurementsRepository {
        get { self[MeasurementsRepositoryKey.self] }
        set { self[MeasurementsRepositoryKey.self] = newValue }
    }

    var storeClient: StoreClient {
        get { self[StoreClientKey.self] }
        set { self[StoreClientKey.self] = newValue }
    }

    var premiumState: PremiumState {
        get { self[PremiumStateKey.self] }
        set { self[PremiumStateKey.self] = newValue }
    }

    var analytics: any Analytics {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }

    var syncService: any SyncService {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }

    var notificationManager: NotificationManager {
        get { self[NotificationManagerKey.self] }
        set { self[NotificationManagerKey.self] = newValue }
    }
}

// MARK: - Null objects

private struct NullEventsRepository: EventsRepository {
    func create(_ dto: EventDTO) async throws -> EventDTO { fatalError("EventsRepository not provided") }
    func update(_ dto: EventDTO) async throws -> EventDTO { fatalError("EventsRepository not provided") }
    func delete(id: UUID) async throws { fatalError("EventsRepository not provided") }
    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] { fatalError("EventsRepository not provided") }
    func lastEvent(for kind: EventKind) async throws -> EventDTO? { fatalError("EventsRepository not provided") }
    func stats(for day: Date) async throws -> EventDayStats { fatalError("EventsRepository not provided") }
}

private struct NullMeasurementsRepository: MeasurementsRepository {
    func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO { fatalError("MeasurementsRepository not provided") }
    func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO { fatalError("MeasurementsRepository not provided") }
    func delete(id: UUID) async throws { fatalError("MeasurementsRepository not provided") }
    func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] { fatalError("MeasurementsRepository not provided") }
}
