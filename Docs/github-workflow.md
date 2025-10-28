# GitHub Workflow Guide

This document describes how we use GitHub for BabyTrack: branching, pull requests, issues, releases, and repository configuration.

## 1. Branches
- `main` — stable branch. Protect it in repository settings (Settings → Branches):
  - Require a pull request before merging
  - Require status checks to pass before merging (`CI`)
  - Require linear history
- `develop` — integration branch for finished features. Also protect it from direct pushes.
- `feature/*`, `bugfix/*` — branch from `develop`.
- `hotfix/*` — branch from `main`, then after merge run `git checkout develop && git merge main`.
- `release/<version>` — release prep. After merging into `main`, tag `v<version>`.

Create the base branches locally:
```bash
git checkout main
git pull
git checkout -b develop
git push -u origin develop
```

## 2. Issue Flow
1. Use the templates (`Bug Report`, `Feature Request`).
2. Apply labels:
   - `bug`, `enhancement`, `documentation`, `ci`, `question`
   - Priority: `P0`, `P1`, `P2`
   - Component: `module:sync`, `module:tracking`, `module:design-system`, etc.
3. Add an assignee and milestone when needed.

## 3. Pull Requests
- Target < 400 lines of diff. Split into independent PRs when larger.
- Fill out the template and attach UI screenshots.
- Require at least one approval.
- CI must be green before merging.
- Delete the branch after merging (`Delete branch` in the UI).
- For substantial changes update the changelog in `Docs/releases/<version>.md`.

## 4. CI/CD
- Workflow: `.github/workflows/ci.yml`.
- Runs on `push` to `main` and every `pull_request`.
- Builds the iOS app, widgets, and watchOS targets; runs tests.
- Snapshot failures are uploaded as artifacts.
- Enable the required status check `CI` in branch protection.

## 5. Dependabot
The `.github/dependabot.yml` file updates:
- Swift Package Manager (`package-ecosystem: swift`)
- GitHub Actions (`package-ecosystem: github-actions`)

It runs weekly, creates PRs with changelog references, and can auto-assign reviewers via CODEOWNERS.

## 6. Code Owners & Reviews
- Maintain `.github/CODEOWNERS` (example below) and keep owner lists current.

```
# Modular example
*           @vpavlov-me @babytrack-core
App/        @ios-team
Packages/   @module-leads
Docs/       @techwriters
```

## 7. Releases
1. Create `release/<version>` from `develop`.
2. Update versions, changelog, metadata, screenshots if needed.
3. Merge via PR into `main` (release) and back into `develop`.
4. Create a GitHub Release with binary artifacts or a TestFlight link.
5. Tag `v<version>` on the commit in `main`.

## 8. Issue Boards
- Use Projects (Beta) for the roadmap.
- Columns: Backlog → Ready → In Progress → In Review → Done.
- Automate card movement based on issue/PR status changes.

## 9. Security
- Maintain `CODE_OF_CONDUCT.md` and `SECURITY.md`.
- For private reports use babytrack@vibecoding.com.
- Monitor Security Advisories and Dependabot alerts.

## 10. GitHub Automation
- **CI** (`.github/workflows/ci.yml`) — build, tests, SwiftLint.
- **Actionlint** (`.github/workflows/actionlint.yml`) — validates GitHub Actions.
- **PR Labeler** (`.github/workflows/pr-labeler.yml`) — applies labels based on `.github/labeler.yml`.
- **Auto Assign** (`.github/workflows/auto-assign.yml`) — assigns reviewers per `.github/auto_assign.yml`.
- **Release Drafter** (`.github/workflows/release-drafter.yml`) — compiles notes from merges into `main`.
- **Stale Issues** (`.github/workflows/stale.yml`) — pings and closes inactive issues/PRs.
- **Dependabot** (`.github/dependabot.yml`) — updates SwiftPM and GitHub Actions dependencies.
- **Labels Sync** (`.github/workflows/labels-sync.yml`) — syncs labels from `.github/labels.yml`.
- **Dependabot Auto Merge** (`.github/workflows/dependabot-auto-merge.yml`) — merges Dependabot patch updates after green checks.

## 11. Repository Setup Checklist
- [ ] Create the `develop` branch
- [ ] Protect the `main` and `develop` branches
- [ ] Enable required status checks
- [ ] Add Issue/PR templates
- [ ] Enable Dependabot
- [ ] Configure CODEOWNERS
- [ ] Set up Projects and Labels
- [ ] Document the workflow in `CONTRIBUTING.md`

Update this document as the team’s processes evolve.
