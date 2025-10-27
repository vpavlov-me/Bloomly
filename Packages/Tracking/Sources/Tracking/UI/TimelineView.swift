import DesignSystem
import SwiftUI

/// Timeline view showing event history
public struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: TimelineViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    errorView(message: error)
                } else if viewModel.eventGroups.isEmpty {
                    emptyStateView
                } else {
                    timelineList
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadTimeline()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Delete Event", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteEvent()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.eventGroups) { group in
                    Section {
                        VStack(spacing: 12) {
                            ForEach(group.events) { event in
                                EventCell(event: event, relativeTime: viewModel.relativeTime(for: event.start))
                                    .onTapGesture {
                                        hapticFeedback()
                                        viewModel.showDetails(for: event)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            hapticFeedback(.medium)
                                            viewModel.confirmDelete(event: event)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    } header: {
                        sectionHeader(title: group.title)
                    }
                }

                // Load more indicator
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Events Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your baby's events will appear here")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Error")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Event Cell

struct EventCell: View {
    let event: EventDTO
    let relativeTime: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: event.kind.symbol)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(eventTitle)
                    .font(.headline)

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Text(relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if event.duration > 0 {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(event.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var eventTitle: String {
        switch event.kind {
        case .sleep:
            return "Sleep"
        case .feeding:
            return "Feeding"
        case .diaper:
            return "Diaper Change"
        case .pumping:
            return "Pumping"
        case .measurement:
            return "Measurement"
        case .medication:
            return "Medication"
        case .note:
            return "Note"
        }
    }

    private var iconColor: Color {
        switch event.kind {
        case .sleep:
            return .purple
        case .feeding:
            return .green
        case .diaper:
            return .orange
        case .pumping:
            return .blue
        case .measurement:
            return .indigo
        case .medication:
            return .red
        case .note:
            return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
import AppSupport

#Preview("With Events") {
    TimelineView(
        viewModel: TimelineViewModel(
            repository: PreviewRepository(),
            analytics: MockAnalytics()
        )
    )
}

#Preview("Empty") {
    TimelineView(
        viewModel: TimelineViewModel(
            repository: EmptyRepository(),
            analytics: MockAnalytics()
        )
    )
}

private struct PreviewRepository: EventsRepository {
    func create(_ dto: EventDTO) async throws -> EventDTO { dto }
    func update(_ dto: EventDTO) async throws -> EventDTO { dto }
    func delete(id: UUID) async throws {}

    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        [
            EventDTO(kind: .sleep, start: Date().addingTimeInterval(-3600), end: Date(), notes: "Good night sleep"),
            EventDTO(kind: .feeding, start: Date().addingTimeInterval(-7200), notes: "Breast feeding - left side"),
            EventDTO(kind: .diaper, start: Date().addingTimeInterval(-10800), notes: "Wet diaper"),
            EventDTO(kind: .pumping, start: Date().addingTimeInterval(-86400), notes: "150ml total"),
            EventDTO(kind: .feeding, start: Date().addingTimeInterval(-90000), notes: "Bottle 120ml"),
        ]
    }

    func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        EventDTO(kind: kind, start: Date().addingTimeInterval(-3600))
    }

    func stats(for day: Date) async throws -> EventDayStats {
        .init(date: Date(), totalEvents: 5, totalDuration: 7200)
    }

    func read(id: UUID) async throws -> EventDTO {
        EventDTO(kind: .sleep, start: Date())
    }

    func upsert(_ dto: EventDTO) async throws -> EventDTO { dto }
    func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO] { dtos }
    func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO] { dtos }

    func events(for babyId: UUID, in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        []
    }

    func events(on date: Date, calendar: Calendar) async throws -> [EventDTO] { [] }
}

private struct EmptyRepository: EventsRepository {
    func create(_ dto: EventDTO) async throws -> EventDTO { dto }
    func update(_ dto: EventDTO) async throws -> EventDTO { dto }
    func delete(id: UUID) async throws {}
    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] { [] }
    func lastEvent(for kind: EventKind) async throws -> EventDTO? { nil }
    func stats(for day: Date) async throws -> EventDayStats {
        .init(date: Date(), totalEvents: 0, totalDuration: 0)
    }
    func read(id: UUID) async throws -> EventDTO {
        EventDTO(kind: .sleep, start: Date())
    }
    func upsert(_ dto: EventDTO) async throws -> EventDTO { dto }
    func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO] { dtos }
    func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO] { dtos }
    func events(for babyId: UUID, in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] { [] }
    func events(on date: Date, calendar: Calendar) async throws -> [EventDTO] { [] }
}
#endif
