import AppSupport
import XCTest
@testable import Tracking

@MainActor
final class EventDetailViewModelTests: XCTestCase {
    private var viewModel: EventDetailViewModel!
    private var mockRepository: InMemoryEventsRepository!
    private var mockAnalytics: MockAnalytics!
    private var testEvent: EventDTO!

    override func setUp() async throws {
        mockRepository = InMemoryEventsRepository()
        mockAnalytics = MockAnalytics()
        testEvent = EventDTO(
            kind: .sleep,
            start: Date().addingTimeInterval(-3600),
            end: Date(),
            notes: "Test sleep"
        )
        viewModel = EventDetailViewModel(
            event: testEvent,
            repository: mockRepository,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockAnalytics = nil
        testEvent = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.mode, .view)
        XCTAssertEqual(viewModel.event, testEvent)
        XCTAssertEqual(viewModel.editedNotes, "Test sleep")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showDeleteConfirmation)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertFalse(viewModel.showUnsavedChangesAlert)
    }

    // MARK: - Mode Tests

    func testEnterEditMode() {
        viewModel.enterEditMode()

        XCTAssertEqual(viewModel.mode, .edit)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("event.edit.started"))
    }

    func testCancelEditWithoutChanges() {
        viewModel.enterEditMode()
        viewModel.cancelEdit()

        XCTAssertEqual(viewModel.mode, .view)
        XCTAssertFalse(viewModel.showUnsavedChangesAlert)
    }

    func testCancelEditWithChanges() {
        viewModel.enterEditMode()
        viewModel.updateNotes("Changed notes")

        XCTAssertTrue(viewModel.hasUnsavedChanges)

        viewModel.cancelEdit()

        XCTAssertTrue(viewModel.showUnsavedChangesAlert)
    }

    func testDiscardChanges() {
        viewModel.enterEditMode()
        viewModel.updateNotes("Changed notes")

        XCTAssertTrue(viewModel.hasUnsavedChanges)

        viewModel.discardChanges()

        XCTAssertEqual(viewModel.mode, .view)
        XCTAssertEqual(viewModel.editedNotes, "Test sleep")
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertFalse(viewModel.showUnsavedChangesAlert)
    }

    func testContinueEditing() {
        viewModel.showUnsavedChangesAlert = true

        viewModel.continueEditing()

        XCTAssertFalse(viewModel.showUnsavedChangesAlert)
    }

    // MARK: - Field Update Tests

    func testUpdateNotes() {
        viewModel.enterEditMode()

        viewModel.updateNotes("New notes")

        XCTAssertEqual(viewModel.editedNotes, "New notes")
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateStart() {
        viewModel.enterEditMode()

        let newStart = Date().addingTimeInterval(-7200)
        viewModel.updateStart(newStart)

        XCTAssertEqual(viewModel.editedStart, newStart)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testUpdateEnd() {
        viewModel.enterEditMode()

        let newEnd = Date().addingTimeInterval(-1800)
        viewModel.updateEnd(newEnd)

        XCTAssertEqual(viewModel.editedEnd, newEnd)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testHasUnsavedChangesTracking() {
        viewModel.enterEditMode()

        XCTAssertFalse(viewModel.hasUnsavedChanges)

        viewModel.updateNotes("Changed")
        XCTAssertTrue(viewModel.hasUnsavedChanges)

        viewModel.updateNotes("Test sleep") // back to original
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }

    // MARK: - Save Tests

    func testSaveChangesSuccess() async {
        // Create event in repository
        _ = try? await mockRepository.create(testEvent)

        viewModel.enterEditMode()
        viewModel.updateNotes("Updated notes")

        await viewModel.saveChanges()

        XCTAssertEqual(viewModel.mode, .view)
        XCTAssertEqual(viewModel.event.notes, "Updated notes")
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertNil(viewModel.error)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("event.edited"))
    }

    func testCannotSaveInViewMode() {
        XCTAssertFalse(viewModel.canSave)
    }

    func testCannotSaveWithoutChanges() {
        viewModel.enterEditMode()
        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSaveWithChanges() {
        viewModel.enterEditMode()
        viewModel.updateNotes("Changed")

        XCTAssertTrue(viewModel.canSave)
    }

    func testCannotSaveWithInvalidDates() {
        viewModel.enterEditMode()
        viewModel.updateStart(Date())
        viewModel.updateEnd(Date().addingTimeInterval(-3600)) // end before start

        XCTAssertFalse(viewModel.canSave)
    }

    // MARK: - Delete Tests

    func testConfirmDelete() {
        viewModel.confirmDelete()

        XCTAssertTrue(viewModel.showDeleteConfirmation)
    }

    func testCancelDelete() {
        viewModel.confirmDelete()
        viewModel.cancelDelete()

        XCTAssertFalse(viewModel.showDeleteConfirmation)
    }

    func testDeleteEvent() async {
        // Create event in repository
        _ = try? await mockRepository.create(testEvent)

        var deleteCalled = false
        let vmWithCallback = EventDetailViewModel(
            event: testEvent,
            repository: mockRepository,
            analytics: mockAnalytics,
            onDelete: { deleteCalled = true }
        )

        await vmWithCallback.deleteEvent()

        XCTAssertTrue(deleteCalled)

        // Verify analytics
        XCTAssertTrue(mockAnalytics.wasTracked("event.deleted"))
    }

    // MARK: - Formatted Output Tests

    func testFormattedDate() {
        let formatted = viewModel.formattedDate
        XCTAssertFalse(formatted.isEmpty)
    }

    func testFormattedDuration() {
        let formatted = viewModel.formattedDuration
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Mode Equatable Tests

    func testEventDetailModeEquatable() {
        XCTAssertEqual(EventDetailMode.view, EventDetailMode.view)
        XCTAssertEqual(EventDetailMode.edit, EventDetailMode.edit)
        XCTAssertNotEqual(EventDetailMode.view, EventDetailMode.edit)
    }

    // MARK: - Callback Tests

    func testOnSaveCallback() async {
        var saveCalled = false
        let vmWithCallback = EventDetailViewModel(
            event: testEvent,
            repository: mockRepository,
            analytics: mockAnalytics,
            onSave: { saveCalled = true }
        )

        _ = try? await mockRepository.create(testEvent)

        vmWithCallback.enterEditMode()
        vmWithCallback.updateNotes("Changed")

        await vmWithCallback.saveChanges()

        XCTAssertTrue(saveCalled)
    }

    func testOnDeleteCallback() async {
        var deleteCalled = false
        let vmWithCallback = EventDetailViewModel(
            event: testEvent,
            repository: mockRepository,
            analytics: mockAnalytics,
            onDelete: { deleteCalled = true }
        )

        _ = try? await mockRepository.create(testEvent)

        await vmWithCallback.deleteEvent()

        XCTAssertTrue(deleteCalled)
    }

    // MARK: - Analytics Tests

    func testAnalyticsTracksEditStart() {
        viewModel.enterEditMode()

        XCTAssertTrue(mockAnalytics.wasTracked("event.edit.started"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "event.edit.started" }
        XCTAssertEqual(events.first?.metadata["kind"], "sleep")
    }

    func testAnalyticsTracksSave() async {
        _ = try? await mockRepository.create(testEvent)

        viewModel.enterEditMode()
        viewModel.updateNotes("Changed")

        await viewModel.saveChanges()

        XCTAssertTrue(mockAnalytics.wasTracked("event.edited"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "event.edited" }
        XCTAssertEqual(events.first?.metadata["kind"], "sleep")
    }

    func testAnalyticsTracksDelete() async {
        _ = try? await mockRepository.create(testEvent)

        await viewModel.deleteEvent()

        XCTAssertTrue(mockAnalytics.wasTracked("event.deleted"))
        let events = mockAnalytics.trackedEvents.filter { $0.name == "event.deleted" }
        XCTAssertEqual(events.first?.metadata["kind"], "sleep")
    }

    // MARK: - Edge Cases

    func testEmptyNotesHandling() {
        viewModel.enterEditMode()
        viewModel.updateNotes("")

        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testNilEndDateHandling() {
        let eventWithoutEnd = EventDTO(
            kind: .feeding,
            start: Date(),
            end: nil,
            notes: "Ongoing feeding"
        )

        let vm = EventDetailViewModel(
            event: eventWithoutEnd,
            repository: mockRepository,
            analytics: mockAnalytics
        )

        XCTAssertNil(vm.editedEnd)
    }
}
