//
//  CoreDataMeasurementsRepository.swift
//  BabyTrack
//
//  Core Data backed measurements repository.
//

import CoreData
import Foundation

public final class CoreDataMeasurementsRepository: MeasurementsRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func measurements(of type: MeasurementType) async throws -> [MeasurementSample] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.predicate = NSPredicate(format: "%K == %@", Keys.type, type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: Keys.date, ascending: true)]
        return try await context.perform {
            let objects = try self.context.fetch(request)
            return objects.compactMap(Self.mapManagedObject(_:))
        }
    }

    public func upsert(_ measurement: MeasurementInput) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "%K == %@", Keys.id, measurement.id as CVarArg)
            let object = try self.context.fetch(request).first ?? NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: self.context)
            Self.apply(measurement, to: object)
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    public func delete(id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
            request.predicate = NSPredicate(format: "%K == %@", Keys.id, id as CVarArg)
            let objects = try self.context.fetch(request)
            objects.forEach(self.context.delete)
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    private static func apply(_ measurement: MeasurementInput, to object: NSManagedObject) {
        object.setValue(measurement.id, forKey: Keys.id)
        object.setValue(measurement.type.rawValue, forKey: Keys.type)
        object.setValue(measurement.value, forKey: Keys.value)
        object.setValue(measurement.unit, forKey: Keys.unit)
        object.setValue(measurement.date, forKey: Keys.date)
        object.setValue(measurement.isSynced, forKey: Keys.isSynced)
    }

    private static func mapManagedObject(_ object: NSManagedObject) -> MeasurementSample? {
        guard
            let id = object.value(forKey: Keys.id) as? UUID,
            let typeValue = object.value(forKey: Keys.type) as? String,
            let type = MeasurementType(rawValue: typeValue),
            let value = object.value(forKey: Keys.value) as? Double,
            let unit = object.value(forKey: Keys.unit) as? String,
            let date = object.value(forKey: Keys.date) as? Date
        else { return nil }
        let isSynced = object.value(forKey: Keys.isSynced) as? Bool ?? false
        return MeasurementSample(
            id: id,
            type: type,
            value: value,
            unit: unit,
            date: date,
            isSynced: isSynced
        )
    }

    private static let entityName = "Measurement"
    private enum Keys {
        static let id = "id"
        static let type = "type"
        static let value = "value"
        static let unit = "unit"
        static let date = "date"
        static let isSynced = "isSynced"
    }
}
