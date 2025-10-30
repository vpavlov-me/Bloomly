# Snapshot Testing Guide

## Overview

Snapshot testing is implemented using [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to prevent UI regressions across the application. This document describes how to work with snapshot tests in the project.

## Architecture

### Test Coverage

Snapshot tests are distributed across feature modules:

- **Tracking Module** ([Packages/Tracking/Tests/Tracking/](../Packages/Tracking/Tests/Tracking/))
  - `DashboardSnapshotTests.swift` - Dashboard views (empty, with data, active timers)
  - `TrackingSnapshotTests.swift` - Tracking screens (Sleep, Feed, Diaper, Pumping)

- **Timeline Module** ([Packages/Timeline/Tests/Timeline/](../Packages/Timeline/Tests/Timeline/))
  - `TimelineSnapshotTests.swift` - Timeline views with variants

- **Paywall Module** ([Packages/Paywall/Tests/Paywall/](../Packages/Paywall/Tests/Paywall/))
  - `PaywallSnapshotTests.swift` - Paywall and subscription screens

- **DesignSystem Module** ([Packages/DesignSystem/Tests/DesignSystem/](../Packages/DesignSystem/Tests/DesignSystem/))
  - `ButtonStyleSnapshotTests.swift` - UI component tests

### Test Variants

Each screen is tested across multiple dimensions:

1. **Color Schemes**: Light mode, Dark mode
2. **Device Sizes**: iPhone SE, iPhone 13 Pro, iPhone 15 Pro Max
3. **States**: Empty, Loading, With Data, Error
4. **Locales**: English (en), Russian (ru) - where applicable

## Running Snapshot Tests

### Recording New Snapshots

When creating new tests or updating UI, you need to record reference snapshots:

```bash
# Record snapshots for all tests
SNAPSHOT_RECORD=1 xcodebuild -workspace Bloomy.xcworkspace \
  -scheme Bloomy \
  -destination 'platform=iOS Simulator,id=<DEVICE_ID>' \
  -skipPackagePluginValidation test

# Or for a specific test
SNAPSHOT_RECORD=1 xcodebuild -workspace Bloomy.xcworkspace \
  -scheme Bloomy \
  -destination 'platform=iOS Simulator,id=<DEVICE_ID>' \
  -only-testing:TrackingTests/DashboardSnapshotTests \
  -skipPackagePluginValidation test
```

### Verifying Snapshots

Run tests without the `SNAPSHOT_RECORD` environment variable to verify against recorded snapshots:

```bash
xcodebuild -workspace Bloomy.xcworkspace \
  -scheme Bloomy \
  -destination 'platform=iOS Simulator,id=<DEVICE_ID>' \
  -skipPackagePluginValidation test
```

### Finding Simulator Device IDs

```bash
xcrun simctl list devices available
```

## Writing Snapshot Tests

### Basic Structure

```swift
import XCTest
import SwiftUI
import SnapshotTesting
@testable import YourModule

final class YourViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Enable recording mode when SNAPSHOT_RECORD=1 is set
        isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    func testYourView() throws {
        let viewModel = YourViewModel(/* dependencies */)
        let view = YourView(viewModel: viewModel)

        // Skip test if snapshot doesn't exist (prevents CI failures)
        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // Helper to check if reference snapshot exists
    private func referenceExists(for testName: String) -> Bool {
        let testClass = String(describing: type(of: self))
        let snapshotsPath = "__Snapshots__/\\(testClass)/\\(testName).png"
        return FileManager.default.fileExists(atPath: snapshotsPath)
    }
}
```

### Testing Multiple Variants

```swift
func testDashboardLightMode() throws {
    let view = DashboardView(viewModel: viewModel)
        .preferredColorScheme(.light)

    assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
}

func testDashboardDarkMode() throws {
    let view = DashboardView(viewModel: viewModel)
        .preferredColorScheme(.dark)

    assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
}

func testDashboardSmallDevice() throws {
    let view = DashboardView(viewModel: viewModel)

    assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
}
```

### Using MockEventsRepository

For testing, use `MockEventsRepository` to provide controlled test data:

```swift
let events = [
    EventDTO(kind: .sleep, start: Date().addingTimeInterval(-3600), end: Date()),
    EventDTO(kind: .feeding, start: Date().addingTimeInterval(-1800))
]

let lastEvents: [EventKind: EventDTO] = [
    .sleep: events[0],
    .feeding: events[1]
]

let repository = MockEventsRepository(events: events, lastEvents: lastEvents)
let viewModel = DashboardViewModel(eventsRepository: repository)
```

## CI Integration

### GitHub Actions Workflow

Snapshot tests run automatically on all PRs:

```yaml
- name: Run Tests
  run: |
    xcodebuild -workspace Bloomy.xcworkspace \
      -scheme Bloomy \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -skipPackagePluginValidation test
```

### Handling Failures

When snapshot tests fail in CI:

1. **Review the failure** - Check if the UI change was intentional
2. **If intentional**: Re-record snapshots locally and commit
3. **If regression**: Fix the UI issue

Artifacts are uploaded on failure:
```yaml
- name: Upload Test Results
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: snapshot-test-failures
    path: |
      **/__Snapshots__/**/*
```

## Best Practices

### 1. Test Important Screens

Focus on:
- User-facing screens (Dashboard, Timeline, Tracking views)
- Complex layouts (Charts, Tables)
- Critical flows (Onboarding, Paywall)

### 2. Test Multiple States

For each screen, test:
- Empty state
- Loading state
- Populated state
- Error state

### 3. Minimize Test Data

Use minimal, representative data:

```swift
// Good: Minimal data that demonstrates layout
let events = [
    EventDTO(kind: .sleep, start: yesterday, end: today)
]

// Bad: Too much data, hard to debug failures
let events = (0..<100).map { EventDTO(...) }
```

### 4. Isolate Tests

Each test should be independent:

```swift
// Good: Fresh viewModel per test
func testDashboard() {
    let viewModel = makeFreshViewModel()
    // ...
}

// Bad: Shared state
static let viewModel = ...
func testDashboard() {
    // Uses shared state
}
```

### 5. Name Tests Clearly

Use descriptive names:

```swift
// Good
func testDashboardEmptyState()
func testDashboardWithActiveTimer()
func testDashboardDarkMode()

// Bad
func testDashboard1()
func testDashboard2()
```

## Troubleshooting

### Test Failures Due to Fonts

If tests fail with font rendering differences:
- Ensure the simulator has the same font setup as CI
- Consider using fixed font sizes in tests

### Test Failures Due to Dates

Avoid using `Date()` directly in snapshot tests:

```swift
// Bad: Changes every time
let event = EventDTO(start: Date())

// Good: Fixed date
let fixedDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
let event = EventDTO(start: fixedDate)
```

### Snapshot Differences

When comparing snapshots locally vs CI:
- Use the same iOS simulator version
- Ensure simulator is in the same state (appearance, locale)
- Check for animations or timing-dependent UI

## References

- [swift-snapshot-testing Documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [Point-Free Episode: Snapshot Testing](https://www.pointfree.co/episodes/ep41-a-tour-of-snapshot-testing)
