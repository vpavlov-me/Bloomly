import AppSupport
import XCTest
@testable import Tracking

@MainActor
final class SleepTrackingViewModelTests: XCTestCase {
    private var viewModel: SleepTrackingViewModel!
    private var mockRepository: InMemoryEventsRepository!
    private var mockAnalytics: MockAnalytics!

    override func setUp() async throws {
        mockRepository = InMemoryEventsRepository()
        mockAnalytics = MockAnalytics()
        viewModel = SleepTrackingViewModel(
            repository: mockRepository,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockAnalytics = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.selectedQuality)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showSuccess)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(viewModel.isActive)
    }

    // MARK: - Timer Tests

    func testStartSleep() {
        viewModel.startSleep()

        XCTAssertTrue(viewModel.isActive)
        if case .active(let startTime) = viewModel.state {
            XCTAssertTrue(abs(startTime.timeIntervalSinceNow) < 1.0)
        } else {
            XCTFail("State should be active")
        }

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.sleep.started"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "tracking.sleep.started" }
        XCTAssertEqual(events.first?.metadata["action"], "started")
    }

    func testStopSleep() {
        viewModel.startSleep()
        viewModel.stopSleep()

        if case .completed(let duration) = viewModel.state {
            XCTAssertGreaterThan(duration, 0)
        } else {
            XCTFail("State should be completed")
        }

        XCTAssertFalse(viewModel.isActive)

        // Verify analytics
        let events = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.sleep.stopped" && $0.metadata["action"] == "stopped"
        }
        XCTAssertEqual(events.count, 1)
    }

    func testCancelSession() {
        viewModel.startSleep()
        viewModel.selectedQuality = .good
        viewModel.notes = "Test"

        viewModel.cancelSession()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.selectedQuality)
        XCTAssertEqual(viewModel.notes, "")
    }

    func testElapsedTimeUpdates() async throws {
        viewModel.startSleep()

        // Wait a bit for timer to tick
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        XCTAssertGreaterThan(viewModel.elapsedTime, 1.0)
        XCTAssertLessThan(viewModel.elapsedTime, 2.0)
    }

    func testFormattedElapsedTime() {
        // Under 1 hour - show MM:SS
        viewModel.elapsedTime = 0
        XCTAssertEqual(viewModel.formattedElapsedTime, "00:00")

        viewModel.elapsedTime = 65
        XCTAssertEqual(viewModel.formattedElapsedTime, "01:05")

        viewModel.elapsedTime = 600
        XCTAssertEqual(viewModel.formattedElapsedTime, "10:00")

        // Over 1 hour - show HH:MM:SS
        viewModel.elapsedTime = 3661 // 1h 1m 1s
        XCTAssertEqual(viewModel.formattedElapsedTime, "01:01:01")

        viewModel.elapsedTime = 7200 // 2h
        XCTAssertEqual(viewModel.formattedElapsedTime, "02:00:00")
    }

    func testFormattedDuration() {
        viewModel.startSleep()
        viewModel.stopSleep()

        let formatted = viewModel.formattedDuration
        XCTAssertFalse(formatted.isEmpty)
        // Should contain either "h" or "m"
        XCTAssertTrue(formatted.contains("h") || formatted.contains("m"))
    }

    // MARK: - Quality Selection Tests

    func testSetQuality() {
        viewModel.selectedQuality = .good
        XCTAssertEqual(viewModel.selectedQuality, .good)

        viewModel.selectedQuality = .restless
        XCTAssertEqual(viewModel.selectedQuality, .restless)

        viewModel.selectedQuality = .short
        XCTAssertEqual(viewModel.selectedQuality, .short)
    }

    func testSleepQualityProperties() {
        XCTAssertEqual(SleepQuality.good.symbol, "😴")
        XCTAssertEqual(SleepQuality.restless.symbol, "😵‍💫")
        XCTAssertEqual(SleepQuality.short.symbol, "🥱")

        XCTAssertEqual(SleepQuality.good.id, "Good")
        XCTAssertEqual(SleepQuality.restless.id, "Restless")
        XCTAssertEqual(SleepQuality.short.id, "Short")
    }

    func testSleepQualityAllCases() {
        XCTAssertEqual(SleepQuality.allCases.count, 3)
        XCTAssertTrue(SleepQuality.allCases.contains(.good))
        XCTAssertTrue(SleepQuality.allCases.contains(.restless))
        XCTAssertTrue(SleepQuality.allCases.contains(.short))
    }

    // MARK: - Save Tests

    func testSaveSleepSuccess() async {
        viewModel.startSleep()
        viewModel.stopSleep()
        viewModel.selectedQuality = .good

        await viewModel.saveSleep()

        // Verify event was created
        let events = try? await mockRepository.events(in: nil, kind: .sleep)
        XCTAssertEqual(events?.count, 1)

        let event = events?.first
        XCTAssertEqual(event?.kind, .sleep)
        XCTAssertTrue(event?.notes?.contains("Quality: Good") ?? false)

        // Verify analytics
        let analyticsEvents = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.sleep.duration_tracked" && $0.metadata["action"] == "completed"
        }
        XCTAssertEqual(analyticsEvents.count, 1)
        XCTAssertEqual(analyticsEvents.first?.metadata["hasQuality"], "true")
        XCTAssertEqual(analyticsEvents.first?.metadata["quality"], "Good")

        // Verify totals updated
        XCTAssertGreaterThan(viewModel.todayTotalHours, 0)
        XCTAssertGreaterThan(viewModel.weekTotalHours, 0)

        // Verify form reset
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.selectedQuality)
        XCTAssertEqual(viewModel.notes, "")
    }

    func testSaveSleepWithoutQuality() async {
        viewModel.startSleep()
        viewModel.stopSleep()

        await viewModel.saveSleep()

        // Should still save even without quality
        let events = try? await mockRepository.events(in: nil, kind: .sleep)
        XCTAssertEqual(events?.count, 1)

        // Analytics should show no quality
        let analyticsEvents = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.sleep.duration_tracked"
        }
        XCTAssertEqual(analyticsEvents.first?.metadata["hasQuality"], "false")
        XCTAssertEqual(analyticsEvents.first?.metadata["quality"], "none")
    }

    func testSaveSleepWithNotes() async {
        viewModel.startSleep()
        viewModel.stopSleep()
        viewModel.selectedQuality = .restless
        viewModel.notes = "Woke up several times"

        await viewModel.saveSleep()

        let events = try? await mockRepository.events(in: nil, kind: .sleep)
        let notes = events?.first?.notes ?? ""
        XCTAssertTrue(notes.contains("Quality: Restless"))
        XCTAssertTrue(notes.contains("Woke up several times"))
    }

    func testSaveWithoutStoppingTimer() async {
        viewModel.startSleep()

        await viewModel.saveSleep()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.contains("stop the timer") ?? false)

        // No event should be created
        let events = try? await mockRepository.events(in: nil, kind: .sleep)
        XCTAssertEqual(events?.count, 0)
    }

    // MARK: - Totals Tests

    func testLoadTotalsWithNoEvents() async {
        await viewModel.loadTotals()

        XCTAssertEqual(viewModel.todayTotalHours, 0)
        XCTAssertEqual(viewModel.weekTotalHours, 0)
    }

    func testLoadTotalsWithEvents() async {
        // Create sleep events with 2-hour duration each
        let now = Date()
        let event1 = EventDTO(
            kind: .sleep,
            start: now.addingTimeInterval(-7200), // 2 hours ago
            end: now
        )
        let event2 = EventDTO(
            kind: .sleep,
            start: now.addingTimeInterval(-10800), // 3 hours duration
            end: now.addingTimeInterval(-3600)
        )

        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)

        await viewModel.loadTotals()

        XCTAssertEqual(viewModel.todayTotalHours, 5.0, accuracy: 0.1) // 2h + 3h
        XCTAssertEqual(viewModel.weekTotalHours, 5.0, accuracy: 0.1)
    }

    func testTotalsIgnoreOtherEventTypes() async {
        // Create mixed events
        let now = Date()
        let sleepEvent = EventDTO(
            kind: .sleep,
            start: now.addingTimeInterval(-3600),
            end: now
        )
        let diaperEvent = EventDTO(kind: .diaper, start: now)

        _ = try? await mockRepository.create(sleepEvent)
        _ = try? await mockRepository.create(diaperEvent)

        await viewModel.loadTotals()

        XCTAssertEqual(viewModel.todayTotalHours, 1.0, accuracy: 0.1) // Only sleep event
    }

    // MARK: - Form Reset Tests

    func testResetForm() {
        viewModel.startSleep()
        viewModel.selectedQuality = .good
        viewModel.notes = "Test"
        viewModel.error = "Error"

        viewModel.resetForm()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.selectedQuality)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - State Tests

    func testSleepStateEquatable() {
        let state1 = SleepState.idle
        let state2 = SleepState.idle
        XCTAssertEqual(state1, state2)

        let now = Date()
        let state3 = SleepState.active(startTime: now)
        let state4 = SleepState.active(startTime: now)
        XCTAssertEqual(state3, state4)

        let state5 = SleepState.completed(duration: 3600)
        let state6 = SleepState.completed(duration: 3600)
        XCTAssertEqual(state5, state6)
    }

    func testIsActiveProperty() {
        viewModel.state = .idle
        XCTAssertFalse(viewModel.isActive)

        viewModel.state = .active(startTime: Date())
        XCTAssertTrue(viewModel.isActive)

        viewModel.state = .completed(duration: 3600)
        XCTAssertFalse(viewModel.isActive)
    }

    // MARK: - Analytics Tests

    func testAnalyticsTracksStartStop() async {
        viewModel.startSleep()
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.sleep.started"))

        viewModel.stopSleep()
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.sleep.stopped"))
    }

    func testAnalyticsTracksDuration() async {
        viewModel.startSleep()
        try? await Task.sleep(nanoseconds: 100_000_000) // Small delay
        viewModel.stopSleep()

        await viewModel.saveSleep()

        let events = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.sleep.duration_tracked"
        }
        XCTAssertEqual(events.count, 1)
        XCTAssertNotNil(events.first?.metadata["durationMinutes"])
    }

    // MARK: - Success State Tests

    func testShowSuccessAfterSaving() async {
        viewModel.startSleep()
        viewModel.stopSleep()

        await viewModel.saveSleep()
        XCTAssertTrue(viewModel.showSuccess)
    }
}
