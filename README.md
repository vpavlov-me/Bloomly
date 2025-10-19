# BabyTrack

Bloomly — это нативное iOS‑приложение для отслеживания сна, кормлений, подгузников, роста и других событий младенца. Проект фокусируется на минималистичном UX, оффлайн‑первом подходе и прозрачной архитектуре SwiftUI + Core Data + CloudKit.

## Tech Stack
- SwiftUI • Combine • Swift Concurrency
- Core Data + NSPersistentCloudKitContainer
- CloudKit (private DB) + App Groups
- WidgetKit + App Intents (timelines)
- watchOS 10 companion (SwiftUI)
- StoreKit 2 subscriptions
- Swift Charts visualisations
- XCTest + SnapshotTesting
- Tuist driven modular build

## Modules
| Package | Responsibility |
| --- | --- |
| `DesignSystem` | Типографика, отступы, базовые SwiftUI компоненты |
| `Content` | Локализации, ассеты, строковые ресурсы |
| `Tracking` | Доменные модели событий, Core Data репозиторий |
| `Measurements` | Измерения роста/веса, графики и вычисления |
| `Timeline` | Агрегация событий и измерений, представление ленты |
| `Paywall` | StoreKit 2 обертки и paywall UI |
| `Sync` | CloudKit синхронизация, маппинг записей |
| `Widgets` | Виджеты «Последнее кормление» и «Сон сегодня» |
| `WatchApp` | UI для watchOS, быстрые действия |

## Getting Started
1. `brew install tuist swiftlint` (при необходимости)
2. `tuist install` (скачает совместимую версию)
3. `tuist generate`
4. Откройте `BabyTrack.xcworkspace`
5. В Xcode задайте Signing Team (`ABCDE12345` — placeholder) и при необходимости измените bundle ID (`com.example.*`).
6. Включите iCloud контейнер `iCloud.com.example.BabyTrack` и App Group `group.com.example.BabyTrack` для приложения, виджета и watch extension.
7. Запустите на iOS 17+ симуляторе, активируйте фоновые обновления (Background fetch).

### Tests
```bash
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallelizeTargets \
  -skipPackagePluginValidation build

xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrackTests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallelizeTargets \
  -skipPackagePluginValidation test
```
Для snapshot-тестов используйте `record` флаги из `SnapshotTesting` при первом запуске (`SNAPSHOT_RECORD=1`).

## CloudKit & StoreKit
- Активируйте iCloud capability и создайте контейнер через Developer Portal.
- В CloudKit Dashboard создайте record types `Event` и `Measurement` с полями `id`, `payload`, `updatedAt`.
- Продвигайте схему из dev в prod перед релизом.
- StoreKit 2 продукты: `com.example.babytrack.premium.monthly`, `com.example.babytrack.premium.annual`. Добавьте в App Store Connect и протестируйте с sandbox-аккаунтами.

## Roadmap
- [x] Tuist workspace и модульная структура
- [x] Core Data + CloudKit scaffold
- [x] Paywall с StoreKit 2
- [x] WidgetKit + WatchOS связка
- [x] Snapshot/Unit тесты
- [ ] Полноценная CloudKit pull-синхронизация
- [ ] Реальные WHO percentile данные
- [ ] Продакшен аналитика и A/B тесты paywall

## License
MIT. См. файл [LICENSE](LICENSE).
