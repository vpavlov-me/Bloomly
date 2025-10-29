# BabyTrack

BabyTrack is a modular SwiftUI application for tracking sleep, feedings, diaper changes, and growth measurements. The architecture is designed for an offline-first experience with local Core Data storage, a CloudKit sync layer, a shared design system, and reusable feature modules that power iOS, watchOS, and WidgetKit surfaces.

## Key Features
- **Event Journal** for sleep, feedings, diaper changes, and pumping with local persistence, notes, and CloudKit-backed sync across devices.
- **Timeline Feed** that aggregates events and measurements, provides quick actions, and visualizes trends with Swift Charts.
- **WHO Percentiles** charts that expose official WHO curves (Premium feature).
- **Data Export** that lets users back up data as CSV or JSON.
- **Toast Notifications** so every CRUD flow provides instant feedback.
- **WidgetKit Widgets** (“Last Feeding” and “Sleep Today”) backed by an App Group shared store.
- **watchOS 10 Companion** for quick logging and access to recent events.
- **StoreKit 2 Paywall** with purchase/restore flows, design system styling, and app-level dependency injection.

## Tech Stack
- Swift 5.10, SwiftUI, modern concurrency (async/await)
- Core Data + NSPersistentCloudKitContainer, App Groups
- CloudKit (Private DB) with custom zones, change-token tracking, and background push/pull orchestration
- WidgetKit, watchOS 10, Swift Charts
- StoreKit 2, Storefront paywall
- XCTest and SnapshotTesting
- Tuist workspace, Swift Package Manager feature modules

## Modules
| Package | Responsibility |
| --- | --- |
| `DesignSystem` | Colors, typography, cards, toast, and reusable UI components |
| `Content` | Localizations (en/ru), SF Symbols, and text resources |
| `Tracking` | Event model, Core Data repository, logging form |
| `Measurements` | Measurements, growth charts, WHO percentiles, sample builders |
| `Timeline` | Event and measurement aggregation, SwiftUI interface |
| `Paywall` | StoreKit 2 client, Premium state, UI, and snapshots |
| `Sync` | CloudKit sync engine: Core Data mapping, change-token storage, push/pull/conflict handling |
| `Widgets` | WidgetKit providers, App Group store, “Feed/Sleep” widgets |
| `WatchApp` | watchOS fast logging, events, and measurements |

## Getting Started

> Quick path: `./scripts/bootstrap.sh` installs Tuist (if needed), generates the workspace, and resolves dependencies.

1. Install Xcode 16 with the iOS 17 / watchOS 10 SDKs.
2. Install tooling: `brew install tuist swiftlint`.
3. Run `tuist install` to fetch the compatible Tuist version (see `Tuist/Config.swift`).
4. Run `tuist generate` to create `BabyTrack.xcworkspace`.
5. Open the workspace and assign your Apple Developer team (placeholder Team ID is `ABCDE12345`).
6. Update the bundle prefix `com.example` if necessary.
7. Enable the iCloud container `iCloud.com.example.BabyTrack` and App Group `group.com.example.babytrack` for every target.
8. Create StoreKit products `com.example.babytrack.premium.monthly` and `com.example.babytrack.premium.yearly`.

## Tests & QA

```bash
# Build the app
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallelizeTargets \
  -skipPackagePluginValidation build

# Run unit, UI, and snapshot tests
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallelizeTargets \
  -skipPackagePluginValidation test
```

### Snapshot Testing
BabyTrack uses [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to prevent UI regressions.

**Test coverage:**
- Dashboard (empty state, populated state, active timers)
- Timeline (empty and populated states)
- Tracking flows (Sleep, Feed, Diaper, Pumping)
- Paywall and design system components

**Variants:**
- Light and Dark appearance
- iPhone SE, iPhone 13 Pro, iPhone 15 Pro Max
- State permutations (Empty, Loading, Error)

**Commands:**
- **Record references**: `SNAPSHOT_RECORD=1 xcodebuild ... test` creates or refreshes reference images in `Tests/__Snapshots__`.
- **Verify**: Run tests without the environment variable to compare UI against stored references.
- **CI**: GitHub Actions runs in verification mode and uploads artifacts on failure.

Detailed notes: [Docs/snapshot-testing.md](Docs/snapshot-testing.md)

### In-Memory Storage
- Repositories can use `PersistenceController(inMemory: true)` for unit tests and previews.
- Tests stay isolated without polluting the production database.
- Use `.preview` for SwiftUI previews.

## Premium & Paywall
- Premium state lives in `@AppStorage("isPremium")` and is exposed through `Paywall.PremiumState`.
- **Premium features:**
  - WHO percentile curves in growth charts
  - Head circumference tracking
  - Advanced analytics (planned)
- The paywall is available via Settings → Manage Subscription.
- The StoreKit 2 client (`StoreClient`) handles product load, purchase, restore, and entitlement validation.

## Data Export
BabyTrack allows exporting all data for backups or migration:
- **CSV export**: Events and measurements in a tabular layout.
- **JSON export**: Structured JSON with export metadata.
- Access: Settings → Export Data → select the preferred format.
- Share exported files through the system Share Sheet.

## CloudKit Sync
CloudKit sync keeps local Core Data in lockstep with iCloud:
- `CloudKitSyncService` maps Core Data entities to `CKRecord`s, persists change tokens, and supports last-write-wins conflict resolution.
- Soft-deleted events propagate as record deletions; measurements stay current across devices.
- Background refresh is registered through `BGTaskScheduler` to keep data fresh outside the foreground session.

Follow the setup checklist below before shipping.

### CloudKit Setup (Preparation)
1. Enable the CloudKit capability in Xcode.
2. Create the CloudKit container `iCloud.com.example.BabyTrack`.
3. Prepare the Private Database schema (Record Types: `Event`, `Measurement`) and deploy it before releasing.

## Error Handling & UX
- **Toast Notifications** surface success/error feedback in every CRUD flow.
- **Graceful Fallbacks** ensure optionals are safely unwrapped (no force unwraps in production code).
- **Loading States** rely on `ProgressView` for async operations.
- **Empty States** provide custom `EmptyStateView` descriptions and recovery actions.

## Documentation
- `Docs/architecture.md` — data flow diagram and module layering.
- `Docs/cloudkit.md` — iCloud setup and schema deployment.
- `Docs/file-tree.md` — current repository layout.
- `Docs/github-workflow.md` — branching strategy, PR, and release rules.

## Automation
- GitHub Actions: `CI` (build + tests), `SwiftLint`, `Actionlint`, `Stale Issues`.
- Release Drafter assembles release notes by labels.
- PR Labeler and Auto Assign apply labels and assign reviewers based on path rules.
- Dependabot updates SwiftPM and GitHub Actions dependencies and auto-merges patch releases.
- Labels Sync keeps the GitHub label set aligned with `.github/labels.yml`.

## Contributing
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for workflow, branching, and testing expectations.
- We follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- Use the GitHub issue templates for bugs and feature requests.

## Roadmap
- [x] Tuist workspace and modular SPM structure
- [x] Core Data + CloudKit scaffold
- [x] StoreKit 2 paywall with snapshot tests
- [x] WidgetKit + watchOS companion
- [x] Unit/UI/Snapshot tests and CI workflow
- [x] Production CloudKit sync (pull/push/conflicts)
- [x] WHO percentiles and extended charts
- [x] Data Export (CSV/JSON)
- [x] Toast notifications and error handling
- [ ] Background sync with BGTaskScheduler
- [ ] Advanced analytics dashboard
- [ ] A/B paywall scenarios

## License
MIT. See `LICENSE`.
