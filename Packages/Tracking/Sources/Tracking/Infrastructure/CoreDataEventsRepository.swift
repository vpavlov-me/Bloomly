import CoreData
import Foundation

public actor CoreDataEventsRepository: EventsRepository {
    private let context: NSManagedObjectContext
    private let calendar: Calendar

    public init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    public func create(_ dto: EventDTO) async throws -> EventDTO {
        try await perform { context in
            let object = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
            let now = Date()
            object.setValue(dto.id, forKey: "id")
            object.setValue(dto.kind.rawValue, forKey: "kind")
            object.setValue(dto.start, forKey: "start")
            object.setValue(dto.end, forKey: "end")
            object.setValue(dto.notes, forKey: "notes")
            object.setValue(dto.createdAt, forKey: "createdAt")
            object.setValue(now, forKey: "updatedAt")
            object.setValue(false, forKey: "isSynced")
            object.setValue(false, forKey: "isDeleted")
            try context.saveIfNeeded()
            guard let mapped = self.map(object) else {
                throw EventsRepositoryError.persistence(NSError(domain: "Mapping", code: 0))
            }
            return mapped
        }
    }

    public func update(_ dto: EventDTO) async throws -> EventDTO {
        try await perform { context in
            guard let object = try self.fetchObject(id: dto.id, in: context) else {
                throw EventsRepositoryError.notFound
            }
            object.setValue(dto.kind.rawValue, forKey: "kind")
            object.setValue(dto.start, forKey: "start")
            object.setValue(dto.end, forKey: "end")
            object.setValue(dto.notes, forKey: "notes")
            object.setValue(dto.isDeleted, forKey: "isDeleted")
            object.setValue(Date(), forKey: "updatedAt")
            try context.saveIfNeeded()
            guard let mapped = self.map(object) else {
                throw EventsRepositoryError.persistence(NSError(domain: "Mapping", code: 0))
            }
            return mapped
        }
    }

    public func read(id: UUID) async throws -> EventDTO {
        try await perform { context in
            guard let object = try self.fetchObject(id: id, in: context) else {
                throw EventsRepositoryError.notFound
            }
            guard let mapped = self.map(object) else {
                throw EventsRepositoryError.persistence(NSError(domain: "Mapping", code: 0))
            }
            return mapped
        }
    }

    public func delete(id: UUID) async throws {
        try await perform { context in
            guard let object = try self.fetchObject(id: id, in: context) else {
                throw EventsRepositoryError.notFound
            }
            // Soft delete: mark as deleted instead of removing from database
            object.setValue(true, forKey: "isDeleted")
            object.setValue(Date(), forKey: "updatedAt")
            try context.saveIfNeeded()
        }
    }

    public func upsert(_ dto: EventDTO) async throws -> EventDTO {
        try await perform { context in
            // Try to fetch existing object
            let existing = try self.fetchObject(id: dto.id, in: context)

            if let object = existing {
                // Update existing
                object.setValue(dto.kind.rawValue, forKey: "kind")
                object.setValue(dto.start, forKey: "start")
                object.setValue(dto.end, forKey: "end")
                object.setValue(dto.notes, forKey: "notes")
                object.setValue(dto.isDeleted, forKey: "isDeleted")
                object.setValue(Date(), forKey: "updatedAt")
            } else {
                // Create new
                let object = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
                object.setValue(dto.id, forKey: "id")
                object.setValue(dto.kind.rawValue, forKey: "kind")
                object.setValue(dto.start, forKey: "start")
                object.setValue(dto.end, forKey: "end")
                object.setValue(dto.notes, forKey: "notes")
                object.setValue(dto.createdAt, forKey: "createdAt")
                object.setValue(Date(), forKey: "updatedAt")
                object.setValue(false, forKey: "isSynced")
                object.setValue(false, forKey: "isDeleted")
            }

            try context.saveIfNeeded()

            // Fetch and return the saved object
            guard let saved = try self.fetchObject(id: dto.id, in: context),
                  let mapped = self.map(saved) else {
                throw EventsRepositoryError.persistence(NSError(domain: "Mapping", code: 0))
            }
            return mapped
        }
    }

    public func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        try await perform { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
            var predicates: [NSPredicate] = []
            // Filter out soft-deleted events by default
            predicates.append(NSPredicate(format: "isDeleted == NO"))
            if let interval {
                predicates.append(NSPredicate(format: "start >= %@ AND start < %@", interval.start as NSDate, interval.end as NSDate))
            }
            if let kind {
                predicates.append(NSPredicate(format: "kind == %@", kind.rawValue))
            }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
            let objects = try context.fetch(request)
            return objects.compactMap(self.map(_:))
        }
    }

    public func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        try await perform { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
            request.predicate = NSPredicate(format: "kind == %@ AND isDeleted == NO", kind.rawValue)
            request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
            request.fetchLimit = 1
            return try context.fetch(request).compactMap(self.map(_:)).first
        }
    }

    public func events(for babyID: UUID, in interval: DateInterval?) async throws -> [EventDTO] {
        // Note: Baby relationship not yet implemented in Core Data model
        // For now, return all events. This will be updated when Baby-Event relationship is added
        try await events(in: interval, kind: nil)
    }

    public func stats(for day: Date) async throws -> EventDayStats {
        let events = try await events(on: day, calendar: calendar)
        let totalDuration = events.reduce(0) { partialResult, event in
            partialResult + event.duration
        }
        return EventDayStats(date: calendar.startOfDay(for: day), totalEvents: events.count, totalDuration: totalDuration)
    }

    public func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        try await perform { context in
            var created: [EventDTO] = []

            for dto in dtos {
                let object = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
                let now = Date()
                object.setValue(dto.id, forKey: "id")
                object.setValue(dto.kind.rawValue, forKey: "kind")
                object.setValue(dto.start, forKey: "start")
                object.setValue(dto.end, forKey: "end")
                object.setValue(dto.notes, forKey: "notes")
                object.setValue(dto.createdAt, forKey: "createdAt")
                object.setValue(now, forKey: "updatedAt")
                object.setValue(false, forKey: "isSynced")
                object.setValue(false, forKey: "isDeleted")

                if let mapped = self.map(object) {
                    created.append(mapped)
                }
            }

            // Single save for all objects (performance optimization)
            try context.saveIfNeeded()
            return created
        }
    }

    public func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        try await perform { context in
            var updated: [EventDTO] = []
            let now = Date()

            for dto in dtos {
                guard let object = try self.fetchObject(id: dto.id, in: context) else {
                    throw EventsRepositoryError.notFound
                }

                object.setValue(dto.kind.rawValue, forKey: "kind")
                object.setValue(dto.start, forKey: "start")
                object.setValue(dto.end, forKey: "end")
                object.setValue(dto.notes, forKey: "notes")
                object.setValue(dto.isDeleted, forKey: "isDeleted")
                object.setValue(now, forKey: "updatedAt")

                if let mapped = self.map(object) {
                    updated.append(mapped)
                }
            }

            // Single save for all objects (performance optimization)
            try context.saveIfNeeded()
            return updated
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
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func map(_ object: NSManagedObject) -> EventDTO? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let kindString = object.value(forKey: "kind") as? String,
            let kind = EventKind(rawValue: kindString),
            let start = object.value(forKey: "start") as? Date,
            let createdAt = object.value(forKey: "createdAt") as? Date,
            let updatedAt = object.value(forKey: "updatedAt") as? Date
        else { return nil }

        let end = object.value(forKey: "end") as? Date
        let notes = object.value(forKey: "notes") as? String
        let synced = object.value(forKey: "isSynced") as? Bool ?? false
        let deleted = object.value(forKey: "isDeleted") as? Bool ?? false

        return EventDTO(
            id: id,
            kind: kind,
            start: start,
            end: end,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: synced,
            isDeleted: deleted
        )
    }
}

private extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}
