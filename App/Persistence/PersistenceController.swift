import CoreData
import os.log

public final class PersistenceController {
    public static let shared = PersistenceController()
    public static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        controller.populatePreviewData()
        return controller
    }()

    public let container: NSPersistentCloudKitContainer
    public var viewContext: NSManagedObjectContext { container.viewContext }

    public init(inMemory: Bool = false, bundle: Bundle = .main) {
        let modelName = "BabyTrackModel"
        container = NSPersistentCloudKitContainer(name: modelName)

        let storeURL: URL
        if inMemory {
            storeURL = URL(fileURLWithPath: "/dev/null")
        } else {
            // Prefer App Group container, fall back to app support directory
            let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.babytrack")
            let defaultURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let url = appGroupURL ?? defaultURL ?? FileManager.default.temporaryDirectory
            storeURL = url.appendingPathComponent("BabyTrack.sqlite")
        }

        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        description.url = storeURL
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if let identifier = bundle.object(forInfoDictionaryKey: "CloudKitContainerIdentifier") as? String, !identifier.isEmpty {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: identifier)
        }

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                os_log("Unresolved Core Data error: %{public}@", log: .default, type: .fault, error.localizedDescription)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.undoManager = nil
        return context
    }
}

private extension PersistenceController {
    func populatePreviewData() {
        let context = container.viewContext
        let calendar = Calendar.current
        let now = Date()
        for offset in 0..<6 {
            let date = calendar.date(byAdding: .day, value: -offset, to: now) ?? now
            let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
            event.setValue(UUID(), forKey: "id")
            event.setValue(["sleep", "feed", "diaper"].randomElement() ?? "sleep", forKey: "kind")
            let start = calendar.date(byAdding: .hour, value: -Int.random(in: 1...4), to: date) ?? date
            let end = calendar.date(byAdding: .minute, value: Int.random(in: 20...90), to: start)
            event.setValue(start, forKey: "start")
            event.setValue(end, forKey: "end")
            event.setValue("Sample note", forKey: "notes")
            event.setValue(date, forKey: "createdAt")
            event.setValue(date, forKey: "updatedAt")
            event.setValue(false, forKey: "isSynced")
        }

        for offset in 0..<5 {
            let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
            measurement.setValue(UUID(), forKey: "id")
            measurement.setValue(["height", "weight", "head"].randomElement() ?? "height", forKey: "type")
            measurement.setValue(Double.random(in: 48...80), forKey: "value")
            measurement.setValue("cm", forKey: "unit")
            measurement.setValue(calendar.date(byAdding: .day, value: -offset, to: now), forKey: "date")
            measurement.setValue(false, forKey: "isSynced")
        }

        try? context.save()
    }
}

public extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}
