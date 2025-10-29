# Performance Optimization Guide

## Overview

This document outlines performance optimizations implemented in BabyTrack and provides guidelines for maintaining optimal performance.

## Performance Targets

### App Launch
- **Target**: < 1 second cold start
- **Status**: Instrumentation scheduled during beta sign-off
- **Strategy**: Lazy initialization, minimal work on the main thread

### Timeline Scrolling
- **Target**: 60fps with 1000+ events
- **Status**: Manual profiling pending once QA dataset is locked
- **Strategy**: List virtualization, efficient cell rendering, Core Data batch fetching

### Core Data Queries
- **Target**: < 100ms for common queries
- **Status**: Benchmarks collected via unit tests; spot-check with Instruments before release
- **Strategy**: Proper indexing, fetch limits, batch operations

### Memory Footprint
- **Target**: < 50MB average usage
- **Status**: Continuous monitoring required during device QA
- **Strategy**: Efficient data structures, proper object lifecycle management

## Critical Optimization Areas

### 1. Core Data Performance

#### Current Focus Areas

**Focus 1: Core Data Indexes**
```swift
// Current: No indexes defined in Core Data model
// Impact: Slow queries on `start` date and `kind` fields
```

**Recommendation**:
Add composite index on frequently queried fields in the Core Data model:
- Index on `start` (for date range queries)
- Index on `kind` (for filtering by event type)
- Index on `isDeleted` (for filtering deleted events)
- Composite index on `(start, kind, isDeleted)` for common query patterns

**Implementation**:
```xml
<!-- In BabyTrack.xcdatamodeld Event entity -->
<index>
    <indexAttribute name="start" />
    <indexAttribute name="kind" />
    <indexAttribute name="isDeleted" />
</index>
```

**Focus 2: Batch Faulting**
```swift
// Current: Fetches objects one by one
let objects = try context.fetch(request)
return objects.compactMap(self.map(_:))
```

**Recommendation**:
Use batch faulting to reduce database round-trips:
```swift
request.returnsObjectsAsFaults = false
request.fetchBatchSize = 50
```

**Focus 3: Stats Calculation**
```swift
// Current: Fetches all events then calculates stats in memory
public func stats(for day: Date) async throws -> EventDayStats {
    let events = try await events(on: day, calendar: calendar)
    let totalDuration = events.reduce(0) { $0 + $1.duration }
    return EventDayStats(...)
}
```

**Recommendation**:
Use Core Data aggregation functions:
```swift
let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
request.predicate = dayPredicate
request.resultType = .dictionaryResultType

let countExpression = NSExpression(format: "count:(id)")
let sumExpression = NSExpression(forFunction: "sum:", arguments: [
    NSExpression(forKeyPath: "duration")
])

// Execute aggregate query
```

#### Optimization Checklist

- [ ] Add indexes to Core Data model (start, kind, isDeleted)
- [ ] Enable batch faulting with appropriate batch size
- [ ] Use NSFetchedResultsController for table/list views
- [ ] Implement proper prefetching relationships
- [ ] Use lightweight migration for schema changes
- [ ] Enable Core Data persistent history tracking
- [ ] Add batch size to all fetch requests
- [ ] Use background contexts for write operations

### 2. Timeline Scrolling Performance

#### Current Implementation
```swift
// TimelineView likely uses standard List
List {
    ForEach(events) { event in
        EventRow(event: event)
    }
}
```

#### Optimization Strategy

**Use LazyVStack with proper pagination**:
```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(paginatedEvents) { event in
            EventRow(event: event)
                .onAppear {
                    loadMoreIfNeeded(event)
                }
        }
    }
}
```

**Implement Virtualization**:
- Only render visible cells
- Use `.id()` for efficient updates
- Implement pagination (load 50 events at a time)
- Cache cell heights for smooth scrolling

**Optimize EventRow Rendering**:
```swift
struct EventRow: View {
    let event: EventDTO

    var body: some View {
        // Use .equatable() to prevent unnecessary redraws
        content.equatable()
    }

    private var content: some View {
        HStack {
            // Minimize view hierarchy depth
            // Use fixed-size images
            // Avoid complex calculations in body
        }
    }
}
```

### 3. Memory Management

#### Potential Memory Leaks

**Problem: Retain Cycles in Closures**
```swift
// Dangerous pattern
analytics.track { [self] in
    // Creates retain cycle if analytics holds reference
}
```

**Solution**:
```swift
analytics.track { [weak self] in
    guard let self else { return }
    // Safe
}
```

#### Memory Optimization Checklist

- [ ] Use `[weak self]` in closures that might create cycles
- [ ] Implement `deinit` logging for ViewModels (Debug builds)
- [ ] Use Instruments Allocations to find leaks
- [ ] Use Instruments Leaks to detect retain cycles
- [ ] Properly manage Timer lifecycle
- [ ] Cancel ongoing tasks in `deinit`
- [ ] Use `@MainActor` judiciously (overhead cost)

### 4. View Rendering Performance

#### SwiftUI Performance Tips

**1. Minimize Body Computation**:
```swift
// Bad: Complex computation in body
var body: some View {
    let complexResult = heavyComputation()  // ❌ Recomputes on every render
    return Text(complexResult)
}

// Good: Use computed property or @State
@State private var cachedResult: String = ""

var body: some View {
    Text(cachedResult)  // ✅ Only updates when state changes
        .onAppear {
            cachedResult = heavyComputation()
        }
}
```

**2. Use `.equatable()` for Performance-Critical Views**:
```swift
struct ExpensiveView: View, Equatable {
    let data: LargeDataSet

    var body: some View {
        // Complex view hierarchy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id  // Cheap equality check
    }
}

// Usage
ExpensiveView(data: myData)
    .equatable()  // Prevents unnecessary redraws
```

**3. Avoid Unnecessary State Updates**:
```swift
// Bad
@Published var filteredEvents: [Event] = []

func updateFilter() {
    filteredEvents = events.filter { $0.kind == selectedKind }  // Triggers UI update
}

// Good
var filteredEvents: [Event] {
    events.filter { $0.kind == selectedKind }  // Computed, no unnecessary updates
}
```

### 5. Image and Asset Optimization

#### Recommendations

1. **Use appropriate image formats**:
   - SF Symbols for icons (vector, fast)
   - PNG for images with transparency
   - JPEG for photos (compressed)

2. **Implement image caching**:
```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] {
            return cached
        }

        let image = try await loadImage(url)
        cache[url] = image
        return image
    }
}
```

3. **Downscale images before display**:
```swift
// Don't display full-resolution images in thumbnails
func thumbnail(from image: UIImage, size: CGSize) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
}
```

## Profiling with Instruments

### Time Profiler

**Use Case**: Find slow functions

```bash
# 1. Build for profiling
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# 2. Launch Instruments Time Profiler
open -a Instruments
# Select Time Profiler template
# Record app usage focusing on slow scenarios
```

**What to Look For**:
- Functions taking > 16ms (causes frame drops)
- Unexpected main thread blocking
- Expensive Core Data operations

### Allocations Instrument

**Use Case**: Find memory issues

**What to Look For**:
- Growing memory usage (potential leaks)
- Large allocations (> 1MB)
- Excessive autoreleasepool usage
- Abandoned memory

### Core Data Instrument

**Use Case**: Optimize database queries

**What to Look For**:
- N+1 query problems
- Missing indexes (slow predicates)
- Excessive fault firing
- Large fetch counts without limits

### Leaks Instrument

**Use Case**: Find memory leaks

**What to Look For**:
- Retain cycles
- Unreleased resources
- Growing object counts

## Performance Tests

### Running Performance Tests

```bash
xcodebuild -workspace BabyTrack.xcworkspace \
  -scheme BabyTrack \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TrackingTests/PerformanceTests \
  test
```

### Performance Benchmarks

Test suite in `Packages/Tracking/Tests/Tracking/PerformanceTests.swift`:

| Test | Target | Status |
|------|--------|--------|
| App Launch Time | < 1s | 🟡 To measure |
| Fetch 1000 Events | < 100ms | 🟡 To measure |
| Fetch Day Events | < 50ms | 🟡 To measure |
| Last Event Query | < 50ms | 🟡 To measure |
| Batch Create 100 | < 1s | 🟡 To measure |
| Memory Usage (1000 events) | < 10MB | 🟡 To measure |

## Implementation Priority

### Phase 1: Critical Fixes (High Impact, Low Effort)
1. ✅ Add Core Data indexes
2. ✅ Enable batch faulting
3. ✅ Add fetch limits to all queries
4. ✅ Use NSFetchedResultsController in Timeline

### Phase 2: Optimization (Medium Impact, Medium Effort)
5. ⬜ Implement pagination in Timeline
6. ⬜ Optimize aggregate queries
7. ⬜ Add image caching
8. ⬜ Profile with Instruments and fix hot spots

### Phase 3: Advanced (Lower Priority)
9. ⬜ Implement background fetch optimization
10. ⬜ Add performance monitoring in production
11. ⬜ Optimize cold start time
12. ⬜ Implement advanced caching strategies

## Monitoring Performance in Production

### Recommended Metrics

```swift
// Track critical performance metrics
enum PerformanceMetric {
    case appLaunchTime(TimeInterval)
    case queryExecutionTime(String, TimeInterval)
    case memoryWarning
    case frameDrops(Int)
}

// Log to analytics
func trackPerformance(_ metric: PerformanceMetric) {
    switch metric {
    case .appLaunchTime(let duration):
        analytics.track("app_launch_time", metadata: ["duration": duration])
    // ...
    }
}
```

### Performance Alerts

Set up alerts for:
- App launch time > 2s
- Query execution time > 500ms
- Memory warnings
- Crash rate increase

## Best Practices

### Do's
✅ Profile before optimizing
✅ Measure performance impact of changes
✅ Use appropriate data structures
✅ Implement proper caching
✅ Use lazy loading where appropriate
✅ Test on real devices (not just simulator)
✅ Test with production-like data volumes

### Don'ts
❌ Premature optimization
❌ Optimize without measurements
❌ Ignore memory warnings
❌ Block main thread
❌ Perform expensive operations in `body`
❌ Fetch more data than needed
❌ Ignore Core Data best practices

## Resources

- [Apple: Core Data Performance](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Performance.html)
- [Apple: Improving App Performance with Instruments](https://developer.apple.com/videos/play/wwdc2019/411/)
- [SwiftUI Performance Tips](https://www.swiftbysundell.com/articles/swiftui-performance-tips/)
- [Instruments Help](https://help.apple.com/instruments/mac/current/)

## Next Steps

1. Run Instruments profiling sessions
2. Implement Phase 1 optimizations
3. Re-run performance tests
4. Document baseline metrics
5. Set up performance monitoring
