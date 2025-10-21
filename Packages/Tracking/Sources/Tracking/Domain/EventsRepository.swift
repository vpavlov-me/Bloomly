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
    func create(_ dto: EventDTO) async throws -> EventDTO
    func update(_ dto: EventDTO) async throws -> EventDTO
    func delete(id: UUID) async throws
    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO]
    func lastEvent(for kind: EventKind) async throws -> EventDTO?
    func stats(for day: Date) async throws -> EventDayStats
}

public extension EventsRepository {
    func events(on day: Date, calendar: Calendar = .current) async throws -> [EventDTO] {
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        let interval = DateInterval(start: startOfDay, end: endOfDay)
        return try await events(in: interval, kind: nil)
    }
}

public struct AnalyticsEvent: Sendable {
    public let name: String
    public let metadata: [String: String]

    public init(name: String, metadata: [String: String] = [:]) {
        self.name = name
        self.metadata = metadata
    }
}

public protocol Analytics: Sendable {
    func track(_ event: AnalyticsEvent)
}

public struct AnalyticsLogger: Analytics {
    private let logger = Logger(subsystem: "com.example.babytrack", category: "analytics")

    public init() {}

    public func track(_ event: AnalyticsEvent) {
        logger.log("Event: \(event.name, privacy: .public) metadata: \(event.metadata.description, privacy: .public)")
    }
}
