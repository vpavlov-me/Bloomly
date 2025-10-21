import CoreData
import Foundation

public actor CoreDataMeasurementsRepository: MeasurementsRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        try await perform { context in
            let object = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
            populate(object, from: dto)
            try context.saveIfNeeded()
            return map(object)
        }
    }

    public func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        try await perform { context in
            guard let object = try fetchObject(id: dto.id, in: context) else {
                throw MeasurementsRepositoryError.notFound
            }
            populate(object, from: dto)
            try context.saveIfNeeded()
            return map(object)
        }
    }

    public func delete(id: UUID) async throws {
        try await perform { context in
            guard let object = try fetchObject(id: id, in: context) else {
                throw MeasurementsRepositoryError.notFound
            }
            context.delete(object)
            try context.saveIfNeeded()
        }
    }

    public func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] {
        try await perform { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
            var predicates: [NSPredicate] = []
            if let interval {
                predicates.append(NSPredicate(format: "date >= %@ AND date < %@", interval.start as NSDate, interval.end as NSDate))
            }
            if let type {
                predicates.append(NSPredicate(format: "type == %@", type.rawValue))
            }
            request.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try context.fetch(request).map(map(_:))
        }
    }

    private func perform<T>(_ action: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let result = try action(self.context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchObject(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func populate(_ object: NSManagedObject, from dto: MeasurementDTO) {
        object.setValue(dto.id, forKey: "id")
        object.setValue(dto.type.rawValue, forKey: "type")
        object.setValue(dto.value, forKey: "value")
        object.setValue(dto.unit, forKey: "unit")
        object.setValue(dto.date, forKey: "date")
        object.setValue(dto.isSynced, forKey: "isSynced")
    }

    private func map(_ object: NSManagedObject) -> MeasurementDTO {
        MeasurementDTO(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            type: MeasurementType(rawValue: object.value(forKey: "type") as? String ?? "height") ?? .height,
            value: object.value(forKey: "value") as? Double ?? 0,
            unit: object.value(forKey: "unit") as? String ?? MeasurementType.height.defaultUnit,
            date: object.value(forKey: "date") as? Date ?? Date(),
            notes: object.value(forKey: "notes") as? String,
            isSynced: object.value(forKey: "isSynced") as? Bool ?? false
        )
    }
}

private extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}
