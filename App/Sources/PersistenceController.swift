//
//  PersistenceController.swift
//  BabyTrack
//
//  NSPersistentCloudKitContainer configuration for BabyTrack.
//

import CoreData
import Sync

public struct PersistenceController {
    public static let modelName = "BabyTrackModel"
    public static let shared = PersistenceController()

    public let container: NSPersistentCloudKitContainer

    public init(inMemory: Bool = false) {
        container = PersistentContainerFactory.makeContainer(
            modelName: Self.modelName,
            appGroupIdentifier: "group.com.example.BabyTrack",
            containerIdentifier: "iCloud.com.example.BabyTrack",
            inMemory: inMemory
        )
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
