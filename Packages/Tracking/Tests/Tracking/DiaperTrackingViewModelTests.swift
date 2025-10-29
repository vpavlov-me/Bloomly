import AppSupport
import XCTest
@testable import Tracking

@MainActor
final class DiaperTrackingViewModelTests: XCTestCase {
    private var viewModel: DiaperTrackingViewModel!
    private var mockRepository: InMemoryEventsRepository!
    private var mockAnalytics: MockAnalytics!

    override func setUp() async throws {
        mockRepository = InMemoryEventsRepository()
        mockAnalytics = MockAnalytics()
        viewModel = DiaperTrackingViewModel(
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
        XCTAssertEqual(viewModel.selectedType, .wet)
        XCTAssertNil(viewModel.consistency)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showSuccess)
    }

    // MARK: - Log Diaper Tests

    func testLogWetDiaper() async {
        viewModel.selectedType = .wet

        await viewModel.logDiaper()

        // Verify event was created
        let events = try? await mockRepository.events(in: nil, kind: .diaper)
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?.kind, .diaper)
        XCTAssertTrue(events?.first?.notes?.contains("Wet") ?? false)

        // Verify analytics tracked
        XCTAssertTrue(mockAnalytics.wasTracked("tracking.diaper.tracked"))

        // Verify counter updated
        XCTAssertEqual(viewModel.todayCount, 1)
    }

    func testLogDirtyDiaper() async {
        viewModel.selectedType = .dirty

        await viewModel.logDiaper()

        let events = try? await mockRepository.events(in: nil, kind: .diaper)
        XCTAssertEqual(events?.count, 1)
        XCTAssertTrue(events?.first?.notes?.contains("Dirty") ?? false)
    }

    func testLogBothDiaper() async {
        viewModel.selectedType = .both

        await viewModel.logDiaper()

        let events = try? await mockRepository.events(in: nil, kind: .diaper)
        XCTAssertEqual(events?.count, 1)
        XCTAssertTrue(events?.first?.notes?.contains("Both") ?? false)
    }

    func testLogDiaperWithConsistency() async {
        viewModel.selectedType = .dirty
        viewModel.consistency = .loose

        await viewModel.logDiaper()

        let events = try? await mockRepository.events(in: nil, kind: .diaper)
        XCTAssertEqual(events?.count, 1)
        let notes = events?.first?.notes ?? ""
        XCTAssertTrue(notes.contains("Dirty"))
        XCTAssertTrue(notes.contains("Loose"))
    }

    func testLogDiaperWithNotes() async {
        viewModel.selectedType = .wet
        viewModel.notes = "First diaper of the day"

        await viewModel.logDiaper()

        let events = try? await mockRepository.events(in: nil, kind: .diaper)
        XCTAssertEqual(events?.count, 1)
        let notes = events?.first?.notes ?? ""
        XCTAssertTrue(notes.contains("Wet"))
        XCTAssertTrue(notes.contains("First diaper of the day"))
    }

    func testLogMultipleDiapersUpdatesCounter() async {
        await viewModel.logDiaper()
        XCTAssertEqual(viewModel.todayCount, 1)

        await viewModel.logDiaper()
        XCTAssertEqual(viewModel.todayCount, 2)

        await viewModel.logDiaper()
        XCTAssertEqual(viewModel.todayCount, 3)
    }

    // MARK: - Form Reset Tests

    func testFormResetsAfterLogging() async {
        viewModel.selectedType = .both
        viewModel.consistency = .normal
        viewModel.notes = "Test notes"

        await viewModel.logDiaper()

        // Form should reset to defaults
        XCTAssertEqual(viewModel.selectedType, .wet)
        XCTAssertNil(viewModel.consistency)
        XCTAssertEqual(viewModel.notes, "")
    }

    func testResetFormMethod() {
        viewModel.selectedType = .dirty
        viewModel.consistency = .hard
        viewModel.notes = "Test"
        viewModel.error = "Some error"

        viewModel.resetForm()

        XCTAssertEqual(viewModel.selectedType, .wet)
        XCTAssertNil(viewModel.consistency)
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Analytics Tests

    func testAnalyticsTracksType() async {
        viewModel.selectedType = .wet
        await viewModel.logDiaper()

        let events = mockAnalytics.trackedEvents.filter { $0.name == "tracking.diaper.tracked" }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.metadata["type"], "wet")
    }

    func testAnalyticsTracksConsistency() async {
        viewModel.selectedType = .dirty
        viewModel.consistency = .loose
        await viewModel.logDiaper()

        let events = mockAnalytics.trackedEvents.filter { $0.name == "tracking.diaper.tracked" }
        XCTAssertEqual(events.first?.metadata["hasConsistency"], "true")
    }

    // MARK: - Load Today Count Tests

    func testLoadTodayCountWithNoEvents() async {
        await viewModel.loadTodayCount()
        XCTAssertEqual(viewModel.todayCount, 0)
    }

    func testLoadTodayCountWithEvents() async {
        // Create some events
        _ = try? await mockRepository.create(EventDTO(kind: .diaper, start: Date()))
        _ = try? await mockRepository.create(EventDTO(kind: .diaper, start: Date()))

        await viewModel.loadTodayCount()
        XCTAssertEqual(viewModel.todayCount, 2)
    }

    func testLoadTodayCountIgnoresNonDiaperEvents() async {
        // Create mixed events
        _ = try? await mockRepository.create(EventDTO(kind: .diaper, start: Date()))
        _ = try? await mockRepository.create(EventDTO(kind: .sleep, start: Date()))
        _ = try? await mockRepository.create(EventDTO(kind: .feeding, start: Date()))

        await viewModel.loadTodayCount()
        XCTAssertEqual(viewModel.todayCount, 1) // Only diaper event
    }

    // MARK: - Success State Tests

    func testShowSuccessAfterLogging() async {
        await viewModel.logDiaper()
        XCTAssertTrue(viewModel.showSuccess)
    }

    // MARK: - Diaper Type Tests

    func testDiaperTypeProperties() {
        XCTAssertEqual(DiaperType.wet.symbol, "💧")
        XCTAssertEqual(DiaperType.dirty.symbol, "💩")
        XCTAssertEqual(DiaperType.both.symbol, "💧💩")

        XCTAssertEqual(DiaperType.wet.id, "Wet")
        XCTAssertEqual(DiaperType.dirty.id, "Dirty")
        XCTAssertEqual(DiaperType.both.id, "Both")
    }

    func testDiaperTypeAllCases() {
        XCTAssertEqual(DiaperType.allCases.count, 3)
        XCTAssertTrue(DiaperType.allCases.contains(.wet))
        XCTAssertTrue(DiaperType.allCases.contains(.dirty))
        XCTAssertTrue(DiaperType.allCases.contains(.both))
    }

    // MARK: - Consistency Tests

    func testConsistencyAllCases() {
        XCTAssertEqual(DiaperConsistency.allCases.count, 3)
        XCTAssertTrue(DiaperConsistency.allCases.contains(.normal))
        XCTAssertTrue(DiaperConsistency.allCases.contains(.loose))
        XCTAssertTrue(DiaperConsistency.allCases.contains(.hard))
    }
}
