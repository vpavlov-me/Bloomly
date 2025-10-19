//
//  WidgetDataProvider.swift
//  BabyTrack
//
//  Fetches shared Core Data snapshots for widgets via App Group store.
//

import CoreData
import Foundation
import Sync
import Tracking

struct WidgetDataProvider {
    private static let sharedContainer: NSPersistentCloudKitContainer = PersistentContainerFactory.makeContainer(
        modelName: Constants.modelName,
        appGroupIdentifier: Constants.appGroup,
        containerIdentifier: Constants.containerIdentifier
    )

    private let container: NSPersistentCloudKitContainer

    init(container: NSPersistentCloudKitContainer = WidgetDataProvider.sharedContainer) {
        self.container = container
    }

    func lastFeedSummary() -> String {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        request.predicate = NSPredicate(format: "kind == %@", EventKind.feed.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        request.fetchLimit = 1
        let date = (try? context.fetch(request).first?.value(forKey: "start") as? Date) ?? Date()
        let interval = Date().timeIntervalSince(date)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "--"
    }

    func todaySleepDuration() -> TimeInterval {
        let context = container.viewContext
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "kind == %@", EventKind.sleep.rawValue),
            NSPredicate(format: "start >= %@", startOfDay as NSDate)
        ])
        let events = (try? context.fetch(request)) ?? []
        return events.reduce(0) { sum, object in
            let start = object.value(forKey: "start") as? Date ?? Date()
            let end = object.value(forKey: "end") as? Date ?? Date()
            return sum + end.timeIntervalSince(start)
        }
    }
}

private enum Constants {
    static let modelName = "BabyTrackModel"
    static let appGroup = "group.com.example.BabyTrack"
    static let containerIdentifier = "iCloud.com.example.BabyTrack"
}
