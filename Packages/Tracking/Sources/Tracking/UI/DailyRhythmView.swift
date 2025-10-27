import DesignSystem
import SwiftUI

/// 24-hour timeline visualization of baby's daily routine.
///
/// Features:
/// - Horizontal scrollable timeline (0-24 hours)
/// - Color-coded event blocks (sleep=blue, feed=pink, diaper=yellow)
/// - Event blocks proportional to duration
/// - Date selector to view different days
/// - Tap event for details
/// - Handles overlapping events
public struct DailyRhythmView: View {
    @StateObject private var viewModel: ViewModel
    private let eventsRepository: any EventsRepository

    private let hourWidth: CGFloat = 60 // Width per hour
    private let trackHeight: CGFloat = 80

    public init(viewModel: ChartsViewModel) {
        self.eventsRepository = viewModel.aggregator.eventsRepository
        _viewModel = StateObject(wrappedValue: ViewModel(selectedDate: Date()))
    }

    public var body: some View {
        VStack(spacing: BabyTrackTheme.spacing.md) {
            // Date selector
            dateSelector

            // Timeline
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if viewModel.events.isEmpty {
                emptyStateView
            } else {
                timelineView
            }
        }
        .padding(.vertical, BabyTrackTheme.spacing.lg)
        .background(BabyTrackTheme.palette.background.ignoresSafeArea())
        .task {
            await viewModel.loadEvents(repository: eventsRepository)
        }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        VStack(spacing: BabyTrackTheme.spacing.sm) {
            HStack {
                Button {
                    viewModel.selectPreviousDay()
                    Task {
                        await viewModel.loadEvents(repository: eventsRepository)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(BabyTrackTheme.palette.accent)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(formattedDate)
                        .font(BabyTrackTheme.typography.headline.font)
                        .foregroundStyle(BabyTrackTheme.palette.primaryText)

                    if isToday {
                        Text("Today")
                            .font(BabyTrackTheme.typography.caption.font)
                            .foregroundStyle(BabyTrackTheme.palette.accent)
                    }
                }

                Spacer()

                Button {
                    viewModel.selectNextDay()
                    Task {
                        await viewModel.loadEvents(repository: eventsRepository)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(isToday ? BabyTrackTheme.palette.mutedText : BabyTrackTheme.palette.accent)
                        .frame(width: 44, height: 44)
                }
                .disabled(isToday)
            }
            .padding(.horizontal, BabyTrackTheme.spacing.md)

            // Quick date buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BabyTrackTheme.spacing.sm) {
                    quickDateButton(title: "Today", daysAgo: 0)
                    quickDateButton(title: "Yesterday", daysAgo: 1)
                    quickDateButton(title: "2 days ago", daysAgo: 2)
                    quickDateButton(title: "3 days ago", daysAgo: 3)
                }
                .padding(.horizontal, BabyTrackTheme.spacing.md)
            }
        }
    }

    private func quickDateButton(title: String, daysAgo: Int) -> some View {
        let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let isSelected = Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: targetDate)

        return Button {
            viewModel.selectDate(Calendar.current.startOfDay(for: targetDate))
            Task {
                await viewModel.loadEvents(repository: eventsRepository)
            }
        } label: {
            Text(title)
                .font(BabyTrackTheme.typography.callout.font)
                .foregroundStyle(
                    isSelected
                        ? BabyTrackTheme.palette.accentContrast
                        : BabyTrackTheme.palette.primaryText
                )
                .padding(.horizontal, BabyTrackTheme.spacing.md)
                .padding(.vertical, BabyTrackTheme.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft)
                        .fill(
                            isSelected
                                ? BabyTrackTheme.palette.accent
                                : BabyTrackTheme.palette.secondaryBackground
                        )
                )
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: viewModel.selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }

    // MARK: - Timeline View

    private var timelineView: some View {
        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
            Text("Daily Rhythm")
                .font(BabyTrackTheme.typography.headline.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)
                .padding(.horizontal, BabyTrackTheme.spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Time axis background
                    timeAxisView

                    // Event blocks
                    eventBlocksView
                }
                .frame(width: hourWidth * 24, height: trackHeight + 40)
            }

            // Legend
            legendView
        }
    }

    private var timeAxisView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hour markers
            HStack(spacing: 0) {
                ForEach(0..<24) { hour in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%02d:00", hour))
                            .font(BabyTrackTheme.typography.caption.font)
                            .foregroundStyle(BabyTrackTheme.palette.mutedText)
                            .frame(width: hourWidth, alignment: .leading)

                        Rectangle()
                            .fill(BabyTrackTheme.palette.outline.opacity(0.3))
                            .frame(width: 1, height: trackHeight)
                    }
                }
            }
        }
        .padding(.top, 20)
    }

    private var eventBlocksView: some View {
        ForEach(viewModel.events) { event in
            eventBlock(for: event)
        }
    }

    private func eventBlock(for event: EventDTO) -> some View {
        let position = eventPosition(for: event)

        return Button {
            viewModel.selectedEvent = event
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: event.kind.symbol)
                        .font(.system(size: 12))
                    Text(event.kind.rawValue.capitalized)
                        .font(BabyTrackTheme.typography.caption.font)
                }
                .foregroundStyle(.white)

                if position.width > 60 {
                    Text(formatDuration(event.duration))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(BabyTrackTheme.spacing.xs)
            .frame(width: position.width, height: 60, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorForEventKind(event.kind))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(viewModel.selectedEvent?.id == event.id ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .offset(x: position.x, y: 20)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedEvent?.id)
    }

    private func eventPosition(for event: EventDTO) -> (x: CGFloat, width: CGFloat) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: event.start)

        // Calculate offset from start of day
        let startOffset = event.start.timeIntervalSince(startOfDay)
        let startHour = startOffset / 3600.0

        // Calculate duration
        let endDate = event.end ?? Date()
        var duration = endDate.timeIntervalSince(event.start)

        // Handle events that cross midnight
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        if endDate > endOfDay {
            duration = endOfDay.timeIntervalSince(event.start)
        }

        let durationHours = max(0.1, duration / 3600.0) // Minimum 0.1 hour for visibility

        let x = startHour * hourWidth
        let width = durationHours * hourWidth

        return (x: x, width: width)
    }

    private func colorForEventKind(_ kind: EventKind) -> Color {
        switch kind {
        case .sleep:
            return Color.blue.opacity(0.8)
        case .feed:
            return Color.pink.opacity(0.8)
        case .diaper:
            return Color.yellow.opacity(0.8)
        case .pumping:
            return Color.purple.opacity(0.8)
        }
    }

    private var legendView: some View {
        HStack(spacing: BabyTrackTheme.spacing.lg) {
            ForEach(EventKind.allCases) { kind in
                HStack(spacing: BabyTrackTheme.spacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForEventKind(kind))
                        .frame(width: 16, height: 16)

                    Text(kind.rawValue.capitalized)
                        .font(BabyTrackTheme.typography.caption.font)
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }
            }
        }
        .padding(.horizontal, BabyTrackTheme.spacing.md)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: BabyTrackTheme.spacing.md) {
            ProgressView()
                .tint(BabyTrackTheme.palette.accent)
            Text("Loading daily rhythm...")
                .font(BabyTrackTheme.typography.callout.font)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
        }
        .frame(height: 200)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(BabyTrackTheme.palette.destructive)
            Text("Error loading data")
                .font(BabyTrackTheme.typography.headline.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)
            Text(message)
                .font(BabyTrackTheme.typography.callout.font)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .padding(BabyTrackTheme.spacing.md)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "calendar",
            title: "No activities yet",
            message: "Events logged for this day will appear here"
        )
        .frame(height: 200)
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - ViewModel

extension DailyRhythmView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var selectedDate: Date
        @Published var events: [EventDTO] = []
        @Published var selectedEvent: EventDTO?
        @Published var isLoading = false
        @Published var error: String?

        init(selectedDate: Date) {
            self.selectedDate = Calendar.current.startOfDay(for: selectedDate)
        }

        func selectDate(_ date: Date) {
            selectedDate = Calendar.current.startOfDay(for: date)
            selectedEvent = nil
        }

        func selectPreviousDay() {
            if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                selectDate(previousDay)
            }
        }

        func selectNextDay() {
            let today = Calendar.current.startOfDay(for: Date())
            if selectedDate < today {
                if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                    selectDate(nextDay)
                }
            }
        }

        func loadEvents(repository: any EventsRepository) async {
            isLoading = true
            error = nil

            do {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: selectedDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    error = "Invalid date"
                    isLoading = false
                    return
                }

                let interval = DateInterval(start: startOfDay, end: endOfDay)
                let fetchedEvents = try await repository.events(in: interval, kind: nil)

                // Sort by start time
                events = fetchedEvents.sorted { $0.start < $1.start }
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
struct DailyRhythmView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = PreviewEventsRepository()
        let aggregator = ChartDataAggregator(eventsRepository: repository)
        let viewModel = ChartsViewModel(aggregator: aggregator)

        return Group {
            // Light mode
            DailyRhythmView(viewModel: viewModel)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            // Dark mode
            DailyRhythmView(viewModel: viewModel)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }

    private actor PreviewEventsRepository: EventsRepository {
        func create(_ dto: EventDTO) async throws -> EventDTO { dto }
        func update(_ dto: EventDTO) async throws -> EventDTO { dto }
        func delete(id: UUID) async throws {}

        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            return [
                // Night sleep
                EventDTO(
                    kind: .sleep,
                    start: calendar.date(byAdding: .hour, value: 1, to: today)!,
                    end: calendar.date(byAdding: .hour, value: 8, to: today)!
                ),
                // Morning feed
                EventDTO(
                    kind: .feed,
                    start: calendar.date(byAdding: .hour, value: 8, to: today)!,
                    end: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 8, to: today)!)!
                ),
                // Diaper change
                EventDTO(
                    kind: .diaper,
                    start: calendar.date(byAdding: .hour, value: 9, to: today)!,
                    end: calendar.date(byAdding: .minute, value: 5, to: calendar.date(byAdding: .hour, value: 9, to: today)!)!
                ),
                // Morning nap
                EventDTO(
                    kind: .sleep,
                    start: calendar.date(byAdding: .hour, value: 10, to: today)!,
                    end: calendar.date(byAdding: .hour, value: 12, to: today)!
                ),
                // Lunch feed
                EventDTO(
                    kind: .feed,
                    start: calendar.date(byAdding: .hour, value: 12, to: today)!,
                    end: calendar.date(byAdding: .minute, value: 25, to: calendar.date(byAdding: .hour, value: 12, to: today)!)!
                ),
                // Afternoon nap
                EventDTO(
                    kind: .sleep,
                    start: calendar.date(byAdding: .hour, value: 14, to: today)!,
                    end: calendar.date(byAdding: .hour, value: 16, to: today)!
                ),
                // Evening feed
                EventDTO(
                    kind: .feed,
                    start: calendar.date(byAdding: .hour, value: 18, to: today)!,
                    end: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 18, to: today)!)!
                ),
                // Night sleep (ongoing)
                EventDTO(
                    kind: .sleep,
                    start: calendar.date(byAdding: .hour, value: 21, to: today)!,
                    end: nil
                )
            ]
        }

        func lastEvent(for kind: EventKind) async throws -> EventDTO? { nil }
        func stats(for day: Date) async throws -> EventDayStats {
            EventDayStats(date: day, totalEvents: 0, totalDuration: 0)
        }
    }
}
#endif
