# BabyTrack

BabyTrack - нативное iOS приложение для отслеживания сна, кормлений, смен подгузника, роста и других событий младенца. Проект ориентирован на минималистичный UX, оффлайн-первый подход и прозрачную архитектуру на SwiftUI + Core Data с синхронизацией через CloudKit. Помимо основного приложения включены companion widgets, watchOS-клиент и монетизация через StoreKit 2.

## Основные возможности
- Журнал событий (сон, кормления, подгузники) с локальным хранением, отметками времени, заметками и последующей синхронизацией.
- Лента дневника с агрегацией событий и измерений, быстрыми действиями и доступом к историческим данным.
- Ростовые измерения c вычислением перцентилей, поддержкой нескольких типов (height, weight, head) и визуализациями на Swift Charts.
- WidgetKit виджеты «Последнее кормление» и «Сон сегодня», а также watchOS 10 приложение с быстрым логированием.
- StoreKit 2 paywall, кастомный дизайн-системный слой и централизованная AppEnvironment DI.

## Tech Stack
- SwiftUI, Combine, Swift Concurrency
- Core Data + NSPersistentCloudKitContainer (App Group storage)
- CloudKit (Private DB) + кастомный SyncService
- WidgetKit + App Intents timelines
- watchOS 10 companion (SwiftUI)
- StoreKit 2 subscriptions
- Swift Charts visualisations
- Tuist-driven modular workspace (Xcode 16), SwiftLint, XCTest + SnapshotTesting
- GitHub Actions CI с матрицей таргетов

## Modules
| Package | Responsibility |
| --- | --- |
| `DesignSystem` | Типографика, цветовые и отступные токены, базовые SwiftUI компоненты и layout-хелперы |
| `Content` | Локализации, доступ к ассетам, текстовые ресурсы |
| `Tracking` | Доменные модели событий, Core Data репозиторий, change tracking для Sync |
| `Measurements` | Измерения роста/веса, перцентильные вычисления, Swift Charts вью |
| `Timeline` | Вью и ViewModel для таймлайна, агрегация событий и измерений |
| `Paywall` | StoreKit 2 клиенты, витрина подписок и paywall UI |
| `Sync` | CloudKit синхронизация, маппер записей и управление конфликтами |
| `Widgets` | Виджеты «Последнее кормление» и «Сон сегодня», работа через App Group стор |
| `WatchApp` | watchOS 10 UI, WatchDataStore с быстрым логированием и синхронизацией |

## Getting Started

> Быстрая альтернатива: запустите `./scripts/bootstrap.sh`, чтобы установить Tuist, сгенерировать workspace и разрешить зависимости.

1. Убедитесь, что установлен Xcode 16 с iOS 17 SDK.
2. `brew install tuist swiftlint` (при необходимости).
3. `tuist install` - подтянет совместимую версию (см. `Tuist/Config.swift`).
4. `tuist generate` для создания `BabyTrack.xcworkspace`.
5. Откройте `BabyTrack.xcworkspace` в Xcode.
6. В Signing настройте Team (placeholder `ABCDE12345`) и при необходимости измените bundle ID `com.example.*`.
7. Включите iCloud контейнер `iCloud.com.example.BabyTrack` и App Group `group.com.example.BabyTrack` для приложения, виджета и watch extension.
8. Запустите на iOS 17+ симуляторе или устройстве, включите Background Fetch для корректной работы таймлайна.

## Tests

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

Для snapshot-тестов используйте `SNAPSHOT_RECORD=1`. В CI используется `.github/workflows/ci.yml` с матрицей для iOS и watchOS.

## CloudKit & StoreKit

- Активируйте iCloud capability и создайте контейнер через Developer Portal (подробности в `Docs/cloudkit.md`).
- В CloudKit Dashboard создайте record types `Event` и `Measurement` с полями `id`, `payload`, `updatedAt`; продвигайте схему из development в production перед релизом.
- StoreKit 2 продукты: `com.example.babytrack.premium.monthly`, `com.example.babytrack.premium.annual`. Добавьте их в App Store Connect и тестируйте на sandbox-аккаунтах.
- Пуш синхронизация доступна, pull-цикл пока в разработке (см. `Sync`).

## Документация

- `Docs/architecture.md` - обзор модульной архитектуры и потоков данных.
- `Docs/cloudkit.md` - пошаговая настройка CloudKit.
- `Docs/file-tree.md` - актуальная структура репозитория.

## Roadmap

- [x] Tuist workspace и модульная структура
- [x] Core Data + CloudKit scaffold
- [x] Paywall с StoreKit 2
- [x] WidgetKit + watchOS связка
- [x] Snapshot/Unit тесты
- [ ] Полноценная CloudKit pull-синхронизация
- [ ] Реальные WHO percentile данные
- [ ] Продакшен аналитика и A/B тесты paywall

## License

MIT. См. `LICENSE`.
