import Foundation

public struct EventDTO: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var kind: EventKind
    public var start: Date
    public var end: Date?
    public var notes: String?
    public var metadata: [String: String]?
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
        metadata: [String: String]? = nil,
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
        self.metadata = metadata
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

    /// Formatted duration string (e.g., "2h 30m", "45m", "3h")
    public var formattedDuration: String {
        let seconds = Int(duration)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }

    /// Duration in minutes (rounded)
    public var durationInMinutes: Int {
        Int(duration / 60)
    }

    /// Duration in hours (rounded to 1 decimal place)
    public var durationInHours: Double {
        (duration / 3600).rounded(toPlaces: 1)
    }

    /// Check if event is in the past
    public var isPast: Bool {
        if let end = end {
            return end < Date()
        }
        return start < Date()
    }

    /// Check if event is today
    public func isToday(calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(start)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
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
