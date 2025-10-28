import Content
import Foundation

public enum EventKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case sleep
    case feeding
    case diaper
    case pumping
    case measurement
    case medication
    case note

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .sleep: return EventCopy.Kind.sleep.rawValue
        case .feeding: return EventCopy.Kind.feed.rawValue
        case .diaper: return EventCopy.Kind.diaper.rawValue
        case .pumping: return "event.kind.pumping"
        case .measurement: return "event.kind.measurement"
        case .medication: return "event.kind.medication"
        case .note: return "event.kind.note"
        }
    }

    public var symbol: String {
        switch self {
        case .sleep: return Symbols.sleep
        case .feeding: return Symbols.feed
        case .diaper: return Symbols.diaper
        case .pumping: return "drop.circle.fill"
        case .measurement: return "ruler"
        case .medication: return "pills"
        case .note: return "note.text"
        }
    }
}
