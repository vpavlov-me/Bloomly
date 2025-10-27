# Analytics Implementation Guide

This document describes how to use and extend the analytics system in the BabyTrack app.

## Overview

The app uses **TelemetryDeck** for privacy-first, GDPR-compliant analytics. No personally identifiable information (PII) is collected.

## Architecture

```
┌─────────────────┐
│  Your Code      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Analytics       │◄─── Protocol
│ Protocol        │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌──────┐  ┌──────────────────┐
│ Mock │  │ TelemetryDeck    │
│      │  │ Analytics        │
└──────┘  └──────────────────┘
```

## Usage

### 1. Initialize Analytics

In your app's initialization:

```swift
import AppSupport

let analytics = TelemetryDeckAnalytics(appID: "YOUR-TELEMETRY-DECK-APP-ID")
```

### 2. Track Events

#### Using Convenience Methods

```swift
// App lifecycle
analytics.trackAppLaunched()
analytics.trackAppBackgrounded()

// Screen views
analytics.trackScreenView("Dashboard")

// Feature usage
analytics.trackFeatureUsed("SleepTracking")

// Errors (anonymized)
analytics.trackError(someError, domain: "repository")
```

#### Using Predefined Event Types

```swift
import AppSupport

// Track a predefined event
analytics.track(AnalyticsEvent(type: .dashboardViewed))

// With metadata
analytics.track(AnalyticsEvent(
    type: .eventCreated,
    metadata: ["eventKind": "sleep"]
))
```

#### Custom Events

```swift
analytics.track(AnalyticsEvent(
    name: "custom.event.name",
    metadata: ["key": "value"]
))
```

## Adding New Event Types

### Step 1: Define Event Type

Edit `AnalyticsEventType.swift`:

```swift
public enum AnalyticsEventType: String, Sendable {
    // ... existing events ...

    case myNewFeature = "feature.myNewFeature.used"
}
```

### Step 2: Add Convenience Method (Optional)

Edit `AnalyticsEventType.swift` extension:

```swift
public extension AnalyticsEvent {
    static func myNewFeatureUsed(param: String) -> AnalyticsEvent {
        AnalyticsEvent(
            type: .myNewFeature,
            metadata: ["param": param]
        )
    }
}
```

### Step 3: Use It

```swift
analytics.track(AnalyticsEvent.myNewFeatureUsed(param: "value"))
```

## Privacy Guidelines

### ✅ DO:
- Track feature usage
- Track screen views
- Track error types (not error messages)
- Use anonymized metadata

### ❌ DON'T:
- Track user names or emails
- Track baby names or birthdates
- Track photo data
- Track exact timestamps (use day/hour buckets)
- Track notes or user-entered text

## Testing

### Using MockAnalytics

```swift
let mock = MockAnalytics()
mock.track(AnalyticsEvent(type: .appLaunched))

// Verify event was tracked
XCTAssertTrue(mock.wasTracked("app.launched"))
XCTAssertEqual(mock.count(for: "app.launched"), 1)

// Reset for next test
mock.reset()
```

## Opt-Out Support

Users can disable analytics in Settings:

```swift
let analytics = TelemetryDeckAnalytics(appID: appID)

// Disable tracking
analytics.disable()

// Re-enable
analytics.enable()

// Check status
if analytics.enabled {
    analytics.trackFeatureUsed("Feature")
}
```

## Available Event Types

### App Lifecycle
- `app.launched`
- `app.backgrounded`
- `app.foregrounded`
- `app.terminated`

### Feature Usage
- `tracking.sleep.started`
- `tracking.sleep.stopped`
- `tracking.feeding.tracked`
- `tracking.diaper.tracked`
- `tracking.pumping.tracked`

### Screen Views
- `screen.dashboard.viewed`
- `screen.timeline.viewed`
- `screen.charts.viewed`
- `screen.settings.viewed`
- `screen.babyProfile.viewed`

### User Actions
- `event.created`
- `event.updated`
- `event.deleted`
- `baby.created`
- `baby.updated`
- `baby.photo.added`

### Errors (Anonymized)
- `error.occurred`
- `sync.failed`
- `data.loadFailed`

### Settings
- `settings.analytics.optedOut`
- `settings.analytics.optedIn`
- `settings.notifications.enabled`
- `settings.notifications.disabled`

### Onboarding
- `onboarding.started`
- `onboarding.completed`
- `onboarding.skipped`

## Best Practices

1. **Track User Intent, Not Actions**: Track what the user wanted to do, not every tap
2. **Use Metadata Wisely**: Add context without revealing PII
3. **Keep Events Focused**: One event should represent one thing
4. **Be Consistent**: Use similar naming patterns for similar events
5. **Document New Events**: Update this file when adding new event types

## Examples

### Tracking Sleep Event

```swift
analytics.track(AnalyticsEvent(
    type: .sleepTrackingStarted,
    metadata: ["source": "quickLog"]
))

// ... user sleeps ...

analytics.track(AnalyticsEvent(
    type: .sleepTrackingStopped,
    metadata: [
        "duration": "short", // "short", "medium", "long" - not exact minutes
        "timeOfDay": "night" // "morning", "afternoon", "evening", "night"
    ]
))
```

### Tracking Screen Navigation

```swift
struct DashboardView: View {
    @Environment(\.analytics) var analytics

    var body: some View {
        VStack {
            // content
        }
        .onAppear {
            analytics.trackScreenView("Dashboard")
        }
    }
}
```

### Tracking Errors

```swift
do {
    try await repository.create(event)
} catch {
    analytics.trackError(error, domain: "repository")
    // handle error
}
```

## TelemetryDeck Dashboard

View your analytics at: https://dashboard.telemetrydeck.com/

## Resources

- [TelemetryDeck Documentation](https://telemetrydeck.com/docs/)
- [TelemetryDeck Swift SDK](https://github.com/TelemetryDeck/SwiftSDK)
- [GDPR Compliance](https://telemetrydeck.com/privacy/)
