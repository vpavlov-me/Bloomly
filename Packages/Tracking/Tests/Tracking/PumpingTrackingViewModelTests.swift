import AppSupport
import XCTest
@testable import Tracking

@MainActor
final class PumpingTrackingViewModelTests: XCTestCase {
    private var viewModel: PumpingTrackingViewModel!
    private var mockRepository: InMemoryEventsRepository!
    private var mockAnalytics: MockAnalytics!

    override func setUp() async throws {
        mockRepository = InMemoryEventsRepository()
        mockAnalytics = MockAnalytics()
        viewModel = PumpingTrackingViewModel(
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
        XCTAssertEqual(viewModel.leftBreastVolume, 0)
        XCTAssertEqual(viewModel.rightBreastVolume, 0)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showSuccess)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(viewModel.isActive)
    }

    // MARK: - Timer Tests

    func testStartPumping() {
        viewModel.startPumping()

        XCTAssertTrue(viewModel.isActive)
        if case .active(let startTime) = viewModel.state {
            XCTAssertTrue(abs(startTime.timeIntervalSinceNow) < 1.0)
        } else {
            XCTFail("State should be active")
        }

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.pumping.tracked"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "tracking.pumping.tracked" }
        XCTAssertEqual(events.first?.metadata["action"], "started")
    }

    func testStopPumping() {
        viewModel.startPumping()
        viewModel.stopPumping()

        if case .completed(let duration) = viewModel.state {
            XCTAssertGreaterThan(duration, 0)
        } else {
            XCTFail("State should be completed")
        }

        XCTAssertFalse(viewModel.isActive)

        // Verify analytics
        let events = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.pumping.tracked" && $0.metadata["action"] == "stopped"
        }
        XCTAssertEqual(events.count, 1)
    }

    func testCancelSession() {
        viewModel.startPumping()
        viewModel.leftBreastVolume = 100
        viewModel.rightBreastVolume = 90

        viewModel.cancelSession()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.leftBreastVolume, 0)
        XCTAssertEqual(viewModel.rightBreastVolume, 0)
    }

    func testElapsedTimeUpdates() async throws {
        viewModel.startPumping()

        // Wait a bit for timer to tick
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        XCTAssertGreaterThan(viewModel.elapsedTime, 1.0)
        XCTAssertLessThan(viewModel.elapsedTime, 2.0)
    }

    func testFormattedElapsedTime() {
        viewModel.elapsedTime = 0
        XCTAssertEqual(viewModel.formattedElapsedTime, "00:00")

        viewModel.elapsedTime = 65
        XCTAssertEqual(viewModel.formattedElapsedTime, "01:05")

        viewModel.elapsedTime = 600
        XCTAssertEqual(viewModel.formattedElapsedTime, "10:00")
    }

    // MARK: - Volume Tests

    func testSetLeftVolume() {
        viewModel.setLeftVolume(100)
        XCTAssertEqual(viewModel.leftBreastVolume, 100)

        // Negative values should be clamped to 0
        viewModel.setLeftVolume(-50)
        XCTAssertEqual(viewModel.leftBreastVolume, 0)
    }

    func testSetRightVolume() {
        viewModel.setRightVolume(80)
        XCTAssertEqual(viewModel.rightBreastVolume, 80)

        // Negative values should be clamped to 0
        viewModel.setRightVolume(-30)
        XCTAssertEqual(viewModel.rightBreastVolume, 0)
    }

    func testApplyLeftPreset() {
        viewModel.applyLeftPreset(60)
        XCTAssertEqual(viewModel.leftBreastVolume, 60)
    }

    func testApplyRightPreset() {
        viewModel.applyRightPreset(90)
        XCTAssertEqual(viewModel.rightBreastVolume, 90)
    }

    func testTotalVolume() {
        viewModel.leftBreastVolume = 100
        viewModel.rightBreastVolume = 80

        XCTAssertEqual(viewModel.totalVolume, 180)
    }

    func testVolumePresets() {
        XCTAssertEqual(PumpingTrackingViewModel.volumePresets, [30, 60, 90, 120])
    }

    // MARK: - Save Tests

    func testSavePumpingSuccess() async {
        viewModel.startPumping()
        viewModel.stopPumping()
        viewModel.leftBreastVolume = 100
        viewModel.rightBreastVolume = 80

        await viewModel.savePumping()

        // Verify event was created
        let events = try? await mockRepository.events(in: nil, kind: .pumping)
        XCTAssertEqual(events?.count, 1)

        let event = events?.first
        XCTAssertEqual(event?.kind, .pumping)
        XCTAssertTrue(event?.notes?.contains("Left: 100ml") ?? false)
        XCTAssertTrue(event?.notes?.contains("Right: 80ml") ?? false)
        XCTAssertTrue(event?.notes?.contains("Total: 180ml") ?? false)

        // Verify analytics
        let analyticsEvents = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.pumping.tracked" && $0.metadata["action"] == "completed"
        }
        XCTAssertEqual(analyticsEvents.count, 1)
        XCTAssertEqual(analyticsEvents.first?.metadata["totalVolume"], "180")
        XCTAssertEqual(analyticsEvents.first?.metadata["leftVolume"], "100")
        XCTAssertEqual(analyticsEvents.first?.metadata["rightVolume"], "80")

        // Verify totals updated
        XCTAssertEqual(viewModel.todayTotal, 180)
        XCTAssertEqual(viewModel.weekTotal, 180)

        // Verify form reset
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.leftBreastVolume, 0)
        XCTAssertEqual(viewModel.rightBreastVolume, 0)
    }

    func testSavePumpingWithNotes() async {
        viewModel.startPumping()
        viewModel.stopPumping()
        viewModel.leftBreastVolume = 50
        viewModel.rightBreastVolume = 50
        viewModel.notes = "Morning session"

        await viewModel.savePumping()

        let events = try? await mockRepository.events(in: nil, kind: .pumping)
        XCTAssertTrue(events?.first?.notes?.contains("Morning session") ?? false)
    }

    func testSaveWithoutStoppingTimer() async {
        viewModel.startPumping()
        viewModel.leftBreastVolume = 100

        await viewModel.savePumping()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.contains("stop the timer") ?? false)

        // No event should be created
        let events = try? await mockRepository.events(in: nil, kind: .pumping)
        XCTAssertEqual(events?.count, 0)
    }

    func testSaveWithoutVolume() async {
        viewModel.startPumping()
        viewModel.stopPumping()

        await viewModel.savePumping()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.contains("enter volume") ?? false)

        // No event should be created
        let events = try? await mockRepository.events(in: nil, kind: .pumping)
        XCTAssertEqual(events?.count, 0)
    }

    // MARK: - Totals Tests

    func testLoadTotalsWithNoEvents() async {
        await viewModel.loadTotals()

        XCTAssertEqual(viewModel.todayTotal, 0)
        XCTAssertEqual(viewModel.weekTotal, 0)
    }

    func testLoadTotalsWithEvents() async {
        // Create pumping events
        let event1 = EventDTO(
            kind: .pumping,
            start: Date(),
            notes: "Left: 50ml • Right: 50ml • Total: 100ml"
        )
        let event2 = EventDTO(
            kind: .pumping,
            start: Date(),
            notes: "Left: 60ml • Right: 40ml • Total: 100ml"
        )

        _ = try? await mockRepository.create(event1)
        _ = try? await mockRepository.create(event2)

        await viewModel.loadTotals()

        XCTAssertEqual(viewModel.todayTotal, 200)
        XCTAssertEqual(viewModel.weekTotal, 200)
    }

    func testTotalsIgnoreOtherEventTypes() async {
        // Create mixed events
        let pumpingEvent = EventDTO(
            kind: .pumping,
            start: Date(),
            notes: "Total: 100ml"
        )
        let sleepEvent = EventDTO(kind: .sleep, start: Date())

        _ = try? await mockRepository.create(pumpingEvent)
        _ = try? await mockRepository.create(sleepEvent)

        await viewModel.loadTotals()

        XCTAssertEqual(viewModel.todayTotal, 100)
    }

    // MARK: - Form Reset Tests

    func testResetForm() {
        viewModel.startPumping()
        viewModel.leftBreastVolume = 100
        viewModel.rightBreastVolume = 80
        viewModel.notes = "Test"
        viewModel.error = "Error"

        viewModel.resetForm()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.leftBreastVolume, 0)
        XCTAssertEqual(viewModel.rightBreastVolume, 0)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - State Tests

    func testPumpingStateEquatable() {
        let state1 = PumpingState.idle
        let state2 = PumpingState.idle
        XCTAssertEqual(state1, state2)

        let now = Date()
        let state3 = PumpingState.active(startTime: now)
        let state4 = PumpingState.active(startTime: now)
        XCTAssertEqual(state3, state4)

        let state5 = PumpingState.completed(duration: 100)
        let state6 = PumpingState.completed(duration: 100)
        XCTAssertEqual(state5, state6)
    }

    func testIsActiveProperty() {
        viewModel.state = .idle
        XCTAssertFalse(viewModel.isActive)

        viewModel.state = .active(startTime: Date())
        XCTAssertTrue(viewModel.isActive)

        viewModel.state = .completed(duration: 100)
        XCTAssertFalse(viewModel.isActive)
    }
}
