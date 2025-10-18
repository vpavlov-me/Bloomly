//
//  CoreDataEventsRepository.swift
//  BabyTrack
//
//  Core Data backed repository for baby care events.
//

import CoreData
import Foundation

public final class CoreDataEventsRepository: EventsRepository {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func events(in range: ClosedRange<Date>?, of kind: EventKind?) async throws -> [Event] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        var predicates: [NSPredicate] = []
        if let kind {
            predicates.append(NSPredicate(format: "%K == %@", Keys.kind, kind.rawValue))
        }
        if let range {
            predicates.append(NSPredicate(format: "%K >= %@ AND %K <= %@", Keys.start, range.lowerBound as NSDate, Keys.start, range.upperBound as NSDate))
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        request.sortDescriptors = [NSSortDescriptor(key: Keys.start, ascending: false)]

        return try await context.perform {
            let objects = try self.context.fetch(request)
            return objects.compactMap(Self.mapManagedObject(_:))
        }
    }

    public func upsert(_ event: EventInput) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
            request.predicate = NSPredicate(format: "%K == %@", Keys.id, event.id as CVarArg)
            request.fetchLimit = 1
            let existing = try self.context.fetch(request).first
            let object = existing ?? NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: self.context)
            Self.apply(event, to: object)
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
            for object in objects {
                self.context.delete(object)
            }
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    private static func apply(_ event: EventInput, to object: NSManagedObject) {
        object.setValue(event.id, forKey: Keys.id)
        object.setValue(event.kind.rawValue, forKey: Keys.kind)
        object.setValue(event.start, forKey: Keys.start)
        object.setValue(event.end, forKey: Keys.end)
        object.setValue(event.notes, forKey: Keys.notes)
        object.setValue(event.createdAt, forKey: Keys.createdAt)
        object.setValue(event.updatedAt, forKey: Keys.updatedAt)
        object.setValue(event.isSynced, forKey: Keys.isSynced)
    }

    private static func mapManagedObject(_ object: NSManagedObject) -> Event? {
        guard
            let id = object.value(forKey: Keys.id) as? UUID,
            let kindValue = object.value(forKey: Keys.kind) as? String,
            let kind = EventKind(rawValue: kindValue),
            let start = object.value(forKey: Keys.start) as? Date,
            let createdAt = object.value(forKey: Keys.createdAt) as? Date,
            let updatedAt = object.value(forKey: Keys.updatedAt) as? Date
        else {
            return nil
        }
        let end = object.value(forKey: Keys.end) as? Date
        let notes = object.value(forKey: Keys.notes) as? String
        let isSynced = object.value(forKey: Keys.isSynced) as? Bool ?? false
        return Event(
            id: id,
            kind: kind,
            start: start,
            end: end,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced
        )
    }

    private static let entityName = "Event"
    private enum Keys {
        static let id = "id"
        static let kind = "kind"
        static let start = "start"
        static let end = "end"
        static let notes = "notes"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let isSynced = "isSynced"
    }
}
