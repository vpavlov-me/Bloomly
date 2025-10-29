import AppSupport
import Combine
import Foundation
import Measurements
import Tracking

@MainActor
public final class WatchDataStore: ObservableObject {
    public static let shared = WatchDataStore()

    public let eventsRepository: any EventsRepository
    public let measurementsRepository: any MeasurementsRepository
    public let analytics: any Analytics

    @Published public private(set) var recentEvents: [EventDTO] = []

    // MARK: - Computed Properties for Complications

    public var lastFeed: EventDTO? {
        recentEvents.first { $0.kind == .feeding }
    }

    public var lastSleep: EventDTO? {
        recentEvents.first { $0.kind == .sleep }
    }

    public var lastDiaper: EventDTO? {
        recentEvents.first { $0.kind == .diaper }
    }

    #if os(watchOS)
    private let connectivity = WatchConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()
    #endif

    private let calendar: Calendar

    public init(
        eventsRepository: (any EventsRepository)? = nil,
        measurementsRepository: (any MeasurementsRepository)? = nil,
        analytics: (any Analytics)? = nil,
        calendar: Calendar = .current
    ) {
        if let eventsRepository {
            self.eventsRepository = eventsRepository
        } else {
            self.eventsRepository = InMemoryEventsRepository(calendar: calendar)
        }
        if let measurementsRepository {
            self.measurementsRepository = measurementsRepository
        } else {
            self.measurementsRepository = InMemoryMeasurementsRepository()
        }
        self.analytics = analytics ?? AnalyticsLogger()
        self.calendar = calendar

        #if os(watchOS)
        setupConnectivityObservers()
        #endif
    }

    #if os(watchOS)
    private func setupConnectivityObservers() {
        // Observe received events from iPhone
        connectivity.$receivedEvents
            .sink { [weak self] events in
                self?.recentEvents = events
            }
            .store(in: &cancellables)
    }
    #endif

    public func log(kind: EventKind) {
        log(draft: EventDraft(kind: kind, start: Date()))
    }

    public func log(draft: EventDraft) {
        Task {
            await performLog(draft: draft)
        }
    }

    public func refresh() {
        Task {
            await loadRecentEvents()
        }
    }

    private func performLog(draft: EventDraft) async {
        do {
            let dto = draft.makeDTO()
            _ = try await eventsRepository.create(dto)
            analytics.track(AnalyticsEvent(name: "watch_log", metadata: ["kind": draft.kind.rawValue]))

            #if os(watchOS)
            // Send event to iPhone via Watch Connectivity
            connectivity.sendEvent(dto)
            #endif

            await loadRecentEvents()
        } catch {
            // For now swallow errors; watch UI handles repository errors separately.
        }
    }

    private func loadRecentEvents() async {
        do {
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -3, to: end) ?? end.addingTimeInterval(-3 * 86400)
            let interval = DateInterval(start: start, end: end)
            let events = try await eventsRepository.events(in: interval, kind: nil)
            recentEvents = Array(events.prefix(10))
        } catch {
            recentEvents = []
        }
    }
}
