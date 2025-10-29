# CloudKit Setup

BabyTrack relies on a dedicated CloudKit zone to synchronise Core Data entities. Follow the checklist below before running on device or shipping a build.

1. Enable the **iCloud > CloudKit** capability for the App, Widget, and Watch Extension. Use the container `iCloud.com.example.BabyTrack` and the App Group `group.com.example.babytrack`.
2. In the [Apple Developer portal](https://developer.apple.com), create the container and link it to the bundle identifier.
3. In CloudKit Dashboard (Private Database, Development environment):
   - Create record type **Event** with fields:
     - `kind` (String, Queryable)
     - `start` (Date, Queryable)
     - `end` (Date, optional)
     - `notes` (String, optional)
     - `createdAt` (Date)
     - `updatedAt` (Date, Queryable)
     - `isDeleted` (Int64 or Boolean)
   - Create record type **Measurement** with fields:
     - `type` (String, Queryable)
     - `value` (Double)
     - `unit` (String)
     - `date` (Date, Queryable)
     - `notes` (String, optional)
4. Deploy the schema (`Deploy Schema to Production`) before releasing.
5. For testing use CK Dashboard data reset, sandbox accounts, and trigger `AppEnvironment.syncService.pushPending()`.
6. For rollbacks rely on CloudKit schema versioning and backups of the Core Data store.
7. Add `com.example.babytrack.sync` to the app’s `Permitted background task scheduler identifiers` in Info.plist so BGTaskScheduler can refresh the zone.
