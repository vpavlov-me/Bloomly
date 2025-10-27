import AppSupport
import XCTest
@testable import Tracking

@MainActor
final class FeedingTrackingViewModelTests: XCTestCase {
    private var viewModel: FeedingTrackingViewModel!
    private var mockRepository: InMemoryEventsRepository!
    private var mockAnalytics: MockAnalytics!
    private var userDefaults: UserDefaults!

    override func setUp() async throws {
        mockRepository = InMemoryEventsRepository()
        mockAnalytics = MockAnalytics()
        userDefaults = UserDefaults(suiteName: "test.feeding.tracking")!
        viewModel = FeedingTrackingViewModel(
            repository: mockRepository,
            analytics: mockAnalytics,
            userDefaults: userDefaults
        )
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "test.feeding.tracking")
        viewModel = nil
        mockRepository = nil
        mockAnalytics = nil
        userDefaults = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.selectedType, .breast)
        XCTAssertEqual(viewModel.breastState, .idle)
        XCTAssertEqual(viewModel.currentSide, .left)
        XCTAssertEqual(viewModel.leftDuration, 0)
        XCTAssertEqual(viewModel.rightDuration, 0)
        XCTAssertEqual(viewModel.bottleVolume, 0)
        XCTAssertEqual(viewModel.solidDescription, "")
        XCTAssertEqual(viewModel.solidAmount, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showSuccess)
    }

    func testInitializationWithLastBreastSide() {
        userDefaults.set("Right", forKey: "FeedingTracking.lastBreastSide")

        let vm = FeedingTrackingViewModel(
            repository: mockRepository,
            analytics: mockAnalytics,
            userDefaults: userDefaults
        )

        XCTAssertEqual(vm.currentSide, .right)
    }

    // MARK: - Type Selection Tests

    func testSelectType() {
        viewModel.selectType(.bottle)
        XCTAssertEqual(viewModel.selectedType, .bottle)

        viewModel.selectType(.solid)
        XCTAssertEqual(viewModel.selectedType, .solid)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.feeding.type_selected"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "tracking.feeding.type_selected" }
        XCTAssertEqual(events.count, 2)
    }

    func testTypeSymbols() {
        XCTAssertEqual(FeedingType.breast.symbol, "🤱")
        XCTAssertEqual(FeedingType.bottle.symbol, "🍼")
        XCTAssertEqual(FeedingType.solid.symbol, "🥄")
    }

    // MARK: - Breast Feeding Tests

    func testStartBreastFeeding() {
        viewModel.startBreastFeeding()

        XCTAssertTrue(viewModel.isBreastActive)
        XCTAssertFalse(viewModel.isBreastPaused)

        if case .active(let side, let startTime) = viewModel.breastState {
            XCTAssertEqual(side, .left)
            XCTAssertTrue(abs(startTime.timeIntervalSinceNow) < 1.0)
        } else {
            XCTFail("Breast state should be active")
        }

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.feeding.started"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "tracking.feeding.started" }
        XCTAssertEqual(events.first?.metadata["type"], "breast")
        XCTAssertEqual(events.first?.metadata["side"], "Left")
    }

    func testPauseBreastFeeding() async throws {
        viewModel.startBreastFeeding()

        // Wait a bit
        try await Task.sleep(nanoseconds: 500_000_000)

        viewModel.pauseBreastFeeding()

        XCTAssertFalse(viewModel.isBreastActive)
        XCTAssertTrue(viewModel.isBreastPaused)

        if case .paused(let side, let elapsed) = viewModel.breastState {
            XCTAssertEqual(side, .left)
            XCTAssertGreaterThan(elapsed, 0)
        } else {
            XCTFail("Breast state should be paused")
        }

        // Left duration should be updated
        XCTAssertGreaterThan(viewModel.leftDuration, 0)
    }

    func testResumeBreastFeeding() async throws {
        viewModel.startBreastFeeding()
        try await Task.sleep(nanoseconds: 500_000_000)
        viewModel.pauseBreastFeeding()

        viewModel.resumeBreastFeeding()

        XCTAssertTrue(viewModel.isBreastActive)
        XCTAssertFalse(viewModel.isBreastPaused)
    }

    func testSwitchBreastSide() async throws {
        viewModel.startBreastFeeding()
        XCTAssertEqual(viewModel.currentSide, .left)

        // Wait a bit
        try await Task.sleep(nanoseconds: 500_000_000)

        let leftDurationBefore = viewModel.leftDuration
        viewModel.switchBreastSide()

        // Side should switch
        XCTAssertEqual(viewModel.currentSide, .right)

        // Left duration should be updated
        XCTAssertGreaterThan(viewModel.leftDuration, leftDurationBefore)

        // Should still be active
        XCTAssertTrue(viewModel.isBreastActive)

        if case .active(let side, _) = viewModel.breastState {
            XCTAssertEqual(side, .right)
        } else {
            XCTFail("Breast state should be active")
        }
    }

    func testStopBreastFeeding() async throws {
        viewModel.startBreastFeeding()
        try await Task.sleep(nanoseconds: 500_000_000)

        viewModel.stopBreastFeeding()

        XCTAssertFalse(viewModel.isBreastActive)
        XCTAssertFalse(viewModel.isBreastPaused)

        if case .completed(let left, let right) = viewModel.breastState {
            XCTAssertGreaterThan(left, 0)
            XCTAssertEqual(right, 0) // Only left side was used
        } else {
            XCTFail("Breast state should be completed")
        }

        // Last side should be saved (opposite of longer duration)
        let savedSide = userDefaults.string(forKey: "FeedingTracking.lastBreastSide")
        XCTAssertEqual(savedSide, "Right") // Opposite of left
    }

    func testBreastSideProperties() {
        XCTAssertEqual(BreastSide.left.symbol, "L")
        XCTAssertEqual(BreastSide.right.symbol, "R")
        XCTAssertEqual(BreastSide.left.opposite, .right)
        XCTAssertEqual(BreastSide.right.opposite, .left)
    }

    func testElapsedTimeUpdates() async throws {
        viewModel.startBreastFeeding()

        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        XCTAssertGreaterThan(viewModel.elapsedTime, 1.0)
        XCTAssertLessThan(viewModel.elapsedTime, 2.0)
    }

    func testTotalBreastDuration() async throws {
        viewModel.startBreastFeeding()
        try await Task.sleep(nanoseconds: 500_000_000)
        viewModel.switchBreastSide()
        try await Task.sleep(nanoseconds: 500_000_000)
        viewModel.stopBreastFeeding()

        let total = viewModel.totalBreastDuration
        XCTAssertGreaterThan(total, 1.0)
        XCTAssertEqual(total, viewModel.leftDuration + viewModel.rightDuration, accuracy: 0.1)
    }

    // MARK: - Bottle Feeding Tests

    func testSetBottleVolume() {
        viewModel.setBottleVolume(120)
        XCTAssertEqual(viewModel.bottleVolume, 120)

        viewModel.setBottleVolume(180)
        XCTAssertEqual(viewModel.bottleVolume, 180)
    }

    func testAdjustBottleVolume() {
        viewModel.setBottleVolume(100)

        viewModel.adjustBottleVolume(by: 10)
        XCTAssertEqual(viewModel.bottleVolume, 110)

        viewModel.adjustBottleVolume(by: -20)
        XCTAssertEqual(viewModel.bottleVolume, 90)

        // Should not go below zero
        viewModel.adjustBottleVolume(by: -100)
        XCTAssertEqual(viewModel.bottleVolume, 0)
    }

    func testBottleVolumePresets() {
        XCTAssertEqual(viewModel.bottleVolumePresets, [60, 90, 120, 150, 180])
    }

    // MARK: - Solid Feeding Tests

    func testSolidDescription() {
        viewModel.solidDescription = "Apple sauce"
        XCTAssertEqual(viewModel.solidDescription, "Apple sauce")

        viewModel.solidAmount = "1 jar"
        XCTAssertEqual(viewModel.solidAmount, "1 jar")
    }

    // MARK: - Save Tests

    func testSaveBreastFeeding() async throws {
        viewModel.startBreastFeeding()
        try await Task.sleep(nanoseconds: 500_000_000)
        viewModel.stopBreastFeeding()

        await viewModel.saveFeeding()

        // Verify event was created
        let events = try await mockRepository.events(in: nil, kind: .feeding)
        XCTAssertEqual(events.count, 1)

        let event = events.first
        XCTAssertEqual(event?.kind, .feeding)
        XCTAssertNotNil(event?.metadata?["leftDuration"])
        XCTAssertNotNil(event?.metadata?["totalDuration"])

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.feeding.completed"))
        let analyticsEvents = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.feeding.completed"
        }
        XCTAssertEqual(analyticsEvents.first?.metadata["type"], "breast")

        // Verify form reset
        XCTAssertEqual(viewModel.breastState, .idle)
        XCTAssertEqual(viewModel.leftDuration, 0)
        XCTAssertEqual(viewModel.rightDuration, 0)
    }

    func testSaveBottleFeeding() async throws {
        viewModel.selectType(.bottle)
        viewModel.setBottleVolume(120)

        await viewModel.saveFeeding()

        let events = try await mockRepository.events(in: nil, kind: .feeding)
        XCTAssertEqual(events.count, 1)

        let event = events.first
        XCTAssertEqual(event?.metadata?["volume"], "120")
        XCTAssertTrue(event?.notes?.contains("120 ml") ?? false)

        // Verify analytics
        let analyticsEvents = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.feeding.completed"
        }
        XCTAssertEqual(analyticsEvents.first?.metadata["type"], "bottle")
    }

    func testSaveSolidFeeding() async throws {
        viewModel.selectType(.solid)
        viewModel.solidDescription = "Mashed banana"
        viewModel.solidAmount = "3 spoons"

        await viewModel.saveFeeding()

        let events = try await mockRepository.events(in: nil, kind: .feeding)
        XCTAssertEqual(events.count, 1)

        let event = events.first
        XCTAssertEqual(event?.metadata?["description"], "Mashed banana")
        XCTAssertEqual(event?.metadata?["amount"], "3 spoons")

        // Verify analytics
        let analyticsEvents = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.feeding.completed"
        }
        XCTAssertEqual(analyticsEvents.first?.metadata["type"], "solid")
    }

    func testSaveWithNotes() async throws {
        viewModel.selectType(.bottle)
        viewModel.setBottleVolume(90)
        viewModel.notes = "Baby was very hungry"

        await viewModel.saveFeeding()

        let events = try await mockRepository.events(in: nil, kind: .feeding)
        let notes = events.first?.notes ?? ""
        XCTAssertTrue(notes.contains("90 ml"))
        XCTAssertTrue(notes.contains("Baby was very hungry"))
    }

    func testCannotSaveWithoutData() async {
        // Breast without duration
        viewModel.selectType(.breast)
        XCTAssertFalse(viewModel.canSave)

        // Bottle without volume
        viewModel.selectType(.bottle)
        XCTAssertFalse(viewModel.canSave)

        // Solid without description
        viewModel.selectType(.solid)
        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSaveWithValidData() async throws {
        // Breast with duration
        viewModel.selectType(.breast)
        viewModel.startBreastFeeding()
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.stopBreastFeeding()
        XCTAssertTrue(viewModel.canSave)

        // Reset
        viewModel.resetForm()

        // Bottle with volume
        viewModel.selectType(.bottle)
        viewModel.setBottleVolume(120)
        XCTAssertTrue(viewModel.canSave)

        // Reset
        viewModel.resetForm()

        // Solid with description
        viewModel.selectType(.solid)
        viewModel.solidDescription = "Banana"
        XCTAssertTrue(viewModel.canSave)
    }

    // MARK: - Format Tests

    func testFormatDuration() {
        viewModel.leftDuration = 0
        XCTAssertEqual(viewModel.formattedLeftDuration, "0:00")

        viewModel.leftDuration = 65 // 1:05
        XCTAssertEqual(viewModel.formattedLeftDuration, "1:05")

        viewModel.leftDuration = 600 // 10:00
        XCTAssertEqual(viewModel.formattedLeftDuration, "10:00")

        viewModel.rightDuration = 125 // 2:05
        XCTAssertEqual(viewModel.formattedRightDuration, "2:05")
    }

    // MARK: - Reset Tests

    func testResetForm() async throws {
        viewModel.selectType(.bottle)
        viewModel.setBottleVolume(120)
        viewModel.notes = "Test"
        viewModel.error = "Error"

        viewModel.resetForm()

        XCTAssertEqual(viewModel.breastState, .idle)
        XCTAssertEqual(viewModel.leftDuration, 0)
        XCTAssertEqual(viewModel.rightDuration, 0)
        XCTAssertEqual(viewModel.bottleVolume, 0)
        XCTAssertEqual(viewModel.solidDescription, "")
        XCTAssertEqual(viewModel.solidAmount, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - State Tests

    func testBreastFeedingStateEquatable() {
        let state1 = BreastFeedingState.idle
        let state2 = BreastFeedingState.idle
        XCTAssertEqual(state1, state2)

        let now = Date()
        let state3 = BreastFeedingState.active(side: .left, startTime: now)
        let state4 = BreastFeedingState.active(side: .left, startTime: now)
        XCTAssertEqual(state3, state4)

        let state5 = BreastFeedingState.paused(side: .right, elapsedTime: 60)
        let state6 = BreastFeedingState.paused(side: .right, elapsedTime: 60)
        XCTAssertEqual(state5, state6)

        let state7 = BreastFeedingState.completed(leftDuration: 120, rightDuration: 180)
        let state8 = BreastFeedingState.completed(leftDuration: 120, rightDuration: 180)
        XCTAssertEqual(state7, state8)
    }

    // MARK: - Analytics Tests

    func testAnalyticsTracksTypeSelection() {
        viewModel.selectType(.bottle)
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.feeding.type_selected"))

        let events = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.feeding.type_selected"
        }
        XCTAssertEqual(events.first?.metadata["type"], "bottle")
    }

    func testAnalyticsTracksBreastStart() {
        viewModel.startBreastFeeding()
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.feeding.started"))

        let events = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.feeding.started"
        }
        XCTAssertEqual(events.first?.metadata["type"], "breast")
        XCTAssertNotNil(events.first?.metadata["side"])
    }

    func testAnalyticsTracksCompletion() async {
        viewModel.selectType(.bottle)
        viewModel.setBottleVolume(120)

        await viewModel.saveFeeding()

        XCTAssertTrue(mockAnalytics.wasTracked("tracking.feeding.completed"))

        let events = mockAnalytics.trackedEvents.filter {
            $0.name == "tracking.feeding.completed"
        }
        XCTAssertEqual(events.first?.metadata["type"], "bottle")
        XCTAssertEqual(events.first?.metadata["volume"], "120")
    }

    // MARK: - Success State Tests

    func testShowSuccessAfterSaving() async {
        viewModel.selectType(.bottle)
        viewModel.setBottleVolume(90)

        await viewModel.saveFeeding()
        XCTAssertTrue(viewModel.showSuccess)
    }

    // MARK: - Integration Tests

    func testCompleteBreastFeedingSession() async throws {
        // Start feeding on left
        viewModel.startBreastFeeding()
        XCTAssertEqual(viewModel.currentSide, .left)

        // Feed for a bit
        try await Task.sleep(nanoseconds: 500_000_000)

        // Switch to right
        viewModel.switchBreastSide()
        XCTAssertEqual(viewModel.currentSide, .right)
        XCTAssertGreaterThan(viewModel.leftDuration, 0)

        // Feed on right
        try await Task.sleep(nanoseconds: 500_000_000)

        // Stop feeding
        viewModel.stopBreastFeeding()
        XCTAssertGreaterThan(viewModel.rightDuration, 0)

        // Save
        await viewModel.saveFeeding()

        // Verify event
        let events = try await mockRepository.events(in: nil, kind: .feeding)
        XCTAssertEqual(events.count, 1)

        let event = events.first
        XCTAssertNotNil(event?.metadata?["leftDuration"])
        XCTAssertNotNil(event?.metadata?["rightDuration"])
        XCTAssertNotNil(event?.metadata?["totalDuration"])

        // Verify form reset
        XCTAssertEqual(viewModel.breastState, .idle)
        XCTAssertEqual(viewModel.leftDuration, 0)
        XCTAssertEqual(viewModel.rightDuration, 0)
    }
}
