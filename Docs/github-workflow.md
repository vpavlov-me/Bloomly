# GitHub Workflow Guide

Этот документ описывает, как мы работаем с GitHub для BabyTrack: ветки, pull requests, issue, релизы и настройки репозитория.

## 1. Ветки
- `main` — стабильная ветка. Защищаем в настройках репозитория (Settings → Branches):
  - Require a pull request before merging
  - Require status checks to pass before merging (`CI`)
  - Require linear history
- `develop` — интеграционная ветка для готовых фич. Также защищаем от прямых пушей.
- `feature/*`, `bugfix/*` — ответвляемся от `develop`.
- `hotfix/*` — ответвляемся от `main`, после мёрджа делаем `git checkout develop && git merge main`.
- `release/<version>` — подготовка релиза. После мёрджа в `main` тегируем `v<version>`.

Создайте базовые ветки локально:
```bash
git checkout main
git pull
git checkout -b develop
git push -u origin develop
```

## 2. Issue Flow
1. Используйте шаблоны (`Bug Report`, `Feature Request`).
2. Назначайте метки:
   - `bug`, `enhancement`, `documentation`, `ci`, `question`.
   - Приоритет: `P0`, `P1`, `P2`.
   - Компонент: `module:sync`, `module:tracking`, `module:design-system`, и т.д.
3. Добавляйте исполнителя и срок (milestone) при необходимости.

## 3. Pull Requests
- Цель — < 400 строк diff. Делим на независимые PR.
- Заполняем шаблон, добавляем скриншоты UI.
- Минимум один апрув.
- CI должен быть зелёный.
- После мёрджа не забываем удалить ветку (`Delete branch` в UI).
- Для крупных изменений добавляем changelog в `Docs/releases/<version>.md`.

## 4. CI/CD
- Workflow: `.github/workflows/ci.yml`.
- Запускается на `push` в `main` и на каждый `pull_request`.
- Проверяет сборку iOS, виджетов и watchOS; гоняет тесты.
- Snapshot-фейлы выгружаются артефактами.
- Рекомендуется включить Required status check `CI` в branch protection.

## 5. Dependabot
Файл `.github/dependabot.yml` обновляет:
- Swift Package Manager (`package-ecosystem: swift`)
- GitHub Actions (`package-ecosystem: github-actions`)

Запуск раз в неделю, создаёт PR с changelog и ссылками. Настройте автоматическое назначение ревьюеров через CODEOWNERS.

## 6. Code Owners и ревью
- Создайте файл `.github/CODEOWNERS` (пример ниже) и обновите списки владельцев.

```
# Модульный пример
*           @pavlov @babytrack-core
App/        @ios-team
Packages/   @module-leads
Docs/       @techwriters
```

## 7. Releases
1. Создаём ветку `release/<version>` от `develop`.
2. Обновляем версии, changelog, метаданные, скриншоты (при необходимости).
3. Мёрджим через PR в `main` (release) и обратно в `develop`.
4. Создаём GitHub Release с бинарными артефактами или TestFlight ссылкой.
5. Тег `v<version>` ставим на коммит в `main`.

## 8. Issue Boards
- Используйте Projects (Beta) для roadmap.
- Колонки: Backlog → Ready → In Progress → In Review → Done.
- Автоматизируйте перемещение карт при смене статуса issue/PR.

## 9. Безопасность
- Поддерживаем `CODE_OF_CONDUCT.md` и `SECURITY.md` (см. TODO).
- Для приватных обращений используйте почту babytrack@vibecoding.com.
- Регулярно проверяйте Security Advisories и Dependabot alerts.

## 10. Checklist при настройке репозитория
- [ ] Создана ветка `develop`
- [ ] Защищены ветки `main`, `develop`
- [ ] Включены требуемые status checks
- [ ] Добавлены Issue/PR templates
- [ ] Включён Dependabot
- [ ] Настроен CODEOWNERS
- [ ] Подключены Projects и Labels
- [ ] Описан workflow в `CONTRIBUTING.md`

Этот файл обновляем по мере эволюции процессов команды.
