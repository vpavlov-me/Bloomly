import Foundation

public enum MeasurementsRepositoryError: LocalizedError {
    case notFound
    case persistence(Error)

    public var errorDescription: String? {
        switch self {
        case .notFound: return "Measurement not found"
        case .persistence(let error): return error.localizedDescription
        }
    }
}

public protocol MeasurementsRepository: Sendable {
    func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO
    func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO
    func delete(id: UUID) async throws
    func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO]
}

public extension MeasurementsRepository {
    func measurements(forLastDays days: Int, calendar: Calendar = .current) async throws -> [MeasurementDTO] {
        let end = Date()
        guard let start = calendar.date(byAdding: .day, value: -days, to: end) else { return [] }
        let interval = DateInterval(start: start, end: end)
        return try await measurements(in: interval, type: nil)
    }
}
