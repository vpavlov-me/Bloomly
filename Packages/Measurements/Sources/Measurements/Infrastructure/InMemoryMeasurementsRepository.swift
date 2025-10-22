import Foundation

public actor InMemoryMeasurementsRepository: MeasurementsRepository {
    private var storage: [UUID: MeasurementDTO]

    public init(measurements: [MeasurementDTO] = []) {
        self.storage = Dictionary(uniqueKeysWithValues: measurements.map { ($0.id, $0) })
    }

    public func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        storage[dto.id] = dto
        return dto
    }

    public func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        guard storage[dto.id] != nil else {
            throw MeasurementsRepositoryError.notFound
        }
        storage[dto.id] = dto
        return dto
    }

    public func delete(id: UUID) async throws {
        guard storage.removeValue(forKey: id) != nil else {
            throw MeasurementsRepositoryError.notFound
        }
    }

    public func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] {
        var items = Array(storage.values)
        if let interval {
            items = items.filter { interval.contains($0.date) }
        }
        if let type {
            items = items.filter { $0.type == type }
        }
        return items.sorted { $0.date > $1.date }
    }
}
