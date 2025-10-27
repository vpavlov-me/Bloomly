import Foundation

public actor InMemoryEventsRepository: EventsRepository {
    private var storage: [UUID: EventDTO]
    private let calendar: Calendar

    public init(
        events: [EventDTO] = [],
        calendar: Calendar = .current
    ) {
        self.storage = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
        self.calendar = calendar
    }

    public func create(_ dto: EventDTO) async throws -> EventDTO {
        storage[dto.id] = dto
        return dto
    }

    public func update(_ dto: EventDTO) async throws -> EventDTO {
        guard storage[dto.id] != nil else {
            throw EventsRepositoryError.notFound
        }
        storage[dto.id] = dto
        return dto
    }

    public func delete(id: UUID) async throws {
        guard storage.removeValue(forKey: id) != nil else {
            throw EventsRepositoryError.notFound
        }
    }

    public func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        var events = Array(storage.values)
        if let interval {
            events = events.filter { interval.contains($0.start) }
        }
        if let kind {
            events = events.filter { $0.kind == kind }
        }
        return events.sorted { $0.start > $1.start }
    }

    public func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        try await events(in: nil, kind: kind).first
    }

    public func read(id: UUID) async throws -> EventDTO {
        guard let event = storage[id] else {
            throw EventsRepositoryError.notFound
        }
        return event
    }

    public func upsert(_ dto: EventDTO) async throws -> EventDTO {
        storage[dto.id] = dto
        return dto
    }

    public func events(for babyID: UUID, in interval: DateInterval?) async throws -> [EventDTO] {
        // In-memory doesn't support baby filtering yet
        try await events(in: interval, kind: nil)
    }

    public func stats(for day: Date) async throws -> EventDayStats {
        let events = try await events(on: day, calendar: calendar)
        let totalDuration = events.reduce(0) { $0 + $1.duration }
        return EventDayStats(date: calendar.startOfDay(for: day), totalEvents: events.count, totalDuration: totalDuration)
    }

    public func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        for dto in dtos {
            storage[dto.id] = dto
        }
        return dtos
    }

    public func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        for dto in dtos {
            guard storage[dto.id] != nil else {
                throw EventsRepositoryError.notFound
            }
            storage[dto.id] = dto
        }
        return dtos
    }
}
