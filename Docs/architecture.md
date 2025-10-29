# Architecture

```
+---------------------------------------------+
|                   BabyTrack                 |
|  SwiftUI TabView + AppEnvironment (DI)      |
+---------------------------+-----------------+
                            |
                            v
+---------------+      +-----------+      +-------------+
|  Feature SPM  |----->| Core Data |<---->| CloudKit     |
|  modules      |      | persistent|      | Sync Service |
|  (Tracking,   |      | store      |      | (Sync pkg)   |
|  Measurements,|      +-----------+      +-------------+
|  Paywall, ...) |             ^                    |
+-------+--------+             |                    v
        |                      |           +------------------+
        v                      |           | Shared App Group |
+---------------+              |           | Widgets/WatchApp |
|  DesignSystem |              |           +------------------+
|  + Content    |              |
+---------------+              |
        |                      |
        v                      |
+---------------+              |
|   UI Surfaces |--------------+
| (App, Widgets,|
|  Watch)       |
+---------------+
```

- **AppEnvironment** injects repositories and services into SwiftUI and watchOS layers.
- **Tracking/Measurements** expose repository protocols while Core Data implementations remain inside `Internal`.
- **Sync** encapsulates CloudKit mapping, change-token storage, and conflict resolution.
- **Widgets** and **WatchApp** use the shared store through the App Group container.
- **DesignSystem/Content** deliver consistent visuals and localization resources.
