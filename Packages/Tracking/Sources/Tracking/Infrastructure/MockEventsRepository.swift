import Foundation

#if DEBUG
/// Mock implementation of EventsRepository for SwiftUI Previews and tests
public final class MockEventsRepository: EventsRepository {
    private let eventsStorage: [EventDTO]
    private let lastEventsMap: [EventKind: EventDTO]

    public init(events: [EventDTO] = [], lastEvents: [EventKind: EventDTO] = [:]) {
        self.eventsStorage = events
        self.lastEventsMap = lastEvents
    }

    public func create(_ dto: EventDTO) async throws -> EventDTO {
        dto
    }

    public func read(id: UUID) async throws -> EventDTO {
        guard let event = eventsStorage.first(where: { $0.id == id }) else {
            throw EventsRepositoryError.notFound
        }
        return event
    }

    public func update(_ dto: EventDTO) async throws -> EventDTO {
        dto
    }

    public func delete(id: UUID) async throws {}

    public func upsert(_ dto: EventDTO) async throws -> EventDTO {
        dto
    }

    public func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        var filtered = eventsStorage

        if let interval = interval {
            filtered = filtered.filter { event in
                event.start >= interval.start && event.start < interval.end
            }
        }

        if let kind = kind {
            filtered = filtered.filter { $0.kind == kind }
        }

        return filtered
    }

    public func events(for babyID: UUID, in interval: DateInterval?) async throws -> [EventDTO] {
        eventsStorage
    }

    public func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        lastEventsMap[kind]
    }

    public func stats(for day: Date) async throws -> EventDayStats {
        EventDayStats(date: day, totalEvents: eventsStorage.count, totalDuration: 7200)
    }

    public func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        dtos
    }

    public func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        dtos
    }
}
#endif
