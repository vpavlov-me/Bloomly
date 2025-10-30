# 🚀 Быстрый Старт к Релизу

## Что уже готово ✅

Я автоматически подготовил все необходимые файлы и документацию для релиза вашего приложения в TestFlight и App Store:

### 📄 Созданные Документы
1. **[PRIVACY.md](PRIVACY.md)** - Полная политика конфиденциальности (EN)
2. **[TERMS.md](TERMS.md)** - Условия использования (EN)
3. **[RELEASE_MANUAL.md](RELEASE_MANUAL.md)** - Подробная пошаговая инструкция
4. **[Configuration.storekit](Configuration.storekit)** - StoreKit для локального тестирования IAP

### 🛠 Скрипты и Инструменты
5. **[scripts/update-bundle-ids.sh](scripts/update-bundle-ids.sh)** - Автоматическое обновление Bundle IDs

### 🎨 Структуры и Шаблоны
6. **App/Resources/Assets.xcassets/** - Структура для App Icons
7. **AppStoreAssets/metadata/** - Шаблоны описаний для App Store (EN/RU)
8. **AppStoreAssets/SCREENSHOT_GUIDE.md** - Руководство по созданию скриншотов

### ⚙️ Обновления Кода
9. ✅ CloudKit entitlements переключены на Production
10. ✅ Частично исправлены SwiftLint нарушения

---

## 🎯 Что делать дальше

### Вариант 1: Полная Инструкция
📖 Откройте **[RELEASE_MANUAL.md](RELEASE_MANUAL.md)** и следуйте пошаговой инструкции

### Вариант 2: Краткий План

#### Этап 1: Apple Developer Portal (2-3 часа)
```bash
# Шаг 1: Зарегистрируйте Bundle IDs
https://developer.apple.com/account/resources/identifiers/list

Создайте 4 Bundle ID:
- com.vibecoding.bloomly (main app)
- com.vibecoding.bloomly.widgets
- com.vibecoding.bloomly.watchapp
- com.vibecoding.bloomly.watchkitextension

# Шаг 2: Создайте App Group
group.com.vibecoding.bloomly

# Шаг 3: Создайте iCloud Container
iCloud.com.vibecoding.bloomly

# Шаг 4: Настройте CloudKit Schema
https://icloud.developer.apple.com/dashboard
→ Development → Deploy to Production

# Шаг 5: Создайте App в App Store Connect
https://appstoreconnect.apple.com

# Шаг 6: Создайте In-App Purchases
→ Monthly: $4.99
→ Yearly: $39.99
```

#### Этап 2: Обновите Код (30 минут)
```bash
# Запустите скрипт обновления Bundle IDs
cd /Users/pavlov/Documents/Vibecoding/Bloomy
./scripts/update-bundle-ids.sh com.vibecoding.bloomly YOUR_TEAM_ID

# Регенерируйте проект
tuist clean
tuist generate

# Откройте в Xcode
open Bloomy.xcworkspace
```

#### Этап 3: Создайте Ресурсы (3-4 часа)
```bash
# 1. App Icons (1024x1024 и все размеры)
#    → Поместите в App/Resources/Assets.xcassets/AppIcon.appiconset/

# 2. Скриншоты (3+ для каждого размера)
#    → См. AppStoreAssets/SCREENSHOT_GUIDE.md

# 3. Опубликуйте Privacy Policy
#    → PRIVACY.md на https://vibecoding.com/bloomly/privacy
```

#### Этап 4: Build & Upload (1-2 часа)
```bash
# В Xcode:
1. Scheme: Bloomy
2. Destination: Any iOS Device
3. Product → Archive
4. Validate App
5. Distribute App → App Store Connect
```

#### Этап 5: TestFlight (30 минут)
```bash
# В App Store Connect:
1. TestFlight → Internal Testing → Добавьте себя
2. External Testing → Create Group → Submit for Review
```

---

## 📋 Краткий Checklist

### Перед началом
- [ ] У вас есть платный Apple Developer Account ($99/год)
- [ ] Установлен Xcode 16+
- [ ] Установлен Tuist (`brew install tuist`)

### Apple Developer Portal
- [ ] 4 Bundle IDs зарегистрированы
- [ ] App Group создан
- [ ] iCloud Container создан
- [ ] CloudKit Schema deployed в Production
- [ ] In-App Purchase продукты созданы

### Код и Ресурсы
- [ ] Bundle IDs обновлены (скрипт запущен)
- [ ] `tuist generate` выполнен
- [ ] App Icons добавлены
- [ ] Privacy Policy опубликована
- [ ] Terms опубликованы

### Build
- [ ] Archive создан
- [ ] Validation passed
- [ ] Uploaded в App Store Connect

### TestFlight
- [ ] Internal Testing работает
- [ ] External Testing submitted for review

---

## ⏱ Временные Затраты

| Этап | Время |
|------|-------|
| Apple Developer Setup | 2-3 часа |
| Обновление кода | 30 минут |
| Ресурсы (иконки, скриншоты) | 3-4 часа |
| Build & Upload | 1-2 часа |
| TestFlight Setup | 30 минут |
| **Beta Review (Apple)** | **24-48 часов** |
| Beta Testing | 2 недели |
| App Store Submission | 2-3 часа |
| **App Review (Apple)** | **1-3 дня** |
| **TOTAL** | **~4 недели** |

---

## 📚 Документация

- **Подробная инструкция**: [RELEASE_MANUAL.md](RELEASE_MANUAL.md)
- **Руководство по скриншотам**: [AppStoreAssets/SCREENSHOT_GUIDE.md](AppStoreAssets/SCREENSHOT_GUIDE.md)
- **Privacy Policy**: [PRIVACY.md](PRIVACY.md)
- **Terms of Service**: [TERMS.md](TERMS.md)

---

## 🆘 Помощь

**Вопросы по коду**: [GitHub Issues](https://github.com/vpavlov-me/Bloomy/issues)
**Apple Developer Support**: https://developer.apple.com/support/

---

## 🎉 Успехов с релизом!

Всё готово для того, чтобы начать процесс релиза. Следуйте инструкции в [RELEASE_MANUAL.md](RELEASE_MANUAL.md) и через 3-4 недели ваше приложение будет в App Store!

**Первый шаг**: Откройте https://developer.apple.com/account и начните с регистрации Bundle IDs.
