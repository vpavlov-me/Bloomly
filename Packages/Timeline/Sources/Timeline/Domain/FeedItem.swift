import Foundation
import Measurements
import Tracking

public enum FeedItem: Identifiable, Hashable, Sendable {
    case event(EventDTO)
    case measurement(MeasurementDTO)

    public var id: UUID {
        switch self {
        case .event(let event): return event.id
        case .measurement(let measurement): return measurement.id
        }
    }

    public var date: Date {
        switch self {
        case .event(let event): return event.start
        case .measurement(let measurement): return measurement.date
        }
    }

    public var kindIdentifier: String {
        switch self {
        case .event(let event): return event.kind.rawValue
        case .measurement(let measurement): return measurement.type.rawValue
        }
    }
}
