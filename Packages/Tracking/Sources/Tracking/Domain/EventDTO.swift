import Foundation

public struct EventDTO: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var kind: EventKind
    public var start: Date
    public var end: Date?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var isSynced: Bool
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        kind: EventKind,
        start: Date,
        end: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isSynced: Bool = false,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
        self.isDeleted = isDeleted
    }

    public var duration: TimeInterval {
        (end ?? Date()).timeIntervalSince(start)
    }

    public var isOngoing: Bool {
        end == nil
    }
}

public struct EventDayStats: Equatable, Sendable {
    public let date: Date
    public let totalEvents: Int
    public let totalDuration: TimeInterval

    public init(date: Date, totalEvents: Int, totalDuration: TimeInterval) {
        self.date = date
        self.totalEvents = totalEvents
        self.totalDuration = totalDuration
    }
}
