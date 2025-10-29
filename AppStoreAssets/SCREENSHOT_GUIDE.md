# 📸 Руководство по Созданию App Store Screenshots

## Требуемые Размеры

### iPhone Screenshots
- **6.7" Display** (iPhone 15 Pro Max): 1290 x 2796 px
- **6.5" Display** (iPhone 11 Pro Max): 1242 x 2688 px
- **5.5" Display** (iPhone 8 Plus): 1242 x 2208 px

**Минимум**: 3 скриншота для каждого размера
**Максимум**: 10 скриншотов для каждого размера

---

## Рекомендуемые Сцены (Порядок важен!)

### 1. Hero Shot - Dashboard с Данными
**Что показать**:
- Dashboard с несколькими событиями
- Активный таймер сна
- Быстрые действия (Quick Log buttons)
- Красивые иконки и статистика

**Настройка в симуляторе**:
```
1. Добавьте несколько событий разных типов
2. Запустите таймер сна (Sleep Tracking)
3. Убедитесь, что есть данные за сегодня
4. Сделайте скриншот Dashboard
```

### 2. Event Tracking в Действии
**Что показать**:
- Форма добавления события (Sleep, Feeding, или Diaper)
- Заполненные поля
- Кнопки действий

**Варианты**:
- Sleep tracking form с выбором времени
- Feeding form с выбором типа (breast/bottle)
- Diaper change quick log

### 3. Timeline с Историей
**Что показать**:
- Timeline view с 5-10 событиями
- Разные типы событий (сон, кормление, подгузники)
- Временная шкала
- Pull-to-refresh hint

**Настройка**:
```
1. Создайте 7-10 событий за последние 24 часа
2. Разные типы и времена
3. Откройте Timeline tab
4. Скриншот
```

### 4. Growth Charts с WHO Перцентилями
**Что показать**:
- Beautiful growth chart
- WHO percentile curves
- Data points с датами
- Premium badge (если применимо)

**Настройка**:
```
1. Добавьте 5-7 измерений роста/веса за 3-6 месяцев
2. Откройте Charts → Growth
3. Убедитесь, что WHO кривые видны
4. Скриншот
```

### 5. Apple Watch Companion
**Что показать**:
- Watch face с BabyTrack complications
- Quick log screen на часах
- Recent events на часах

**Как сделать**:
```
1. Запустите Watch Simulator
2. Откройте BabyTrack Watch app
3. Quick Log view
4. Скриншот (Cmd+S)
```

### 6. Home Screen Widgets
**Что показать**:
- iPhone Home Screen с виджетами BabyTrack
- Last Feeding widget
- Sleep Today widget
- Красивый wallpaper

**Настройка**:
```
1. Добавьте виджеты на Home Screen симулятора
2. Убедитесь, что они показывают реальные данные
3. Выберите красивый wallpaper
4. Скриншот Home Screen
```

### 7. Settings / Premium Paywall
**Что показать**:
- Paywall screen с премиум функциями
- Pricing (monthly/yearly)
- Feature list
- Красивый дизайн

---

## Быстрый Способ: Использование iOS Simulator

### Шаг 1: Запуск нужных симуляторов
```bash
# iPhone 15 Pro Max (6.7")
open -a Simulator --args -CurrentDeviceUDID [UDID]

# Найти UDID:
xcrun simctl list devices | grep "iPhone 15 Pro Max"
```

### Шаг 2: Подготовка данных
1. Запустите приложение
2. Пройдите onboarding
3. Создайте baby profile
4. Добавьте 10-15 событий разных типов
5. Добавьте 5-7 измерений

### Шаг 3: Создание скриншотов
```
1. Откройте нужный экран
2. Cmd+S для скриншота
3. Скриншоты сохраняются на Desktop
4. Переименуйте файлы понятными именами
```

### Шаг 4: Организация файлов
```
AppStoreAssets/screenshots/
├── 6.7inch/
│   ├── 01-dashboard.png
│   ├── 02-tracking.png
│   ├── 03-timeline.png
│   ├── 04-charts.png
│   └── 05-watch.png
├── 6.5inch/
│   └── [те же файлы]
└── 5.5inch/
    └── [те же файлы]
```

---

## Продвинутый Способ: Автоматизация с Fastlane

### Установка Fastlane Snapshot
```bash
brew install fastlane
fastlane snapshot init
```

### Настройка UI Tests для Snapshot
```swift
// В BabyTrackUITests.swift

func testGenerateScreenshots() {
    let app = XCUIApplication()
    setupSnapshot(app)
    app.launch()

    // 1. Dashboard
    snapshot("01-dashboard")

    // 2. Open event tracking
    app.buttons["Quick Log Sleep"].tap()
    snapshot("02-tracking-form")

    // 3. Timeline
    app.tabBars.buttons["Timeline"].tap()
    snapshot("03-timeline")

    // 4. Charts
    app.tabBars.buttons["Charts"].tap()
    snapshot("04-charts")
}
```

### Запуск генерации
```bash
fastlane snapshot
```

---

## Добавление Рамок Устройства (Device Frames)

### Использование Fastlane Frameit
```bash
brew install imagemagick
fastlane frameit
```

Frameit автоматически добавит рамки iPhone вокруг скриншотов.

### Ручной способ
- Используйте Figma/Sketch templates
- Скачайте: https://www.figma.com/community/file/app-store-screenshot-templates

---

## Оптимизация Screenshots для Конверсии

### Best Practices
1. **Первый скриншот = самый важный** (50% пользователей видят только его)
2. **Показывайте value proposition** в первых 3 скриншотах
3. **Используйте текстовые оверлеи** для объяснения функций
4. **Яркие, контрастные цвета**
5. **Реальные данные** (не placeholder текст)
6. **Последовательность** - расскажите историю

### Пример последовательности
```
1. "Track Every Precious Moment" - Dashboard
2. "Log Events in Seconds" - Quick tracking
3. "See Patterns Over Time" - Timeline
4. "Monitor Growth with WHO Charts" - Charts
5. "Quick Actions on Apple Watch" - Watch app
```

### Текстовые Оверлеи (опционально)
- Короткие заголовки (3-5 слов)
- Крупный, читаемый шрифт
- Контрастный цвет
- Не перекрывайте важные UI элементы

---

## Инструменты и Ресурсы

### Онлайн Генераторы
- **App Store Screenshot Generator**: https://www.appstorescreenshot.com/
- **Previewed**: https://previewed.app/
- **AppLaunchpad**: https://theapplaunchpad.com/

### Дизайн Инструменты
- **Figma** (бесплатный): https://figma.com
- **Sketch** (macOS): https://www.sketch.com/
- **Canva**: https://www.canva.com/

### Fastlane
- **Snapshot**: https://docs.fastlane.tools/actions/snapshot/
- **Frameit**: https://docs.fastlane.tools/actions/frameit/

---

## Чеклист Перед Загрузкой

- [ ] Все 3 размера созданы (6.7", 6.5", 5.5")
- [ ] Минимум 3 скриншота для каждого размера
- [ ] Screenshots в правильном порядке (hero shot первый)
- [ ] Все скриншоты в правильном разрешении
- [ ] PNG формат
- [ ] Нет placeholder данных ("Lorem Ipsum", "Test User")
- [ ] UI выглядит профессионально
- [ ] Нет багов или ошибок на скриншотах
- [ ] Status bar выглядит хорошо (9:41, полный сигнал, заряд)
- [ ] Правильная ориентация (Portrait)

---

## Загрузка в App Store Connect

1. App Store Connect → Your App → Version 1.0
2. App Store → Screenshots → iPhone
3. Выберите размер (6.7", 6.5", 5.5")
4. Перетащите скриншоты в нужном порядке
5. Нажмите "Save"

**Совет**: Загрузите все размеры сразу для консистентности.

---

Удачи с созданием screenshots! 📱✨
