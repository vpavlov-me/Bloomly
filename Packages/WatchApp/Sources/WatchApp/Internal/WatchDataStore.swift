//
//  WatchDataStore.swift
//  BabyTrack
//
//  Shared Core Data access for watchOS extension via App Group store.
//

import CoreData
import Foundation
import Sync
import Tracking

open class WatchDataStore: ObservableObject {
    private let container: NSPersistentCloudKitContainer

    @Published public private(set) var events: [Event] = []

    public init(container: NSPersistentCloudKitContainer = PersistentContainerFactory.makeContainer(
        modelName: "BabyTrackModel",
        appGroupIdentifier: "group.com.example.BabyTrack",
        containerIdentifier: "iCloud.com.example.BabyTrack"
    )) {
        self.container = container
    }

    open func fetchRecentEvents(limit: Int = 10) {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        request.fetchLimit = limit
        do {
            let objects = try context.fetch(request)
            events = objects.compactMap(Self.mapEvent(object:))
        } catch {
            events = []
        }
    }

    open func log(kind: EventKind) {
        let context = container.viewContext
        let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
        let now = Date()
        event.setValue(UUID(), forKey: "id")
        event.setValue(kind.rawValue, forKey: "kind")
        event.setValue(now, forKey: "start")
        event.setValue(now, forKey: "end")
        event.setValue(nil, forKey: "notes")
        event.setValue(now, forKey: "createdAt")
        event.setValue(now, forKey: "updatedAt")
        event.setValue(false, forKey: "isSynced")
        try? context.save()
        fetchRecentEvents()
    }

    private static func mapEvent(object: NSManagedObject) -> Event? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let kindValue = object.value(forKey: "kind") as? String,
            let kind = EventKind(rawValue: kindValue),
            let start = object.value(forKey: "start") as? Date,
            let createdAt = object.value(forKey: "createdAt") as? Date,
            let updatedAt = object.value(forKey: "updatedAt") as? Date
        else { return nil }
        let notes = object.value(forKey: "notes") as? String
        let end = object.value(forKey: "end") as? Date
        let isSynced = object.value(forKey: "isSynced") as? Bool ?? false
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
}
