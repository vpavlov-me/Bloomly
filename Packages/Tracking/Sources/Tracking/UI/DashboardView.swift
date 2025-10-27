import AppSupport
import Content
import DesignSystem
import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    private let analytics: any Analytics
    private let onQuickAction: (EventKind) -> Void

    public init(
        viewModel: DashboardViewModel,
        analytics: any Analytics,
        onQuickAction: @escaping (EventKind) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.analytics = analytics
        self.onQuickAction = onQuickAction
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: BabyTrackTheme.spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    contentView
                }
            }
            .padding(BabyTrackTheme.spacing.lg)
        }
        .navigationTitle(Text(AppCopy.string(for: "dashboard.title")))
        .task {
            await viewModel.load()
            analytics.track(AnalyticsEvent(name: "dashboard_viewed"))
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var contentView: some View {
        VStack(spacing: BabyTrackTheme.spacing.lg) {
            // Active event banner (if any)
            if !viewModel.activeEvents.isEmpty {
                activeEventsBanner
            }

            // Quick action buttons
            quickActionsGrid

            // Time since last cards
            timeSinceLastSection

            // Today's summary
            if let stats = viewModel.todayStats {
                todaySummarySection(stats: stats)
            }
        }
    }

    private var activeEventsBanner: some View {
        VStack(spacing: BabyTrackTheme.spacing.sm) {
            ForEach(viewModel.activeEvents) { event in
                ActiveEventBanner(event: event)
            }
        }
    }

    private var quickActionsGrid: some View {
        Card {
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.md) {
                BabyTrackTheme.typography.headline.text(
                    String(localized: "dashboard.quickActions.title")
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: BabyTrackTheme.spacing.sm
                ) {
                    ForEach(EventKind.allCases) { kind in
                        QuickActionButton(kind: kind) {
                            analytics.track(AnalyticsEvent(
                                name: "quick_action_tapped",
                                metadata: ["kind": kind.rawValue]
                            ))
                            onQuickAction(kind)
                        }
                    }
                }
            }
        }
    }

    private var timeSinceLastSection: some View {
        VStack(spacing: BabyTrackTheme.spacing.sm) {
            ForEach(EventKind.allCases) { kind in
                if let timeSince = viewModel.timeSinceLastEvent(for: kind) {
                    TimeSinceCard(kind: kind, timeSince: timeSince)
                }
            }
        }
    }

    private func todaySummarySection(stats: DashboardStats) -> some View {
        Card {
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.md) {
                BabyTrackTheme.typography.headline.text(
                    String(localized: "dashboard.todaySummary.title")
                )

                VStack(spacing: BabyTrackTheme.spacing.sm) {
                    StatRow(
                        icon: EventKind.sleep.symbol,
                        title: String(localized: "dashboard.stats.sleep"),
                        value: "\(stats.sleepCount) • \(formatDuration(stats.totalSleepDuration))"
                    )

                    Divider()

                    StatRow(
                        icon: EventKind.feed.symbol,
                        title: String(localized: "dashboard.stats.feeding"),
                        value: "\(stats.feedingCount) • \(formatDuration(stats.totalFeedingDuration))"
                    )

                    Divider()

                    StatRow(
                        icon: EventKind.diaper.symbol,
                        title: String(localized: "dashboard.stats.diaper"),
                        value: "\(stats.diaperCount)"
                    )

                    Divider()

                    StatRow(
                        icon: EventKind.pumping.symbol,
                        title: String(localized: "dashboard.stats.pumping"),
                        value: "\(stats.pumpingCount)"
                    )
                }
            }
        }
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: String(localized: "dashboard.error.title"),
            message: message,
            actionTitle: String(localized: "dashboard.error.retry")
        ) {
            Task { await viewModel.refresh() }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return String(localized: "dashboard.duration.hoursMinutes \(hours) \(minutes)")
        } else {
            return String(localized: "dashboard.duration.minutes \(minutes)")
        }
    }
}

// MARK: - Supporting Views

private struct ActiveEventBanner: View {
    let event: EventDTO

    var body: some View {
        Card {
            HStack(spacing: BabyTrackTheme.spacing.md) {
                Image(systemName: event.kind.symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(BabyTrackTheme.palette.accent)

                VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.xs) {
                    BabyTrackTheme.typography.headline.text(
                        AppCopy.string(for: event.kind.titleKey)
                    )
                    BabyTrackTheme.typography.body.text(
                        AppCopy.string(for: "dashboard.activeEvent.ongoing")
                    )
                    .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }

                Spacer()

                ElapsedTimeView(startDate: event.start)
            }
        }
        .background(BabyTrackTheme.palette.accent.opacity(0.1))
    }
}

private struct QuickActionButton: View {
    let kind: EventKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: BabyTrackTheme.spacing.sm) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 32))
                    .foregroundStyle(BabyTrackTheme.palette.accent)

                Text(LocalizedStringKey(kind.titleKey))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BabyTrackTheme.spacing.md)
            .background(BabyTrackTheme.palette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft))
        }
        .buttonStyle(.plain)
    }
}

private struct TimeSinceCard: View {
    let kind: EventKind
    let timeSince: TimeInterval

    var body: some View {
        Card {
            HStack {
                Image(systemName: kind.symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(BabyTrackTheme.palette.accent)

                VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.xs) {
                    Text(LocalizedStringKey(kind.titleKey))
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                    Text(formatTimeSince(timeSince))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }

                Spacer()
            }
        }
    }

    private func formatTimeSince(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return String(localized: "dashboard.timeSince.hours \(hours)")
        } else if minutes > 0 {
            return String(localized: "dashboard.timeSince.minutes \(minutes)")
        } else {
            return String(localized: "dashboard.timeSince.justNow")
        }
    }
}

private struct StatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .frame(width: 24)

            Text(title)
                .font(.system(.body, design: .rounded))

            Spacer()

            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
    }
}

private struct ElapsedTimeView: View {
    let startDate: Date
    @State private var elapsedTime: TimeInterval = 0

    var body: some View {
        Text(formatElapsedTime(elapsedTime))
            .font(.system(.title2, design: .rounded).weight(.bold))
            .monospacedDigit()
            .onAppear {
                updateElapsedTime()
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                updateElapsedTime()
            }
    }

    private func updateElapsedTime() {
        elapsedTime = Date().timeIntervalSince(startDate)
    }

    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView(
                viewModel: DashboardViewModel(eventsRepository: PreviewEventsRepository()),
                analytics: AnalyticsLogger()
            ) { kind in
                print("Quick action: \(kind)")
            }
        }
    }

    private struct PreviewEventsRepository: EventsRepository {
        func create(_ dto: EventDTO) async throws -> EventDTO { dto }
        func update(_ dto: EventDTO) async throws -> EventDTO { dto }
        func delete(id: UUID) async throws {}
        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
            [
                EventDTO(kind: .sleep, start: Date().addingTimeInterval(-7200), end: Date().addingTimeInterval(-3600)),
                EventDTO(kind: .feed, start: Date().addingTimeInterval(-1800)),
                EventDTO(kind: .diaper, start: Date().addingTimeInterval(-3600))
            ]
        }
        func lastEvent(for kind: EventKind) async throws -> EventDTO? {
            EventDTO(kind: kind, start: Date().addingTimeInterval(-3600))
        }
        func stats(for day: Date) async throws -> EventDayStats {
            .init(date: Date(), totalEvents: 5, totalDuration: 7200)
        }
    }
}
#endif
