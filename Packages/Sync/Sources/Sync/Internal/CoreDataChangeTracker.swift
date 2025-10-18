//
//  CoreDataChangeTracker.swift
//  BabyTrack
//
//  Tracks local Core Data changes pending sync.
//

import CoreData
import Foundation
import Tracking
import Measurements

public final class CoreDataChangeTracker: ChangeTracking {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func markSynced(eventIDs: [UUID]) async throws {
        try await context.perform {
            guard !eventIDs.isEmpty else { return }
            let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
            request.predicate = NSPredicate(format: "id IN %@", eventIDs)
            let objects = try self.context.fetch(request)
            objects.forEach { $0.setValue(true, forKey: "isSynced") }
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    public func markSynced(measurementIDs: [UUID]) async throws {
        try await context.perform {
            guard !measurementIDs.isEmpty else { return }
            let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
            request.predicate = NSPredicate(format: "id IN %@", measurementIDs)
            let objects = try self.context.fetch(request)
            objects.forEach { $0.setValue(true, forKey: "isSynced") }
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    public func pendingEvents() async throws -> [Event] {
        try await fetchPending(entityName: "Event") { object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let kindValue = object.value(forKey: "kind") as? String,
                let kind = EventKind(rawValue: kindValue),
                let start = object.value(forKey: "start") as? Date,
                let createdAt = object.value(forKey: "createdAt") as? Date,
                let updatedAt = object.value(forKey: "updatedAt") as? Date
            else { return nil }
            return Event(
                id: id,
                kind: kind,
                start: start,
                end: object.value(forKey: "end") as? Date,
                notes: object.value(forKey: "notes") as? String,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: object.value(forKey: "isSynced") as? Bool ?? false
            )
        }
    }

    public func pendingMeasurements() async throws -> [MeasurementSample] {
        try await fetchPending(entityName: "Measurement") { object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let typeValue = object.value(forKey: "type") as? String,
                let type = MeasurementType(rawValue: typeValue),
                let value = object.value(forKey: "value") as? Double,
                let unit = object.value(forKey: "unit") as? String,
                let date = object.value(forKey: "date") as? Date
            else { return nil }
            return MeasurementSample(
                id: id,
                type: type,
                value: value,
                unit: unit,
                date: date,
                isSynced: object.value(forKey: "isSynced") as? Bool ?? false
            )
        }
    }

    private func fetchPending<T>(entityName: String, mapper: @escaping (NSManagedObject) -> T?) async throws -> [T] {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = NSPredicate(format: "isSynced == NO OR isSynced == 0")
            let objects = try self.context.fetch(request)
            return objects.compactMap(mapper)
        }
    }
}
