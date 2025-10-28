import DesignSystem
import SwiftUI

/// Event detail/edit modal view
public struct EventDetailView: View {
    @StateObject private var viewModel: EventDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case notes
    }

    public init(viewModel: EventDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Event type header
                    eventTypeHeader

                    // Date and time section
                    dateTimeSection

                    // Duration section (if applicable)
                    if viewModel.event.duration > 0 {
                        durationSection
                    }

                    // Metadata section (if applicable)
                    if let metadata = viewModel.event.metadata, !metadata.isEmpty {
                        metadataSection(metadata: metadata)
                    }

                    // Notes section
                    notesSection

                    // Delete button (only in view mode)
                    if viewModel.mode == .view {
                        deleteButton
                    }
                }
                .padding()
            }
            .navigationTitle(viewModel.mode == .view ? "Event Details" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.mode == .view ? "Done" : "Cancel") {
                        if viewModel.mode == .view {
                            dismiss()
                        } else {
                            viewModel.cancelEdit()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if viewModel.mode == .view {
                        Button("Edit") {
                            viewModel.enterEditMode()
                        }
                    } else {
                        Button("Save") {
                            Task {
                                await viewModel.saveChanges()
                                if viewModel.error == nil {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave || viewModel.isLoading)
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Unsaved Changes", isPresented: $viewModel.showUnsavedChangesAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.discardChanges()
                }
                Button("Keep Editing", role: .cancel) {
                    viewModel.continueEditing()
                }
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
            .alert("Delete Event", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteEvent()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Event Type Header

    private var eventTypeHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.event.kind.symbol)
                .font(.system(size: 48))
                .foregroundStyle(eventColor)
                .frame(width: 80, height: 80)
                .background(eventColor.opacity(0.1))
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text(eventTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(viewModel.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Date and Time Section

    private var dateTimeSection: some View {
        VStack(spacing: 16) {
            Text("Date & Time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Start time
            HStack {
                Text("Start")
                    .foregroundStyle(.secondary)

                Spacer()

                if viewModel.mode == .edit {
                    DatePicker("", selection: Binding(
                        get: { viewModel.editedStart },
                        set: { viewModel.updateStart($0) }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                } else {
                    Text(formatDateTime(viewModel.event.start))
                        .fontWeight(.medium)
                }
            }

            Divider()

            // End time (if exists)
            if let end = viewModel.event.end {
                HStack {
                    Text("End")
                        .foregroundStyle(.secondary)

                    Spacer()

                    if viewModel.mode == .edit {
                        DatePicker("", selection: Binding(
                            get: { viewModel.editedEnd ?? end },
                            set: { viewModel.updateEnd($0) }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                    } else {
                        Text(formatDateTime(end))
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(spacing: 12) {
            Text("Duration")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)

                Text(viewModel.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Metadata Section

    private func metadataSection(metadata: [String: String]) -> some View {
        VStack(spacing: 12) {
            Text("Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(formatMetadataKey(key))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(metadata[key] ?? "")
                            .fontWeight(.medium)
                    }

                    if key != metadata.keys.sorted().last {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(spacing: 12) {
            Text("Notes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.mode == .edit {
                TextField("Add notes...", text: Binding(
                    get: { viewModel.editedNotes },
                    set: { viewModel.updateNotes($0) }
                ), axis: .vertical)
                .lineLimit(5...10)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .notes)
            } else {
                if let notes = viewModel.event.notes, !notes.isEmpty {
                    Text(notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            viewModel.confirmDelete()
        } label: {
            Text("Delete Event")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Helpers

    private var eventTitle: String {
        switch viewModel.event.kind {
        case .sleep: return "Sleep"
        case .feeding: return "Feeding"
        case .diaper: return "Diaper Change"
        case .pumping: return "Pumping"
        case .measurement: return "Measurement"
        case .medication: return "Medication"
        case .note: return "Note"
        }
    }

    private var eventColor: Color {
        switch viewModel.event.kind {
        case .sleep: return .purple
        case .feeding: return .green
        case .diaper: return .orange
        case .pumping: return .blue
        case .measurement: return .indigo
        case .medication: return .red
        case .note: return .gray
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatMetadataKey(_ key: String) -> String {
        // Convert camelCase to Title Case
        key.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
}

// MARK: - Preview

#if DEBUG
import AppSupport

#Preview("View Mode") {
    EventDetailView(
        viewModel: EventDetailViewModel(
            event: EventDTO(
                kind: .sleep,
                start: Date().addingTimeInterval(-7200),
                end: Date(),
                notes: "Good night sleep",
                metadata: ["duration": "7200"]
            ),
            repository: MockEventsRepository(),
            analytics: MockAnalytics()
        )
    )
}

#Preview("Edit Mode") {
    let vm = EventDetailViewModel(
        event: EventDTO(
            kind: .feeding,
            start: Date().addingTimeInterval(-3600),
            notes: "Breast feeding"
        ),
        repository: MockEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.enterEditMode()
    return EventDetailView(viewModel: vm)
}

#endif
