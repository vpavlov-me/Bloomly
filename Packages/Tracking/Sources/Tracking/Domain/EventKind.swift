import Content
import Foundation

public enum EventKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case sleep
    case feed
    case diaper

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .sleep: return EventCopy.Kind.sleep.rawValue
        case .feed: return EventCopy.Kind.feed.rawValue
        case .diaper: return EventCopy.Kind.diaper.rawValue
        }
    }

    public var symbol: String {
        switch self {
        case .sleep: return Symbols.sleep
        case .feed: return Symbols.feed
        case .diaper: return Symbols.diaper
        }
    }
}
