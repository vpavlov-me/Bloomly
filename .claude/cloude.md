# bloomy - Конфигурация Claude Code

## 📱 О проекте
bloomy — модульный iOS/watchOS проект для отслеживания развития малыша, построенный на SwiftUI, Core Data, CloudKit и Tuist.

---

## 🤖 Правила использования AI агентов

### Приоритетные агенты для проекта

#### 1. mobile-app-builder (ОСНОВНОЙ)
**Когда использовать:**
- Любая работа с iOS/watchOS функциональностью
- Оптимизация производительности UI
- Интеграция нативных фич (CloudKit, StoreKit, WidgetKit)
- Работа со SwiftUI и UIKit
- App Store оптимизация

**Примеры задач:**
```
"Добавь новый экран статистики сна"
"Оптимизируй производительность списка событий"
"Реализуй push-уведомления для напоминаний"
"Добавь биометрическую аутентификацию"
"Интегрируй HealthKit для синхронизации данных"
```

#### 2. test-writer-fixer
**Когда использовать:**
- Написание unit/UI/snapshot тестов
- Исправление падающих тестов
- Повышение test coverage
- Refactoring тестов

**Примеры задач:**
```
"Напиши тесты для CloudSyncRepository"
"Исправь падающие snapshot тесты в Paywall"
"Увеличь покрытие тестами для Timeline модуля"
"Создай integration тесты для Core Data sync"
```

#### 3. rapid-prototyper
**Когда использовать:**
- Быстрое прототипирование новых фич
- MVP реализации
- Proof of concept
- Эксперименты с новыми подходами

**Примеры задач:**
```
"Создай прототип AI-рекомендаций для сна на основе паттернов"
"Быстро проверь идею с AR измерениями роста ребенка"
"Сделай MVP темной темы для всего приложения"
"Прототипируй social sharing функционал"
```

#### 4. ui-designer
**Когда использовать:**
- Работа с DesignSystem
- Создание/улучшение UI компонентов
- Визуальная полировка
- Accessibility улучшения

**Примеры задач:**
```
"Улучши дизайн карточек событий в Timeline"
"Создай новый компонент для интерактивных графиков"
"Добавь smooth анимации в переходы между экранами"
"Улучши accessibility для VoiceOver пользователей"
```

#### 5. backend-architect
**Когда использовать:**
- Работа с Core Data схемой
- CloudKit интеграция
- Оптимизация sync логики
- Архитектурные решения для data layer

**Примеры задач:**
```
"Оптимизируй CloudKit sync для больших объемов данных"
"Спроектируй миграцию Core Data модели для новых полей"
"Улучши conflict resolution стратегию при синхронизации"
"Реализуй background sync с BGTaskScheduler"
```

#### 6. app-store-optimizer
**Когда использовать:**
- Подготовка к релизу
- Оптимизация метаданных App Store
- ASO (App Store Optimization)
- Работа со скриншотами и описаниями

**Примеры задач:**
```
"Подготовь описание приложения для App Store на русском и английском"
"Оптимизируй ключевые слова для ASO"
"Создай план beta-тестирования через TestFlight"
"Напиши release notes для версии 1.0"
```

#### 7. devops-automator
**Когда использовать:**
- CI/CD оптимизация
- Автоматизация сборок
- GitHub Actions workflows
- Скрипты деплоя

**Примеры задач:**
```
"Настрой автоматический деплой в TestFlight при merge в main"
"Оптимизируй время CI сборки"
"Добавь автоматическую проверку code coverage в CI"
"Создай скрипт для генерации release notes"
```

#### 8. performance-benchmarker
**Когда использовать:**
- Профилирование производительности
- Оптимизация memory usage
- Анализ battery impact
- Поиск bottlenecks

**Примеры задач:**
```
"Проанализируй memory leaks в Timeline view"
"Оптимизируй startup time приложения до <2 секунд"
"Измерь влияние CloudKit sync на батарею"
"Профилируй производительность списка с 10000+ событий"
```

### Вспомогательные агенты

#### product/sprint-prioritizer
- Планирование спринтов
- Приоритизация фич
- Roadmap planning

#### project-management/project-shipper
- Подготовка релизов
- Pre-launch чеклисты
- Release notes

#### studio-operations/analytics-reporter
- Анализ метрик
- Отчеты по использованию
- A/B тестирование

---

## 📋 Правила работы с кодом

### Архитектура
1. **Модульность**: Все новые фичи должны быть в отдельных Swift Package модулях
2. **DI**: Используй Dependency Injection через init параметры
3. **Offline-first**: Все операции должны работать без сети
4. **Repository pattern**: Core Data доступ только через репозитории

### Code Style
1. SwiftLint правила в `.swiftlint.yml`
2. Swift 5.10 modern concurrency (async/await)
3. SwiftUI declarative style
4. No force unwraps, graceful error handling

### Testing
1. Все публичные API должны иметь тесты
2. Snapshot тесты для UI компонентов
3. In-memory storage для unit тестов
4. Coverage target: >70%

### Commit & Deploy
1. Conventional commits: `feat:`, `fix:`, `test:`, `refactor:`
2. Все тесты должны проходить перед коммитом
3. CI проверяет build + tests + SwiftLint

---

## 🏗️ Специфика проекта

### Tech Stack
- Swift 5.10, SwiftUI
- Tuist для workspace management
- Core Data + CloudKit (NSPersistentCloudKitContainer)
- StoreKit 2 для Premium
- WidgetKit, watchOS 10
- Swift Charts для графиков

### Модули проекта
| Модуль | Назначение |
|--------|-----------|
| `DesignSystem` | UI компоненты, токены, Toast, карточки |
| `Content` | Локализации (en/ru), ресурсы |
| `Tracking` | События (сон, кормление, подгузники) |
| `Measurements` | Рост, вес, WHO перцентили |
| `Timeline` | Агрегация данных, SwiftUI интерфейс |
| `Paywall` | StoreKit 2, Premium состояние |
| `Sync` | CloudKit синхронизация |
| `Widgets` | WidgetKit провайдеры |
| `WatchApp` | watchOS companion |

### Premium Features
- WHO перцентильные графики роста
- Head circumference tracking
- Advanced analytics (в планах)
- Data Export (CSV/JSON)

---

## ⚡ Быстрые команды

### Генерация проекта
```bash
./scripts/bootstrap.sh    # Полная настройка с нуля
tuist generate            # Генерация workspace
```

### Тесты
```bash
# Все тесты
xcodebuild -workspace Bloomy.xcworkspace \
  -scheme Bloomy \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test

# Record snapshots
SNAPSHOT_RECORD=1 xcodebuild ... test
```

### Линтинг
```bash
swiftlint
swiftlint --fix  # Автоисправление
```

---

## 🎯 Приоритеты разработки

### High Priority
1. Стабильность CloudKit sync
2. Performance (60fps, <2s startup)
3. Тестовое покрытие >70%
4. Accessibility compliance

### Medium Priority
1. watchOS feature parity с iOS
2. Advanced analytics dashboard
3. Background sync с BGTaskScheduler

### Low Priority
1. A/B paywall эксперименты
2. Дополнительные форматы экспорта
3. Social sharing функционал
4. iPad оптимизация

---

## 🛣️ Roadmap

### Completed
- [x] Tuist workspace и модульная SPM-структура
- [x] Core Data + CloudKit scaffold
- [x] Paywall с StoreKit 2 и snapshot-тестами
- [x] WidgetKit + watchOS внедрение
- [x] Unit/UI/Snapshot тесты и CI workflow
- [x] WHO percentiles и расширенные графики
- [x] Data Export (CSV/JSON)
- [x] Toast notifications и error handling

### In Progress
- [ ] Production CloudKit sync (pull/push/conflicts)
- [ ] Background sync с BGTaskScheduler
- [ ] Advanced analytics dashboard

### Planned
- [ ] A/B paywall сценарии
- [ ] iPad оптимизация
- [ ] Локализация дополнительных языков (es, de, fr)
- [ ] HealthKit интеграция
- [ ] Family sharing функционал

---

## 🔐 Безопасность

### Что НИКОГДА не коммитить:
- ❌ API ключи и токены
- ❌ CloudKit configuration с секретами
- ❌ Apple Push сертификаты (.p12)
- ❌ Provisioning profiles
- ❌ StoreKit secret keys

### Как хранить секреты:
1. Используй `.xcconfig` файлы (добавь в .gitignore)
2. Создай `Secrets.swift.example` с пустыми значениями
3. Реальный `Secrets.swift` держи локально

---

## 📊 Метрики качества

### Performance Targets
- App launch time: <2 секунд
- Frame rate: стабильные 60fps
- Memory usage: <150MB baseline
- Battery impact: минимальный
- Crash rate: <0.1%

### Code Quality
- Test coverage: >70%
- SwiftLint warnings: 0
- Force unwraps: 0
- TODOs в production коде: 0

---

**Последнее обновление:** Октябрь 2024
**Версия документа:** 2.0