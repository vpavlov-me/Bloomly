

# Error Handling Guide

This document outlines the comprehensive error handling strategy implemented in bloomy.

## Overview

bloomy implements a robust error handling system that:
- Provides user-friendly error messages
- Offers automatic recovery mechanisms
- Logs errors for debugging and analytics
- Prevents cascading failures with circuit breakers
- Supports retry logic with exponential backoff

## Architecture

### Error Hierarchy

All errors are represented using `AppError` enum, which provides:
- **User-friendly messages**: No technical jargon
- **Recovery suggestions**: Actionable steps for users
- **Severity levels**: Critical, Error, Warning, Info
- **Retry capability**: Automatic identification of retryable errors
- **Analytics tracking**: Automatic reporting of critical issues

```swift
// Example: Network error with user-friendly message
let error = AppError.networkUnavailable
print(error.errorDescription) // "No internet connection"
print(error.recoverySuggestion) // "Connect to the internet and try again."
```

### Error Categories

#### 1. Data Layer Errors
- `dataCorruption`: Database integrity issues
- `storageFailure`: Unable to save/read data
- `constraintViolation`: Data validation failures
- `notFound`: Record doesn't exist
- `invalidState`: Operation not allowed in current state

#### 2. Network & Sync Errors
- `networkUnavailable`: No internet connection
- `syncConflict`: Conflicting changes detected
- `cloudKitFailure`: iCloud sync issues
- `authenticationRequired`: User not signed in
- `quotaExceeded`: Storage limit reached

#### 3. Permission Errors
- `permissionDenied`: System permission required
- `notificationPermissionDenied`: Notification access needed

#### 4. In-App Purchase Errors
- `purchaseFailed`: Payment processing error
- `productNotFound`: Product unavailable
- `receiptValidationFailed`: Purchase verification failed
- `restoreFailed`: Unable to restore purchases

#### 5. Validation Errors
- `validationError`: Form validation failed
- `invalidInput`: Invalid user input
- `dateRangeInvalid`: Invalid date range
- `requiredFieldMissing`: Required field empty

#### 6. State Management Errors
- `appInterrupted`: Activity was interrupted
- `stateRestorationFailed`: Can't restore previous state
- `concurrentModification`: Data modified elsewhere

#### 7. System Errors
- `lowStorage`: Device storage low
- `lowMemory`: Memory pressure
- `backgroundTaskFailed`: Background operation failed

## Usage

### Basic Error Handling

```swift
// Method 1: Using do-catch
do {
    let event = try await repository.create(eventDTO)
    // Success handling
} catch {
    let appError = AppError.from(error)
    appError.log(context: ["operation": "create_event"])
    // Show error to user
    self.error = appError
}

// Method 2: Using Result type
let result = Result {
    try await repository.create(eventDTO)
}

switch result {
case .success(let event):
    // Handle success
case .failure(let error):
    let appError = AppError.from(error)
    // Handle error
}
```

### Automatic Retry

```swift
// Using ErrorRecovery
let recovery = ErrorRecovery()

let event = try await recovery.withRetry(operation: "create_event") {
    try await repository.create(eventDTO)
}

// Using Task extension
let event = try await Task.withRetry(maxAttempts: 3, delay: 2.0) {
    try await repository.create(eventDTO)
}
```

### Circuit Breaker

Prevent repeated calls to failing services:

```swift
let circuitBreaker = CircuitBreaker(failureThreshold: 5, timeout: 60)

let result = try await circuitBreaker.execute {
    try await syncService.pullChanges()
}
```

### Error Logging

```swift
// Automatic logging with context
error.log(context: [
    "user_id": currentUser.id,
    "operation": "sync",
    "attempt": "3"
])

// Global error logger
await GlobalErrorLogger.shared.log(error, context: ["screen": "timeline"])

// View recent errors (for debugging)
let recentErrors = await GlobalErrorLogger.shared.recentErrors(limit: 10)
```

### UI Presentation

#### Alert Style

```swift
@State private var error: AppError?

var body: some View {
    content
        .errorAlert(error: $error) {
            // Retry action
            Task {
                await retryOperation()
            }
        }
}
```

#### Sheet Style

```swift
@State private var error: AppError?

var body: some View {
    content
        .errorSheet(error: $error) {
            // Retry action
            Task {
                await retryOperation()
            }
        }
}
```

#### Inline Style

```swift
if let error = validationError {
    InlineErrorView(error: error)
}
```

#### Loading State

```swift
@State private var loadingState: LoadingState = .idle

var body: some View {
    LoadingStateView(state: loadingState, onRetry: retry) {
        // Your content when loaded
        contentView
    }
}
```

## Best Practices

### 1. Always Convert to AppError

```swift
// ❌ Bad: Generic error handling
catch {
    print("Error: \(error)")
}

// ✅ Good: Convert to AppError
catch {
    let appError = AppError.from(error)
    appError.log()
    self.error = appError
}
```

### 2. Provide Context

```swift
// ❌ Bad: No context
error.log()

// ✅ Good: Rich context
error.log(context: [
    "operation": "save_event",
    "event_type": "sleep",
    "user_id": user.id,
    "timestamp": Date().ISO8601Format()
])
```

### 3. Use Appropriate Error Types

```swift
// ❌ Bad: Generic error
throw NSError(domain: "App", code: 1)

// ✅ Good: Specific error with details
throw AppError.validationError(
    field: "end_time",
    reason: "End time must be after start time"
)
```

### 4. Handle Errors at the Right Level

```swift
// Repository layer: Throw errors
func create(_ event: EventDTO) async throws -> EventDTO {
    guard isValid(event) else {
        throw AppError.validationError(field: "event", reason: "Invalid data")
    }
    // ...
}

// ViewModel layer: Catch and log
func saveEvent() async {
    do {
        let event = try await repository.create(eventDTO)
        // Update UI
    } catch {
        let appError = AppError.from(error)
        appError.log(context: ["view": "EventForm"])
        self.error = appError
    }
}

// View layer: Present to user
var body: some View {
    content
        .errorAlert(error: $viewModel.error)
}
```

### 5. Implement Recovery

```swift
// Add retry logic for transient failures
func syncData() async {
    do {
        try await Task.withRetry(maxAttempts: 3) {
            try await syncService.pullChanges()
        }
    } catch {
        // Handle after all retries failed
        let appError = AppError.from(error)

        // Try recovery
        do {
            try await errorRecovery.recover(from: appError)
            // Retry after recovery
            try await syncData()
        } catch {
            // Show error to user
            self.error = appError
        }
    }
}
```

## Error Recovery Strategies

### Network Errors
- **Detection**: Check for NSURLErrorDomain errors
- **Recovery**: Wait for network connectivity
- **Retry**: Automatic with exponential backoff
- **User Action**: None required (automatic)

### Storage Errors
- **Detection**: NSCocoaErrorDomain errors
- **Recovery**: Clear caches, free up space
- **Retry**: Manual retry available
- **User Action**: May need to free storage

### Sync Conflicts
- **Detection**: CloudKit conflict errors
- **Recovery**: Last-write-wins strategy
- **Retry**: Automatic
- **User Action**: None (resolved automatically)

### Validation Errors
- **Detection**: Business logic validation
- **Recovery**: None (user input required)
- **Retry**: Not applicable
- **User Action**: Fix input and resubmit

### Permission Errors
- **Detection**: System permission checks
- **Recovery**: Direct user to Settings
- **Retry**: After permission granted
- **User Action**: Grant permission in Settings

## Testing Error Handling

### Unit Tests

```swift
func testErrorHandling() async throws {
    // Test error conversion
    let nsError = NSError(domain: NSCocoaErrorDomain, code: 134030)
    let appError = AppError.from(nsError)
    XCTAssertEqual(appError, .constraintViolation)

    // Test retry logic
    var attemptCount = 0
    let result = try await Task.withRetry(maxAttempts: 3) {
        attemptCount += 1
        if attemptCount < 3 {
            throw AppError.networkUnavailable
        }
        return "success"
    }
    XCTAssertEqual(attemptCount, 3)
    XCTAssertEqual(result, "success")
}
```

### Integration Tests

```swift
func testErrorRecovery() async throws {
    // Simulate network failure
    networkSimulator.setConnectivity(false)

    // Should fail with network error
    do {
        try await syncService.sync()
        XCTFail("Should have thrown")
    } catch let error as AppError {
        XCTAssertEqual(error, .networkUnavailable)
    }

    // Restore network
    networkSimulator.setConnectivity(true)

    // Should succeed after recovery
    try await syncService.sync()
}
```

### UI Tests

```swift
func testErrorPresentation() throws {
    // Trigger error
    app.buttons["Save"].tap()

    // Verify error alert
    XCTAssertTrue(app.alerts.firstMatch.exists)
    XCTAssertTrue(app.alerts.firstMatch.staticTexts["No internet connection"].exists)

    // Verify retry button
    XCTAssertTrue(app.alerts.buttons["Try Again"].exists)

    // Test retry
    app.alerts.buttons["Try Again"].tap()
}
```

## Monitoring and Analytics

### Error Metrics to Track

1. **Error Rate**: Errors per user session
2. **Error Types**: Distribution by error category
3. **Recovery Success Rate**: Successful retries / total errors
4. **Time to Recovery**: Duration from error to resolution
5. **Critical Errors**: Data corruption, storage failures
6. **User-Facing Errors**: Validation, permission errors

### Analytics Events

```swift
// Automatic tracking for critical errors
error.log() // Sends to analytics if shouldReport == true

// Custom events
analytics.track(AnalyticsEvent(
    name: "error_recovered",
    metadata: [
        "error_type": error.id,
        "recovery_method": "automatic_retry",
        "attempts": "3"
    ]
))
```

## Common Scenarios

### Scenario 1: Network Request Fails

```swift
func loadEvents() async {
    loadingState = .loading

    do {
        let events = try await Task.withRetry(maxAttempts: 3) {
            try await repository.events(in: nil, kind: nil)
        }
        self.events = events
        loadingState = .loaded
    } catch {
        let appError = AppError.from(error)
        appError.log(context: ["screen": "timeline"])
        loadingState = .error(appError)
    }
}
```

### Scenario 2: Form Validation Fails

```swift
func validateAndSave() async {
    guard let endTime = endTime, endTime > startTime else {
        error = .dateRangeInvalid
        return
    }

    guard !notes.isEmpty else {
        error = .requiredFieldMissing(field: "notes")
        return
    }

    // Save if validation passes
    await saveEvent()
}
```

### Scenario 3: App Interrupted During Operation

```swift
// Save state before suspension
func sceneDidEnterBackground() {
    if isActiveOperation {
        saveOperationState()
    }
}

// Restore state on return
func sceneWillEnterForeground() {
    if let savedState = loadOperationState() {
        do {
            try restoreOperation(from: savedState)
        } catch {
            error = .stateRestorationFailed
            clearOperationState()
        }
    }
}
```

### Scenario 4: Concurrent Modification Detected

```swift
func updateEvent(_ event: EventDTO) async {
    do {
        let updated = try await repository.update(event)
        self.event = updated
    } catch {
        let appError = AppError.from(error)

        if case .concurrentModification = appError {
            // Refresh and show conflict
            await refreshEvent()
            showConflictDialog = true
        } else {
            self.error = appError
        }
    }
}
```

## Resources

- [Apple Error Handling Best Practices](https://developer.apple.com/documentation/swift/error-handling)
- [Network Error Handling](https://developer.apple.com/documentation/foundation/url_loading_system/handling_an_authentication_challenge)
- [CloudKit Error Handling](https://developer.apple.com/documentation/cloudkit/ckerror)

## Summary

bloomy's error handling system ensures:
- ✅ User-friendly error messages
- ✅ Automatic recovery for transient failures
- ✅ Comprehensive logging and analytics
- ✅ Circuit breaker pattern for failing services
- ✅ Consistent error presentation across the app
- ✅ Graceful degradation
- ✅ State preservation during interruptions

For questions or issues, please refer to the error logs or contact the development team.
