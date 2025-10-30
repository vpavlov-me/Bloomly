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
            VStack(spacing: BloomyTheme.spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    contentView
                }
            }
            .padding(BloomyTheme.spacing.lg)
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
        VStack(spacing: BloomyTheme.spacing.lg) {
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
        VStack(spacing: BloomyTheme.spacing.sm) {
            ForEach(viewModel.activeEvents) { event in
                ActiveEventBanner(event: event)
            }
        }
    }

    private var quickActionsGrid: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.headline.text(
                    String(localized: "dashboard.quickActions.title")
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: BloomyTheme.spacing.sm
                ) {
                    // Show only implemented tracking features
                    ForEach([EventKind.sleep, .feeding, .diaper, .pumping]) { kind in
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
        VStack(spacing: BloomyTheme.spacing.sm) {
            // Show only implemented tracking features
            ForEach([EventKind.sleep, .feeding, .diaper, .pumping]) { kind in
                if let timeSince = viewModel.timeSinceLastEvent(for: kind) {
                    TimeSinceCard(kind: kind, timeSince: timeSince)
                }
            }
        }
    }

    private func todaySummarySection(stats: DashboardStats) -> some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.headline.text(
                    String(localized: "dashboard.todaySummary.title")
                )

                VStack(spacing: BloomyTheme.spacing.sm) {
                    StatRow(
                        icon: EventKind.sleep.symbol,
                        title: String(localized: "dashboard.stats.sleep"),
                        value: "\(stats.sleepCount) • \(formatDuration(stats.totalSleepDuration))"
                    )

                    Divider()

                    StatRow(
                        icon: EventKind.feeding.symbol,
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
            HStack(spacing: BloomyTheme.spacing.md) {
                Image(systemName: event.kind.symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(BloomyTheme.palette.accent)

                VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
                    BloomyTheme.typography.headline.text(
                        AppCopy.string(for: event.kind.titleKey)
                    )
                    BloomyTheme.typography.body.text(
                        AppCopy.string(for: "dashboard.activeEvent.ongoing")
                    )
                    .foregroundStyle(BloomyTheme.palette.mutedText)
                }

                Spacer()

                ElapsedTimeView(startDate: event.start)
            }
        }
        .background(BloomyTheme.palette.accent.opacity(0.1))
    }
}

private struct QuickActionButton: View {
    let kind: EventKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: BloomyTheme.spacing.sm) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 32))
                    .foregroundStyle(BloomyTheme.palette.accent)

                Text(LocalizedStringKey(kind.titleKey))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BloomyTheme.spacing.md)
            .background(BloomyTheme.palette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: BloomyTheme.radii.soft))
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
                    .foregroundStyle(BloomyTheme.palette.accent)

                VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
                    Text(LocalizedStringKey(kind.titleKey))
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                    Text(formatTimeSince(timeSince))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(BloomyTheme.palette.mutedText)
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
                .foregroundStyle(BloomyTheme.palette.accent)
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
        let now = Date()
        let events = [
            EventDTO(kind: .sleep, start: now.addingTimeInterval(-7200), end: now.addingTimeInterval(-3600)),
            EventDTO(kind: .feeding, start: now.addingTimeInterval(-1800)),
            EventDTO(kind: .diaper, start: now.addingTimeInterval(-3600))
        ]
        let lastEvents: [EventKind: EventDTO] = [
            .sleep: events[0],
            .feeding: events[1],
            .diaper: events[2]
        ]

        NavigationStack {
            DashboardView(
                viewModel: DashboardViewModel(eventsRepository: MockEventsRepository(events: events, lastEvents: lastEvents)),
                analytics: AnalyticsLogger()
            ) { kind in
                print("Quick action: \(kind)")
            }
        }
    }
}
#endif
