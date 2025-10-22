import Foundation

public struct EventDraft {
    public var kind: EventKind
    public var start: Date
    public var end: Date?
    public var notes: String?

    public init(kind: EventKind, start: Date, end: Date? = nil, notes: String? = nil) {
        self.kind = kind
        self.start = start
        self.end = end
        self.notes = notes
    }

    public func makeDTO(id: UUID = UUID()) -> EventDTO {
        EventDTO(
            id: id,
            kind: kind,
            start: start,
            end: end,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date(),
            isSynced: false
        )
    }
}
