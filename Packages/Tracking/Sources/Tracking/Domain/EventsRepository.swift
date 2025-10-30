import AppSupport
import Foundation
import os.log

public enum EventsRepositoryError: LocalizedError {
    case notFound
    case validationFailed(reason: String)
    case persistence(Error)

    public var errorDescription: String? {
        switch self {
        case .notFound: return "Event not found"
        case .validationFailed(let reason): return reason
        case .persistence(let error): return error.localizedDescription
        }
    }
}

public protocol EventsRepository: Sendable {
    /// Create a new event
    func create(_ dto: EventDTO) async throws -> EventDTO

    /// Read an event by ID
    func read(id: UUID) async throws -> EventDTO

    /// Update an existing event
    func update(_ dto: EventDTO) async throws -> EventDTO

    /// Soft delete an event (marks as deleted)
    func delete(id: UUID) async throws

    /// Idempotent upsert: creates if ID doesn't exist, updates if it does
    func upsert(_ dto: EventDTO) async throws -> EventDTO

    /// Fetch events in date range with optional kind filter
    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO]

    /// Fetch events for a specific baby (for multi-baby support)
    func events(for babyID: UUID, in interval: DateInterval?) async throws -> [EventDTO]

    /// Get the last event of a specific kind
    func lastEvent(for kind: EventKind) async throws -> EventDTO?

    /// Get statistics for a specific day
    func stats(for day: Date) async throws -> EventDayStats

    /// Batch insert multiple events (optimized for performance)
    func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO]

    /// Batch update multiple events
    func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO]
}

public extension EventsRepository {
    func events(on day: Date, calendar: Calendar = .current) async throws -> [EventDTO] {
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        let interval = DateInterval(start: startOfDay, end: endOfDay)
        return try await events(in: interval, kind: nil)
    }
}

public struct AnalyticsLogger: Analytics {
    private let logger = Logger(subsystem: "com.vibecoding.bloomly", category: "analytics")

    public init() {}

    public func track(_ event: AnalyticsEvent) {
        logger.log("Event: \(event.name, privacy: .public) metadata: \(event.metadata.description, privacy: .public)")
    }
}
