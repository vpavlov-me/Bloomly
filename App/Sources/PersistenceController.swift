//
//  PersistenceController.swift
//  BabyTrack
//
//  NSPersistentCloudKitContainer configuration for BabyTrack.
//

import CoreData

public struct PersistenceController {
    public static let modelName = "BabyTrackModel"
    public static let shared = PersistenceController()

    public let container: NSPersistentCloudKitContainer

    public init(inMemory: Bool = false) {
        let bundle = Bundle(for: BundleToken.self)
        let modelURL = bundle.url(forResource: PersistenceController.modelName, withExtension: "momd")
        let managedObjectModel: NSManagedObjectModel
        if let modelURL, let model = NSManagedObjectModel(contentsOf: modelURL) {
            managedObjectModel = model
        } else {
            managedObjectModel = NSManagedObjectModel()
        }

        container = NSPersistentCloudKitContainer(name: PersistenceController.modelName, managedObjectModel: managedObjectModel)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        } else {
            container.persistentStoreDescriptions = container.persistentStoreDescriptions.map { description in
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.example.BabyTrack")
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                return description
            }
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}

private final class BundleToken {}
