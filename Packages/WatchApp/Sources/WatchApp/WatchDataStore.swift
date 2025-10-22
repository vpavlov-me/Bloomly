import AppSupport
import Foundation
import Measurements
import Tracking

@MainActor
public final class WatchDataStore: ObservableObject {
    public let eventsRepository: any EventsRepository
    public let measurementsRepository: any MeasurementsRepository
    public let analytics: any Analytics

    @Published public private(set) var recentEvents: [EventDTO] = []

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
    }

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
