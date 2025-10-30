# Contributor Guide

Thanks for helping improve bloomy! This guide documents how we work with the repository—from filing issues to shipping releases and handling urgent fixes.

## 📋 Prerequisites
- macOS 14+ and Xcode 16 (see `README.md` for details).
- Installed tooling: `tuist`, `swiftlint`, `xcpretty`.
- GitHub account with permission to create branches in this repository.
- Configured SSH key or HTTPS with a personal access token.

## 🌿 Branching Strategy
- `main` — stable release-ready builds. Protected branch; merges happen through pull requests only.
- `develop` — integration branch where vetted features land before a release.
- `feature/<scope>-<short-name>` — feature work. Example: `feature/tracking-offline-mode`.
- `bugfix/<issue-id>-<short-name>` — fixes for issues discovered in `develop`.
- `hotfix/<issue-id>-<short-name>` — urgent production fixes (branched from `main`, merged back into both `main` and `develop`).
- `release/<version>` — release preparation, last-mile bug fixes, and metadata (branched from `develop`, merged into `main` and `develop`).

## 🔁 Workflow
1. **Create an issue** (or pick an existing one), agree on scope, add relevant labels.
2. **Branch** off the target (`develop`, or `main` for hotfixes) following the naming conventions above.
3. **Implement:**
   - Follow the existing code style, run `swiftlint`.
   - Maintain test coverage; add snapshot tests when you change UI.
4. **Test:**
   ```bash
   tuist generate --path .
   xcodebuild -workspace Bloomy.xcworkspace \
     -scheme Bloomy \
     -destination 'platform=iOS Simulator,name=iPhone 15' \
     -skipPackagePluginValidation \
     test
   ```
5. **Open a PR:**
   - Fill in the pull request template.
   - Link the issue (e.g., `Closes #123`).
   - Wait for a green CI run.
6. **Code review:**
   - At least one approval from the module owner (see CODEOWNERS once available).
   - Apply changes via additional commits; avoid squashing until the final merge so the history remains clear.

## 🤖 Automation
- **SwiftLint**: enforced via a dedicated CI job (`.github/workflows/ci.yml`). PRs fail if linting is not clean.
- **Actionlint**: validates GitHub Actions YAML syntax.
- **PR Labeler**: applies labels based on file paths (see `.github/labeler.yml`); update as new modules appear.
- **Auto Assign**: assigns reviewers and assignees automatically (see `.github/auto_assign.yml`).
- **Release Drafter**: builds release drafts from merges into `main`.
- **Stale Issues**: reminds about inactive issues/PRs and closes them after a week.
- **Labels Sync**: keeps GitHub labels aligned with `.github/labels.yml`.
- **Dependabot Auto Merge**: merges dependency patch updates after successful checks.

## 📝 Commit Style
- Follow **Conventional Commits**:
  - `feat: add WHO percentile support`
  - `fix(tracking): prevent crash when note is empty`
  - `chore(ci): update xcode image`
- Keep commits atomic; do not mix unrelated changes in one commit.

## 🔐 Branch Protection & CI
- `main` is protected: requires a successful `CI` run and at least one approval.
- `develop` disallows direct pushes; squash/merge and rebase/merge are permitted via PR.
- CI (`.github/workflows/ci.yml`) must pass before merging.

## 🚀 Releases
1. Create `release/<version>` from `develop`.
2. Update the version in `Project.swift` and refresh the changelog (see below).
3. Run regression tests and verify tooling locally.
4. After approvals, merge into `main` (release) and back into `develop` (to retain fixes).
5. Draft a GitHub Release with the changelog and attach the build.

## 🧯 Hotfixes
1. Branch `hotfix/<issue-id>-<short-name>` from `main`.
2. Fix the problem and add a covering test.
3. Merge via PR into `main`, then cherry-pick or merge into `develop`.

## 🗂️ Documentation & Changelog
- Technical notes live in `Docs/`.
- Release notes belong in `Docs/releases/<version>.md`.
- When adding a feature, update `Docs/` and the README if relevant.

## 🤝 Code of Conduct
We follow the [Contributor Covenant](CODE_OF_CONDUCT.md). Contact the project moderators when you observe violations.

## ❓ Questions
Open a GitHub discussion or reach out in the team chat. Thanks for contributing!
