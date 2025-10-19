//
//  PersistentContainerFactory.swift
//  BabyTrack
//
//  Provides shared NSPersistentCloudKitContainer configured for App Group + CloudKit.
//

import CoreData
import Foundation

public enum PersistentContainerFactory {
    public static func makeContainer(
        modelName: String,
        appGroupIdentifier: String,
        containerIdentifier: String,
        inMemory: Bool = false
    ) -> NSPersistentCloudKitContainer {
        let managedObjectModel = loadModel(named: modelName)
        let container = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: managedObjectModel)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            let storeURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
                .appendingPathComponent("\(modelName).sqlite")
            let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
            if let storeURL {
                description.url = storeURL
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                container.persistentStoreDescriptions = [description]
            } else {
                description.type = NSInMemoryStoreType
                container.persistentStoreDescriptions = [description]
            }
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Persistent store loading failed: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }

    private static func loadModel(named modelName: String) -> NSManagedObjectModel {
        if let bundle = Bundle(identifier: "com.example.babytrack"),
           let url = bundle.url(forResource: modelName, withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: url) {
            return model
        }
        let bundles = [Bundle.main, Bundle.module]
        for bundle in bundles {
            if let url = bundle.url(forResource: modelName, withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }
        return makeDefaultModel()
    }
}

private func makeDefaultModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()

    let eventEntity = NSEntityDescription()
    eventEntity.name = "Event"
    eventEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
    eventEntity.properties = [
        attribute(name: "id", type: .UUIDAttributeType, optional: false),
        attribute(name: "kind", type: .stringAttributeType, optional: false),
        attribute(name: "start", type: .dateAttributeType, optional: false),
        attribute(name: "end", type: .dateAttributeType, optional: true),
        attribute(name: "notes", type: .stringAttributeType, optional: true),
        attribute(name: "createdAt", type: .dateAttributeType, optional: false),
        attribute(name: "updatedAt", type: .dateAttributeType, optional: false),
        attribute(name: "isSynced", type: .booleanAttributeType, optional: false, defaultValue: false)
    ]

    let measurementEntity = NSEntityDescription()
    measurementEntity.name = "Measurement"
    measurementEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
    measurementEntity.properties = [
        attribute(name: "id", type: .UUIDAttributeType, optional: false),
        attribute(name: "type", type: .stringAttributeType, optional: false),
        attribute(name: "value", type: .doubleAttributeType, optional: false),
        attribute(name: "unit", type: .stringAttributeType, optional: false),
        attribute(name: "date", type: .dateAttributeType, optional: false),
        attribute(name: "isSynced", type: .booleanAttributeType, optional: false, defaultValue: false)
    ]

    model.entities = [eventEntity, measurementEntity]
    return model
}

private func attribute(name: String, type: NSAttributeType, optional: Bool, defaultValue: Any? = nil) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = type
    attribute.isOptional = optional
    if let defaultValue {
        attribute.defaultValue = defaultValue
    }
    return attribute
}
