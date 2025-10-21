# BabyTrack

BabyTrack — модульный SwiftUI-проект для отслеживания сна, кормлений, смен подгузников и измерений роста малыша. Архитектура ориентирована на оффлайн-первый опыт, локальное хранение через Core Data с последующей синхронизацией в CloudKit, а также на единый дизайн-слой и переиспользуемые фиче-модули для iOS, watchOS и WidgetKit.

## Основные возможности
- **Журнал событий** (сон, кормление, подгузник) с локальным хранением, заметками и последующей CloudKit-синхронизацией.
- **Лента таймлайна** с агрегацией событий и измерений, быстрыми действиями и Swift Charts для роста/веса.
- **WHO перцентили** — графики роста с эталонными кривыми ВОЗ (Premium feature).
- **Data Export** — экспорт всех данных в CSV или JSON для резервного копирования.
- **Toast уведомления** для пользовательского feedback при операциях CRUD.
- **WidgetKit виджеты** «Последнее кормление» и «Сон сегодня» на общих данных App Group.
- **watchOS 10 companion** с быстрым логированием и списком последних событий.
- **Paywall на StoreKit 2** с обработкой покупок/восстановлений, дизайн-система и DI-контейнер на уровне приложения.

## Tech Stack
- Swift 5.10, SwiftUI, modern concurrency (async/await)
- Core Data + NSPersistentCloudKitContainer, App Groups
- CloudKit (Private DB) с production-grade sync implementation
- WidgetKit, watchOS 10, Swift Charts
- StoreKit 2, Storefront paywall
- XCTest и SnapshotTesting
- Tuist workspace, Swift Package Manager feature-модули

## Модули
| Package | Responsibility |
| --- | --- |
| `DesignSystem` | Цвета, типографика, карточки, Toast, переиспользуемые UI-компоненты |
| `Content` | Локализации (en/ru), SF Symbols, текстовые ресурсы |
| `Tracking` | Event-модель, Core Data репозиторий, форма логирования |
| `Measurements` | Измерения, графики роста, WHO percentiles, формирование выборок |
| `Timeline` | Объединение событий/измерений в секции, SwiftUI интерфейс |
| `Paywall` | StoreKit 2 клиент, Premium состояние, UI и снапшоты |
| `Sync` | CloudKit production sync: pull/push/conflict resolution |
| `Widgets` | WidgetKit провайдеры, App Group стор, виджеты «Feed/Sleep» |
| `WatchApp` | watchOS: быстрый лог, события, измерения |

## Getting Started

> Быстро: `./scripts/bootstrap.sh` — установит Tuist (если нужно), сгенерирует workspace и разрешит зависимости.

1. Необходим Xcode 16 + iOS 17 / watchOS 10 SDK.
2. Установите инструменты: `brew install tuist swiftlint`.
3. `tuist install` — подтянет совместимую версию (см. `Tuist/Config.swift`).
4. `tuist generate` для сборки `BabyTrack.xcworkspace`.
5. Откройте workspace и назначьте свою команду (placeholder Team ID `ABCDE12345`).
6. При необходимости обновите bundle prefix `com.example`.
7. Включите iCloud контейнер `iCloud.com.example.BabyTrack` и App Group `group.com.example.BabyTrack` во всех таргетах.
8. Для StoreKit 2 заведите продукты `com.example.babytrack.premium.monthly` и `com.example.babytrack.premium.yearly`.

## Tests & QA

```bash
# Build приложение
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallelizeTargets \
  -skipPackagePluginValidation build

# Все модульные тесты (включая snapshot)
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallelizeTargets \
  -skipPackagePluginValidation test
```

### Snapshot Testing
- **Запись эталонов**: `SNAPSHOT_RECORD=1 xcodebuild ... test` — создаст/обновит reference images в `Tests/__Snapshots__`.
- **Проверка**: Без переменной окружения тесты сравнят текущий UI с эталонными снимками.
- **CI**: В GitHub Actions snapshot тесты запускаются в режиме сравнения; при неудаче артефакты загружаются автоматически.

### In-Memory Storage
- Репозитории используют `PersistenceController(inMemory: true)` для unit-тестов и превью.
- Это позволяет изолировать тесты и не засорять production database.
- Используйте `.preview` для SwiftUI previews.

## Premium & Paywall
- Premium состояние хранится в `@AppStorage("isPremium")` и доступно через `Paywall.PremiumState`.
- **Premium Features:**
  - WHO перцентильные кривые на графиках роста
  - Head circumference трекинг
  - Advanced analytics (планируется)
- Paywall открывается из Settings → Manage Subscription.
- StoreKit 2 клиент (`StoreClient`) покрывает загрузку, покупку, restore и проверку entitlement.

## Data Export
Приложение поддерживает экспорт всех данных для резервного копирования или миграции:
- **CSV Export**: События и измерения в табличном формате
- **JSON Export**: Structured JSON с метаданными экспорта
- Доступ: Settings → Export Data → выбрать формат
- Экспортированные файлы можно поделиться через Share Sheet

## CloudKit Sync
Production-ready CloudKit синхронизация реализована с:
- **Pull Changes**: Инкрементальная загрузка через `CKFetchRecordZoneChangesOperation`
- **Push Pending**: Отправка unsynchronized записей с `CKModifyRecordsOperation`
- **Conflict Resolution**: Last-write-wins стратегия на основе `modificationDate`
- **Change Token**: Хранение server change token для эффективной синхронизации
- **Background Sync**: Extension points для BGTaskScheduler (TODO: активация)

### CloudKit Setup
1. Включите iCloud capability в Xcode
2. Создайте CloudKit Container: `iCloud.com.example.BabyTrack`
3. Настройте Private Database schema:
   - Record Types: `Event`, `Measurement`
   - Включите CloudKit в Core Data model
4. Deploy schema в production environment

## Error Handling & UX
- **Toast Notifications**: Все CRUD операции показывают success/error toast
- **Graceful Fallbacks**: Нет force unwraps, все optionals обрабатываются
- **Loading States**: ProgressView во время async операций
- **Empty States**: Кастомные EmptyStateView для пустых списков

## Документация
- `Docs/architecture.md` — диаграмма потоков данных и слои модулей.
- `Docs/cloudkit.md` — пошаговая настройка iCloud, schema deploy.
- `Docs/file-tree.md` — актуальная структура репозитория.
- `Docs/github-workflow.md` — правила работы с GitHub, ветки, PR, релизы.

## Автоматизация
- GitHub Actions: `CI` (сборка + тесты), `SwiftLint`, `Actionlint`, `Stale Issues`.
- Release Drafter автоматически собирает черновики релизов по меткам.
- PR Labeler и Auto Assign распределяют метки и ревьюров на основе путей.
- Dependabot создаёт PR с обновлениями SwiftPM и GitHub Actions зависимостей и сам мержит patch-обновления.
- Labels Sync держит набор меток в актуальном состоянии из `.github/labels.yml`.

## Контрибьютинг
- Перед первым вкладом прочтите [CONTRIBUTING.md](CONTRIBUTING.md) — там описан рабочий процесс, требования к веткам и тестам.
- Мы придерживаемся [кодекса поведения](CODE_OF_CONDUCT.md).
- Для багов и фич используйте готовые issue шаблоны в GitHub.

## Roadmap
- [x] Tuist workspace и модульная SPM-структура
- [x] Core Data + CloudKit scaffold
- [x] Paywall с StoreKit 2 и snapshot-тестами
- [x] WidgetKit + watchOS внедрение
- [x] Unit/UI/Snapshot тесты и CI workflow
- [x] Production CloudKit sync (pull/push/conflicts)
- [x] WHO percentiles и расширенные графики
- [x] Data Export (CSV/JSON)
- [x] Toast notifications и error handling
- [ ] Background sync с BGTaskScheduler
- [ ] Advanced analytics dashboard
- [ ] A/B paywall сценарии

## License
MIT. См. `LICENSE`.
