# CloudKit Setup

1. Включите **iCloud > CloudKit** capability для App, Widget, Watch Extension. Используйте контейнер `iCloud.com.example.BabyTrack` и App Group `group.com.example.BabyTrack`.
2. На [developer.apple.com](https://developer.apple.com) создайте контейнер и назначьте его bundle ID.
3. В CloudKit Dashboard:
   - Перейдите в Environment: Development.
   - Создайте record types `Event`, `Measurement` с полями:
     - `id` (String, indexed)
     - `payload` (Bytes, large)
     - `updatedAt` (Date, indexed)
   - Убедитесь, что запись доступна Private Database.
4. Синхронизируйте схему (`Deploy Schema to Production`) перед релизом.
5. Для тестирования используйте CK Dashboard data reset, sandbox аккаунты и запуск `AppEnvironment.syncService.pushPending()`.
6. Для rollback используйте версионирование схем CloudKit и бэкап Core Data стора.
