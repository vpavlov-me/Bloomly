import Content
import Foundation

public enum MeasurementType: String, CaseIterable, Identifiable, Codable, Sendable {
    case height
    case weight
    case head

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .height: return MeasurementCopy.Kind.height.rawValue
        case .weight: return MeasurementCopy.Kind.weight.rawValue
        case .head: return MeasurementCopy.Kind.head.rawValue
        }
    }

    public var defaultUnit: String {
        switch self {
        case .height, .head: return AppCopy.string(for: "measurement.unit.cm")
        case .weight: return AppCopy.string(for: "measurement.unit.kg")
        }
    }

    public var icon: String {
        switch self {
        case .height: return Symbols.measurement
        case .weight: return Symbols.weight
        case .head: return Symbols.head
        }
    }
}
