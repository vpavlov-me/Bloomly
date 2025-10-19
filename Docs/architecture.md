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

- **AppEnvironment** прокидывает зависимости (репозитории, сервисы) в SwiftUI и watchOS слоях.
- **Tracking/Measurements** хранят протоколы репозиториев, Core Data реализации скрыты во `Internal`.
- **Sync** инкапсулирует CloudKit маппинг, отслеживание изменений и будущие конфликты.
- **Widgets** и **WatchApp** получают доступ к общему стору через App Group контейнер.
- **DesignSystem/Content** обеспечивают единый внешний вид и локализацию.
