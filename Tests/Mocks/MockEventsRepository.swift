import Foundation
import Tracking

/// Mock EventsRepository for testing ViewModels
public final class MockEventsRepository: EventsRepository {
    public var events: [EventDTO] = []
    public var shouldThrowError = false
    public var errorToThrow: EventsRepositoryError = .notFound

    // Track method calls for verification
    public var createCallCount = 0
    public var updateCallCount = 0
    public var deleteCallCount = 0
    public var eventsCallCount = 0
    public var lastEventCallCount = 0
    public var statsCallCount = 0

    public init() {}

    public func create(_ dto: EventDTO) async throws -> EventDTO {
        createCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        var event = dto
        if event.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000")! {
            event = EventDTO(
                id: UUID(),
                kind: dto.kind,
                start: dto.start,
                end: dto.end,
                notes: dto.notes
            )
        }
        events.append(event)
        return event
    }

    public func update(_ dto: EventDTO) async throws -> EventDTO {
        updateCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        guard let index = events.firstIndex(where: { $0.id == dto.id }) else {
            throw EventsRepositoryError.notFound
        }
        events[index] = dto
        return dto
    }

    public func delete(id: UUID) async throws {
        deleteCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        guard let index = events.firstIndex(where: { $0.id == id }) else {
            throw EventsRepositoryError.notFound
        }
        events.remove(at: index)
    }

    public func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        eventsCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }

        var filtered = events

        if let interval = interval {
            filtered = filtered.filter { event in
                event.start >= interval.start && event.start < interval.end
            }
        }

        if let kind = kind {
            filtered = filtered.filter { $0.kind == kind }
        }

        return filtered.sorted { $0.start > $1.start }
    }

    public func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        lastEventCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        return events
            .filter { $0.kind == kind }
            .sorted { $0.start > $1.start }
            .first
    }

    public func stats(for day: Date) async throws -> EventDayStats {
        statsCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return EventDayStats(date: startOfDay, totalEvents: 0, totalDuration: 0)
        }

        let dayEvents = events.filter { event in
            event.start >= startOfDay && event.start < endOfDay
        }

        let totalDuration = dayEvents.reduce(0.0) { $0 + $1.duration }

        return EventDayStats(
            date: startOfDay,
            totalEvents: dayEvents.count,
            totalDuration: totalDuration
        )
    }

    // Helper methods for testing
    public func reset() {
        events.removeAll()
        shouldThrowError = false
        createCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        eventsCallCount = 0
        lastEventCallCount = 0
        statsCallCount = 0
    }

    public func seedEvents(_ eventsList: [EventDTO]) {
        events = eventsList
    }
}
