# Architecture

```
+--------------------+       +-------------------+
|        App         |<----->|   AppEnvironment  |
+--------------------+       +-------------------+
          |                               |
          v                               v
+--------------------+        +-------------------+
|   Feature Modules  |        |   Persistence     |
| (Tracking, etc.)   |        | CoreData/CloudKit |
+--------------------+        +-------------------+
          |                               |
          v                               v
+--------------------+        +-------------------+
|   Widgets/Watch    |        |   External APIs   |
+--------------------+        +-------------------+
```

- **Feature Modules** expose public protocols. Implementations remain internal.
- **AppEnvironment** wires dependencies and exposes them via `ObservableObject` for SwiftUI usage.
- **Sync** coordinates repositories and CloudKit.
- **DesignSystem + Content** provide shared UI + localization resources.
- **Tests** live alongside modules using XCTest and SnapshotTesting.
