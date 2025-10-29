import AppSupport
import Foundation
import os.log

/// View mode for event detail
public enum EventDetailMode: Equatable {
    case view
    case edit
}

/// ViewModel for event detail/edit modal
@MainActor
public final class EventDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var mode: EventDetailMode = .view
    @Published public var event: EventDTO
    @Published public var editedNotes: String
    @Published public var editedStart: Date
    @Published public var editedEnd: Date?
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    @Published public var showDeleteConfirmation: Bool = false
    @Published public var hasUnsavedChanges: Bool = false
    @Published public var showUnsavedChangesAlert: Bool = false

    // MARK: - Dependencies

    private let repository: EventsRepository
    private let analytics: Analytics
    private let logger = Logger(subsystem: "com.example.babytrack", category: "EventDetail")
    private let onDelete: (() -> Void)?
    private let onSave: (() -> Void)?

    // MARK: - Computed Properties

    public var canSave: Bool {
        guard mode == .edit else { return false }

        // Validate that end is after start
        if let end = editedEnd, end <= editedStart {
            return false
        }

        return hasUnsavedChanges
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: event.start)
    }

    public var formattedDuration: String {
        event.formattedDuration
    }

    // MARK: - Initialization

    public init(
        event: EventDTO,
        repository: EventsRepository,
        analytics: Analytics,
        onDelete: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil
    ) {
        self.event = event
        self.editedNotes = event.notes ?? ""
        self.editedStart = event.start
        self.editedEnd = event.end
        self.repository = repository
        self.analytics = analytics
        self.onDelete = onDelete
        self.onSave = onSave
    }

    // MARK: - Mode Actions

    /// Switch to edit mode
    public func enterEditMode() {
        logger.debug("Entering edit mode")
        mode = .edit

        analytics.track(AnalyticsEvent(
            type: .eventUpdated,
            metadata: ["action": "editStarted", "kind": event.kind.rawValue]
        ))
    }

    /// Cancel edit mode
    public func cancelEdit() {
        if hasUnsavedChanges {
            logger.debug("Has unsaved changes, showing alert")
            showUnsavedChangesAlert = true
        } else {
            logger.debug("No changes, cancelling edit")
            discardChanges()
        }
    }

    /// Discard changes and return to view mode
    public func discardChanges() {
        logger.debug("Discarding changes")
        editedNotes = event.notes ?? ""
        editedStart = event.start
        editedEnd = event.end
        mode = .view
        hasUnsavedChanges = false
        showUnsavedChangesAlert = false
    }

    /// Continue editing despite unsaved changes warning
    public func continueEditing() {
        showUnsavedChangesAlert = false
    }

    // MARK: - Save Action

    /// Save changes to event
    public func saveChanges() async {
        guard canSave else {
            error = "Please fix validation errors"
            return
        }

        logger.info("Saving event changes: \(self.event.id)")

        isLoading = true
        error = nil

        do {
            // Create updated event
            var updatedEvent = event
            updatedEvent.notes = editedNotes.isEmpty ? nil : editedNotes
            updatedEvent.start = editedStart
            updatedEvent.end = editedEnd

            // Update via repository
            let savedEvent = try await repository.update(updatedEvent)

            // Update local state
            event = savedEvent
            hasUnsavedChanges = false
            mode = .view

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .eventUpdated,
                metadata: ["kind": event.kind.rawValue]
            ))

            logger.info("Event saved successfully")

            // Notify parent
            onSave?()

            isLoading = false

        } catch {
            logger.error("Failed to save event: \(error.localizedDescription)")
            self.error = "Failed to save changes. Please try again."
            isLoading = false
        }
    }

    // MARK: - Delete Action

    /// Show delete confirmation
    public func confirmDelete() {
        logger.debug("Showing delete confirmation")
        showDeleteConfirmation = true
    }

    /// Cancel delete
    public func cancelDelete() {
        showDeleteConfirmation = false
    }

    /// Delete event
    public func deleteEvent() async {
        logger.info("Deleting event: \(self.event.id)")

        isLoading = true

        do {
            try await repository.delete(id: event.id)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .eventDeleted,
                metadata: ["kind": event.kind.rawValue]
            ))

            logger.info("Event deleted successfully")

            // Notify parent
            onDelete?()

        } catch {
            logger.error("Failed to delete event: \(error.localizedDescription)")
            self.error = "Failed to delete event. Please try again."
            isLoading = false
        }
    }

    // MARK: - Field Updates

    /// Update notes and track changes
    public func updateNotes(_ notes: String) {
        editedNotes = notes
        checkForChanges()
    }

    /// Update start date and track changes
    public func updateStart(_ date: Date) {
        editedStart = date
        checkForChanges()
    }

    /// Update end date and track changes
    public func updateEnd(_ date: Date?) {
        editedEnd = date
        checkForChanges()
    }

    // MARK: - Private Helpers

    private func checkForChanges() {
        hasUnsavedChanges =
            editedNotes != (event.notes ?? "") ||
            editedStart != event.start ||
            editedEnd != event.end
    }
}
