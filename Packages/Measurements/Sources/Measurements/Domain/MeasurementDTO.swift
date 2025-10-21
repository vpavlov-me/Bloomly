import Foundation

public struct MeasurementDTO: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var type: MeasurementType
    public var value: Double
    public var unit: String
    public var date: Date
    public var notes: String?
    public var isSynced: Bool

    public init(
        id: UUID = UUID(),
        type: MeasurementType,
        value: Double,
        unit: String,
        date: Date,
        notes: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.date = date
        self.notes = notes
        self.isSynced = isSynced
    }

    public var formattedValue: String {
        MeasurementDTO.formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
