# 📱 Инструкция для Релиза BabyTrack в TestFlight и App Store

**Дата создания**: 29 октября 2025
**Версия**: 1.0
**Цель**: Подготовка приложения BabyTrack для бета-тестирования в TestFlight и последующего релиза в App Store

---

## ✅ ЧТО УЖЕ СДЕЛАНО АВТОМАТИЧЕСКИ

Я уже подготовил для вас:

1. ✅ **Исправлены SwiftLint нарушения** в коде
2. ✅ **Создан [PRIVACY.md](PRIVACY.md)** - полная политика конфиденциальности
3. ✅ **Создан [TERMS.md](TERMS.md)** - условия использования
4. ✅ **Создан [Configuration.storekit](Configuration.storekit)** - конфигурация для тестирования IAP локально
5. ✅ **Создан скрипт [scripts/update-bundle-ids.sh](scripts/update-bundle-ids.sh)** - автоматическое обновление Bundle IDs
6. ✅ **Создана структура для App Icons** в `App/Resources/Assets.xcassets/`
7. ✅ **Созданы шаблоны App Store метаданных** (английский и русский) в `AppStoreAssets/metadata/`
8. ✅ **Обновлены entitlements на Production** для CloudKit

---

## 🎯 ЧТО НУЖНО СДЕЛАТЬ ВРУЧНУЮ

Ниже пошаговая инструкция того, что требует вашего личного участия.

---

## ЭТАП 1: ПОДГОТОВКА APPLE DEVELOPER ACCOUNT (2-3 часа)

### Шаг 1.1: Регистрация Bundle IDs

**Где**: [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list) → Identifiers

**Действия**:
1. Нажмите "+" для создания нового Identifier
2. Выберите "App IDs"
3. Выберите "App"

**Создайте 4 Bundle ID**:

#### 1️⃣ Main App
```
Description: BabyTrack
Bundle ID: com.vibecoding.bloomly (или ваш выбор)
Capabilities:
  ☑ App Groups
  ☑ iCloud (CloudKit)
  ☑ In-App Purchase
  ☑ Push Notifications
```

#### 2️⃣ Widgets Extension
```
Description: BabyTrack Widgets
Bundle ID: com.vibecoding.bloomly.widgets
Capabilities:
  ☑ App Groups
```

#### 3️⃣ Watch App
```
Description: BabyTrack Watch
Bundle ID: com.vibecoding.bloomly.watchapp
Capabilities:
  ☑ App Groups
```

#### 4️⃣ Watch Extension
```
Description: BabyTrack Watch Extension
Bundle ID: com.vibecoding.bloomly.watchkitextension
Capabilities:
  ☑ App Groups
```

---

### Шаг 1.2: Создание App Group

**Где**: [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/applicationGroup) → Identifiers → App Groups

**Действия**:
1. Нажмите "+"
2. Выберите "App Groups"
3. Description: `BabyTrack Data Sharing`
4. Identifier: `group.com.vibecoding.bloomly`
5. Нажмите "Continue" и "Register"

**Затем добавьте App Group ко всем 4 Bundle IDs**:
- Откройте каждый Bundle ID
- Edit → App Groups → Enable
- Выберите `group.com.vibecoding.bloomly`
- Save

---

### Шаг 1.3: Создание iCloud Container

**Где**: [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/cloudContainer) → Identifiers → iCloud Containers

**Действия**:
1. Нажмите "+"
2. Выберите "iCloud Containers"
3. Description: `BabyTrack CloudKit Container`
4. Identifier: `iCloud.com.vibecoding.bloomly`
5. Нажмите "Continue" и "Register"

**Затем добавьте iCloud Container к Main App, Watch App и Watch Extension**:
- Откройте каждый Bundle ID (кроме Widgets)
- Edit → iCloud → Enable
- Выберите `iCloud.com.vibecoding.bloomly`
- Save

---

### Шаг 1.4: Настройка CloudKit Schema

**Где**: [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)

**Действия**:
1. Войдите с вашим Apple ID
2. Выберите ваш контейнер: `iCloud.com.vibecoding.bloomly`
3. Перейдите в **Development** → **Schema** → **Record Types**

**Создайте 3 Record Type**:

#### Record Type: `Baby`
```
Fields:
- id (String, Queryable, Indexed)
- name (String)
- birthDate (Date/Time, Queryable, Indexed)
- photoData (Bytes) [optional]
- createdAt (Date/Time)
- updatedAt (Date/Time)

Indexes:
- recordName (Queryable, Sortable)
- createdAt (Queryable, Sortable)
```

#### Record Type: `Event`
```
Fields:
- id (String, Queryable, Indexed)
- kind (String, Queryable, Indexed)
- start (Date/Time, Queryable, Indexed)
- end (Date/Time) [optional]
- notes (String) [optional]
- babyID (String, Queryable, Indexed)
- isSynced (Int64)
- isDeleted (Int64, Queryable, Indexed)
- createdAt (Date/Time, Queryable, Indexed)
- updatedAt (Date/Time)

Indexes:
- kind + start (Queryable, Sortable)
- babyID + start (Queryable, Sortable)
- isDeleted (Queryable)
```

#### Record Type: `Measurement`
```
Fields:
- id (String, Queryable, Indexed)
- type (String, Queryable, Indexed)
- value (Double)
- unit (String)
- date (Date/Time, Queryable, Indexed)
- babyID (String, Queryable, Indexed)
- isSynced (Int64)
- createdAt (Date/Time)
- updatedAt (Date/Time)

Indexes:
- type + date (Queryable, Sortable)
- babyID + date (Queryable, Sortable)
```

4. После создания всех Record Types:
   - Нажмите **"Deploy to Production"** вверху
   - ⚠️ **ВАЖНО**: Схему Production нельзя изменить после deploy!
   - Подтвердите деплой

---

### Шаг 1.5: Создание App Store Connect App

**Где**: [App Store Connect](https://appstoreconnect.apple.com) → My Apps

**Действия**:
1. Нажмите "+" → "New App"
2. Заполните форму:
   ```
   Platforms: ☑ iOS  ☑ watchOS
   Name: BabyTrack
   Primary Language: English (U.S.)
   Bundle ID: com.vibecoding.bloomly
   SKU: BABYTRACK001 (любой уникальный)
   User Access: Full Access
   ```
3. Нажмите "Create"

---

### Шаг 1.6: Создание In-App Purchase Products

**Где**: App Store Connect → Your App → Features → In-App Purchases

**Действия**:
1. Нажмите "+" → "Auto-Renewable Subscription"
2. **Создайте Subscription Group** (если нет):
   ```
   Reference Name: Premium Features
   ```

3. **Создайте Monthly подписку**:
   ```
   Reference Name: Premium Monthly
   Product ID: com.vibecoding.bloomly.premium.monthly
   Subscription Group: Premium Features
   Subscription Duration: 1 Month

   Pricing:
   - Choose manually (or use Pricing Template)
   - $4.99 USD (или ваша цена)

   Localization (English):
   - Display Name: Premium Monthly
   - Description: Unlock WHO growth percentiles, head circumference tracking, and advanced analytics

   Localization (Russian):
   - Display Name: Премиум Месячная
   - Description: Доступ к WHO перцентилям роста, отслеживанию окружности головы и расширенной аналитике
   ```

4. **Создайте Yearly подписку**:
   ```
   Reference Name: Premium Yearly
   Product ID: com.vibecoding.bloomly.premium.yearly
   Subscription Group: Premium Features
   Subscription Duration: 1 Year

   Pricing:
   - $39.99 USD (save ~33%)

   Localization (English):
   - Display Name: Premium Yearly
   - Description: Full year of premium features with best value - save over 30%

   Localization (Russian):
   - Display Name: Премиум Годовая
   - Description: Полный год премиум функций с максимальной выгодой - экономия более 30%
   ```

5. Для обоих продуктов загрузите **App Store Promotional Image** (1024x1024)
6. Нажмите "Save" для каждого продукта

---

## ЭТАП 2: ОБНОВЛЕНИЕ КОДА ПРОЕКТА (30 минут)

### Шаг 2.1: Обновление Bundle IDs в проекте

**Используйте автоматический скрипт**:

```bash
cd /Users/pavlov/Documents/Vibecoding/Bloomy
./scripts/update-bundle-ids.sh com.vibecoding.bloomly YOUR_TEAM_ID
```

Где:
- `com.vibecoding.bloomly` - ваш выбранный Bundle ID prefix
- `YOUR_TEAM_ID` - ваш Apple Developer Team ID (найти в [Membership](https://developer.apple.com/account#!/membership))

Скрипт автоматически обновит:
- Project.swift
- Все entitlements файлы
- ProductIDs.swift
- Configuration.storekit

---

### Шаг 2.2: Регенерация Xcode проекта

```bash
tuist clean
tuist generate
```

---

### Шаг 2.3: Проверка в Xcode

1. Откройте проект:
```bash
open BabyTrack.xcworkspace
```

2. Выберите target "BabyTrack" → Signing & Capabilities:
   - Team: выберите ваш Apple Developer Team
   - Provisioning Profile: Automatic
   - Проверьте, что Bundle ID правильный

3. Повторите для всех targets:
   - BabyTrack
   - BabyTrackWidgets
   - BabyTrackWatch
   - BabyTrackWatchExtension

4. Убедитесь, что capabilities активны:
   - ✅ iCloud (CloudKit)
   - ✅ App Groups
   - ✅ In-App Purchase
   - ✅ Push Notifications (опционально)

---

## ЭТАП 3: ПОДГОТОВКА РЕСУРСОВ (3-4 часа)

### Шаг 3.1: Создание App Icons

**Требуемые размеры** (все в PNG без alpha-канала):

Используйте онлайн генератор: https://www.appicon.co/ или создайте вручную.

1. **Дизайн иконки** 1024x1024:
   - Тема: Baby care, рост, отслеживание
   - Цвета: Мягкие пастельные тона
   - Стиль: Современный, минимальный, дружелюбный
   - Без текста

2. **Сгенерируйте все размеры** и поместите в:
```
App/Resources/Assets.xcassets/AppIcon.appiconset/
├── Icon-20@2x.png (40x40)
├── Icon-20@3x.png (60x60)
├── Icon-29@2x.png (58x58)
├── Icon-29@3x.png (87x87)
├── Icon-40@2x.png (80x80)
├── Icon-40@3x.png (120x120)
├── Icon-60@2x.png (120x120)
├── Icon-60@3x.png (180x180)
└── Icon-1024.png (1024x1024)
```

3. **Watch App Icons**: Аналогично для `Targets/BabyTrackWatch/Assets.xcassets/`

---

### Шаг 3.2: Создание App Store Screenshots

**Требуемые размеры**:
- 6.7" Display (iPhone 15 Pro Max): 1290 x 2796 px
- 6.5" Display (iPhone 11 Pro Max): 1242 x 2688 px
- 5.5" Display (iPhone 8 Plus): 1242 x 2208 px

**Минимум 3, максимум 10 скриншотов**

**Рекомендуемые сцены**:
1. Dashboard с данными (hero shot)
2. Event tracking в действии
3. Timeline с историей
4. Growth charts с WHO перцентилями
5. Watch app screen
6. Widgets preview

**Инструменты**:
- iOS Simulator (в Xcode)
- Cmd+S для скриншота симулятора
- [Fastlane Frameit](https://fastlane.tools/frameit) для добавления рамок устройства
- [App Store Screenshot Generator](https://www.appstorescreenshot.com/)

**Сохраните скриншоты в**:
```
AppStoreAssets/screenshots/
├── 6.7inch/
├── 6.5inch/
└── 5.5inch/
```

---

### Шаг 3.3: Публикация Privacy Policy и Terms

**Требование**: Privacy Policy должен быть доступен по публичному URL

**Варианты**:

#### Вариант A: GitHub Pages (бесплатно)
```bash
# В вашем репозитории
mkdir -p docs
cp PRIVACY.md docs/privacy.md
cp TERMS.md docs/terms.md
git add docs/
git commit -m "Add privacy policy and terms"
git push

# Settings → Pages → Enable GitHub Pages
# URL будет: https://vpavlov-me.github.io/Bloomy/privacy.html
```

#### Вариант B: Ваш сайт
Загрузите PRIVACY.md и TERMS.md на `vibecoding.com/bloomly/`

**URLs для использования**:
- Privacy Policy: `https://vibecoding.com/bloomly/privacy`
- Terms of Service: `https://vibecoding.com/bloomly/terms`
- Support: `https://vibecoding.com/bloomly/support`

---

## ЭТАП 4: ФИНАЛЬНАЯ СБОРКА И ЗАГРУЗКА (1-2 часа)

### Шаг 4.1: Pre-Build Checklist

Убедитесь:
- [ ] Bundle IDs обновлены и зарегистрированы
- [ ] Team ID установлен в Xcode
- [ ] App Icons добавлены
- [ ] CloudKit Production schema deployed
- [ ] In-App Purchase продукты созданы
- [ ] Privacy Policy опубликована
- [ ] Provisioning profiles созданы (автоматически)

---

### Шаг 4.2: Установка Version и Build Number

В Xcode:
1. Выберите target "BabyTrack"
2. General → Identity:
   - Version: `1.0.0`
   - Build: `1`

---

### Шаг 4.3: Archive Build

1. В Xcode выберите:
   - Scheme: `BabyTrack`
   - Destination: `Any iOS Device (arm64)`

2. Product → Clean Build Folder (Cmd+Shift+K)

3. Product → Archive (Cmd+B)

4. Дождитесь завершения (5-10 минут)

---

### Шаг 4.4: Validate и Upload

1. После успешного Archive откроется Organizer

2. Нажмите **"Validate App"**:
   - App Store Connect
   - Automatically manage signing
   - Upload symbols: Yes
   - Нажмите "Validate"
   - Дождитесь результата

3. Если validation успешна, нажмите **"Distribute App"**:
   - App Store Connect
   - Upload
   - Automatically manage signing
   - Upload symbols: Yes
   - Нажмите "Upload"

4. Дождитесь завершения загрузки (5-15 минут)

---

### Шаг 4.5: Проверка обработки build

1. Перейдите в [App Store Connect](https://appstoreconnect.apple.com)
2. Your App → Activity → iOS Builds
3. Статус должен измениться с "Processing" на "Ready to Submit" (10-30 минут)

---

## ЭТАП 5: НАСТРОЙКА TESTFLIGHT (30 минут)

### Шаг 5.1: Internal Testing

**Где**: App Store Connect → TestFlight → Internal Testing

1. Нажмите "+" в разделе Internal Testing
2. Group Name: `Internal Testers`
3. Добавьте себя и команду (до 100 человек из App Store Connect team)
4. Выберите build 1.0.0 (1)
5. Нажмите "Save"

Internal build доступен **сразу** без Apple Review.

---

### Шаг 5.2: External Testing

**Где**: App Store Connect → TestFlight → External Testing

1. Нажмите "+" в External Testing
2. Group Name: `Beta Testers`
3. **Заполните Test Information**:

```
What to Test (EN):
Please test the following features:
- Complete onboarding and create baby profile
- Track sleep, feeding, diaper, and pumping events
- View timeline and charts
- Test Premium subscription purchase (Sandbox)
- Try Apple Watch quick actions
- Export data functionality
- Switch between English and Russian

Known Issues:
- Background sync not yet implemented
- Some edge cases in timeline aggregation

Feedback Email: testflight@vibecoding.com
```

4. **Beta App Description**:
```
BabyTrack is a comprehensive baby tracking app that helps parents monitor sleep, feeding, diaper changes, and growth measurements. This beta includes core tracking features, iCloud sync, Apple Watch integration, and Premium subscription functionality.
```

5. **App Review Information**:
```
Contact Information:
- First Name: [Ваше имя]
- Last Name: [Ваша фамилия]
- Phone: [Ваш телефон]
- Email: testflight@vibecoding.com

Sign-In Required: No

Demo Account (for Premium testing):
- Username: Not required (Sandbox StoreKit)
- Password: N/A

Notes:
Premium subscription can be tested using Sandbox environment. No real charges will occur. iCloud sync requires two devices with the same Apple ID for full testing.
```

6. Нажмите "Submit for Review"

⏰ **Apple Review Time**: 24-48 часов

---

## ЭТАП 6: ПОДГОТОВКА К APP STORE (после успешного бета-тестирования)

### Шаг 6.1: Заполнение App Information

**Где**: App Store Connect → Your App → App Information

```
Name: BabyTrack
Subtitle: Sleep, Feed, Diaper & Growth
Category:
  Primary: Health & Fitness
  Secondary: Lifestyle
Content Rights: [Ваша компания] owns exclusive rights to this app
Age Rating: 4+ (No mature content)
```

---

### Шаг 6.2: Заполнение Metadata

**Где**: App Store Connect → Your App → [Version] 1.0 → App Store

**Используйте подготовленные файлы**:
- `AppStoreAssets/metadata/app-description-en.txt`
- `AppStoreAssets/metadata/app-description-ru.txt`

Скопируйте соответствующие секции в App Store Connect.

---

### Шаг 6.3: App Privacy Survey

**Где**: App Store Connect → Your App → App Privacy

**ОЧЕНЬ ВАЖНО**: Честно заполните, что данные вы собираете.

**Для BabyTrack**:
```
Data Types Collected:
☑ Health & Fitness
  - Health data (baby measurements)
  Linked to User: Yes
  Used for Tracking: No

☑ User Content
  - Photos (baby profile photo)
  - Other User Content (events, notes)
  Linked to User: Yes
  Used for Tracking: No

☑ Identifiers
  - User ID (iCloud identifier)
  Linked to User: Yes
  Used for Tracking: No

Data Used for Analytics:
☑ Product Interaction
  Linked to User: No (anonymous via TelemetryDeck)
  Used for Tracking: No

Privacy Policy URL: https://vibecoding.com/bloomly/privacy
```

---

### Шаг 6.4: Upload Screenshots

1. В App Store Connect перейдите к версии 1.0
2. App Store → Screenshots → iPhone
3. Загрузите скриншоты для каждого размера:
   - 6.7" (iPhone 15 Pro Max): минимум 3
   - 6.5" (iPhone 11 Pro Max): минимум 3
   - 5.5" (iPhone 8 Plus): минимум 3

---

### Шаг 6.5: Pricing & Availability

```
Price: Free
Availability: All countries (или выберите)
Pre-Order: No
```

---

### Шаг 6.6: Submit for Review

1. Убедитесь, что все поля заполнены (зелёная галочка)
2. Выберите final build
3. Export Compliance:
   - Uses Encryption: No (или заполните документацию)
4. Advertising Identifier: No
5. Нажмите **"Submit for Review"**

⏰ **Apple Review Time**: 1-3 дня

---

## 📋 ФИНАЛЬНЫЙ CHECKLIST

### Pre-TestFlight
- [ ] Bundle IDs зарегистрированы в Developer Portal
- [ ] App Groups созданы
- [ ] CloudKit Container настроен и deployed в Production
- [ ] In-App Purchase продукты созданы
- [ ] App Icons добавлены
- [ ] Bundle IDs обновлены в коде (скрипт запущен)
- [ ] `tuist generate` выполнен
- [ ] Provisioning profiles созданы в Xcode
- [ ] Privacy Policy опубликована
- [ ] Terms опубликованы

### TestFlight Upload
- [ ] Archive создан в Xcode
- [ ] Validation passed
- [ ] Build uploaded в App Store Connect
- [ ] Processing завершён
- [ ] Internal Testing настроено
- [ ] External Testing group создана
- [ ] Beta App Information заполнена
- [ ] Submitted for Beta Review

### App Store Submission (после бета)
- [ ] 2 недели бета-тестирования завершены
- [ ] Критические баги исправлены
- [ ] Screenshots финализированы (все размеры)
- [ ] App Description написан (EN/RU)
- [ ] Keywords оптимизированы
- [ ] App Privacy survey заполнен
- [ ] Support/Privacy URLs работают
- [ ] Final build выбран
- [ ] Submitted for App Review

---

## 🆘 ПОМОЩЬ И РЕСУРСЫ

### Документация
- [App Store Connect Guide](https://developer.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [CloudKit Documentation](https://developer.apple.com/icloud/cloudkit/)
- [StoreKit 2 Guide](https://developer.apple.com/storekit/)

### Поддержка
- **Проект**: [GitHub Issues](https://github.com/vpavlov-me/Bloomy/issues)
- **Apple Developer Support**: https://developer.apple.com/support/

### Полезные Инструменты
- **App Icon Generator**: https://www.appicon.co/
- **Screenshot Generator**: https://www.appstorescreenshot.com/
- **App Store Optimization**: https://www.apptweak.com/

---

## ⏱ ОЖИДАЕМЫЕ СРОКИ

| Этап | Время | Ваше участие |
|------|-------|--------------|
| Apple Developer Setup | 2-3 часа | Активное |
| Обновление кода | 30 минут | Запуск скриптов |
| Подготовка ресурсов | 3-4 часа | Дизайн/скриншоты |
| Build и Upload | 1-2 часа | Xcode операции |
| TestFlight Setup | 30 минут | Заполнение форм |
| **Beta Review** | 24-48 часов | ⏰ Ожидание Apple |
| Beta Testing | 2 недели | Мониторинг feedback |
| App Store Prep | 2-3 часа | Metadata |
| **App Review** | 1-3 дня | ⏰ Ожидание Apple |
| **ИТОГО** | **3-4 недели** | **до публичного релиза** |

---

## 🎉 ПОЗДРАВЛЯЕМ!

После выполнения всех шагов ваше приложение будет:
1. ✅ Доступно в TestFlight для бета-тестеров
2. ✅ Готово к отправке в App Store Review
3. ✅ Соответствовать всем требованиям Apple

**Удачи с релизом BabyTrack! 🍼📱**

---

**Вопросы?** Создайте issue в репозитории или свяжитесь со мной.

