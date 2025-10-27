import Charts
import Content
import DesignSystem
import SwiftUI

/// Displays sleep analytics charts with multiple visualizations and date range controls.
///
/// Features:
/// - Total sleep per day (bar chart, 7 days)
/// - Average sleep duration statistics
/// - Date range selector (7/14/30 days)
/// - Loading and empty states
/// - Dark mode support
public struct SleepChartsView: View {
    @StateObject private var viewModel: ChartsViewModel
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: ChartsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: BabyTrackTheme.spacing.lg) {
                // Date range selector
                dateRangeSelector

                // Total sleep per day chart
                totalSleepChart

                // Statistics summary
                if let series = viewModel.series(for: .sleepTotal) {
                    statisticsSummary(for: series)
                }
            }
            .padding(.vertical, BabyTrackTheme.spacing.lg)
        }
        .background(BabyTrackTheme.palette.background.ignoresSafeArea())
        .task {
            await viewModel.loadChart(for: .sleepTotal)
        }
    }

    // MARK: - Date Range Selector

    private var dateRangeSelector: some View {
        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
            Text("Time Period")
                .font(BabyTrackTheme.typography.headline.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)
                .padding(.horizontal, BabyTrackTheme.spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BabyTrackTheme.spacing.sm) {
                    ForEach(DateRangePreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                        dateRangeButton(preset)
                    }
                }
                .padding(.horizontal, BabyTrackTheme.spacing.md)
            }
        }
    }

    private func dateRangeButton(_ preset: DateRangePreset) -> some View {
        Button {
            Task {
                await viewModel.changeDateRange(preset)
            }
        } label: {
            Text(preset.displayName)
                .font(BabyTrackTheme.typography.callout.font)
                .foregroundStyle(
                    viewModel.selectedDateRange == preset
                        ? BabyTrackTheme.palette.accentContrast
                        : BabyTrackTheme.palette.primaryText
                )
                .padding(.horizontal, BabyTrackTheme.spacing.md)
                .padding(.vertical, BabyTrackTheme.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft)
                        .fill(
                            viewModel.selectedDateRange == preset
                                ? BabyTrackTheme.palette.accent
                                : BabyTrackTheme.palette.secondaryBackground
                        )
                )
        }
    }

    // MARK: - Total Sleep Chart

    private var totalSleepChart: some View {
        ChartCard(
            title: "Total Sleep Per Day",
            subtitle: viewModel.selectedDateRange.displayName
        ) {
            Group {
                if viewModel.isLoading(.sleepTotal) {
                    loadingView
                } else if let error = viewModel.error(for: .sleepTotal) {
                    errorView(error)
                } else if let series = viewModel.series(for: .sleepTotal) {
                    if series.points.isEmpty || series.statistics.sampleCount == 0 {
                        emptyStateView
                    } else {
                        sleepBarChart(series: series)
                    }
                } else {
                    emptyStateView
                }
            }
            .frame(height: 220)
        }
    }

    private func sleepBarChart(series: ChartSeries) -> some View {
        Chart {
            ForEach(series.points, id: \.interval.start) { point in
                BarMark(
                    x: .value("Date", point.interval.start, unit: .day),
                    y: .value("Hours", point.value)
                )
                .foregroundStyle(sleepBarGradient)
                .cornerRadius(BabyTrackTheme.radii.soft)
                .annotation(position: .top, alignment: .center) {
                    if point.value > 0 {
                        Text(formatHours(point.value))
                            .font(BabyTrackTheme.typography.caption.font)
                            .foregroundStyle(BabyTrackTheme.palette.mutedText)
                    }
                }
            }

            // Average line
            if series.statistics.sampleCount > 0 {
                RuleMark(y: .value("Average", series.statistics.average))
                    .foregroundStyle(BabyTrackTheme.palette.warning.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(formatHours(series.statistics.average))")
                            .font(BabyTrackTheme.typography.caption.font)
                            .foregroundStyle(BabyTrackTheme.palette.warning)
                            .padding(.horizontal, BabyTrackTheme.spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(BabyTrackTheme.palette.background)
                            )
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: series.points.count)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDate(date))
                            .font(BabyTrackTheme.typography.caption.font)
                    }
                    AxisGridLine()
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                            .font(BabyTrackTheme.typography.caption.font)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYScale(domain: 0...(series.statistics.maximum * 1.2))
        .animation(.easeInOut(duration: 0.3), value: series.points.map(\.value))
    }

    private var sleepBarGradient: LinearGradient {
        LinearGradient(
            colors: [
                BabyTrackTheme.palette.accent.opacity(0.8),
                BabyTrackTheme.palette.accent
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Statistics Summary

    private func statisticsSummary(for series: ChartSeries) -> some View {
        ChartCard(title: "Sleep Statistics") {
            HStack(spacing: BabyTrackTheme.spacing.lg) {
                statisticItem(
                    title: "Average",
                    value: formatHours(series.statistics.average),
                    icon: "moon.fill"
                )

                Divider()
                    .frame(height: 40)

                statisticItem(
                    title: "Longest",
                    value: formatHours(series.statistics.maximum),
                    icon: "star.fill"
                )

                Divider()
                    .frame(height: 40)

                statisticItem(
                    title: "Shortest",
                    value: formatHours(series.statistics.minimum),
                    icon: "clock.fill"
                )
            }
            .padding(.vertical, BabyTrackTheme.spacing.sm)
        }
    }

    private func statisticItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: BabyTrackTheme.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(BabyTrackTheme.palette.accent)

            Text(value)
                .font(BabyTrackTheme.typography.title3.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)

            Text(title)
                .font(BabyTrackTheme.typography.caption.font)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: BabyTrackTheme.spacing.md) {
            ProgressView()
                .tint(BabyTrackTheme.palette.accent)
            Text("Loading sleep data...")
                .font(BabyTrackTheme.typography.callout.font)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(BabyTrackTheme.spacing.md)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "moon.zzz.fill",
            title: "Not enough data",
            message: "Start tracking sleep sessions to see your baby's sleep patterns"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Formatters

    private func formatHours(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if m == 0 {
            return "\(h)h"
        }
        return "\(h)h \(m)m"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#if DEBUG
struct SleepChartsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockRepository = PreviewEventsRepository()
        let aggregator = ChartDataAggregator(
            eventsRepository: mockRepository,
            calendar: .current
        )
        let viewModel = ChartsViewModel(
            aggregator: aggregator,
            calendar: .current
        )

        Group {
            // Light mode
            SleepChartsView(viewModel: viewModel)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            // Dark mode
            SleepChartsView(viewModel: viewModel)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }

    // Mock repository for previews
    private actor PreviewEventsRepository: EventsRepository {
        func create(_ dto: EventDTO) async throws -> EventDTO {
            dto
        }

        func update(_ dto: EventDTO) async throws -> EventDTO {
            dto
        }

        func delete(id: UUID) async throws {}

        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
            // Generate mock sleep events for the last 7 days
            let calendar = Calendar.current
            let now = Date()
            var mockEvents: [EventDTO] = []

            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let startOfDay = calendar.startOfDay(for: day)

                // Night sleep (7-9 hours)
                let sleepHours = Double.random(in: 7...9)
                if let sleepStart = calendar.date(byAdding: .hour, value: 22, to: startOfDay),
                   let sleepEnd = calendar.date(byAdding: .hour, value: Int(sleepHours), to: sleepStart) {
                    mockEvents.append(EventDTO(
                        kind: .sleep,
                        start: sleepStart,
                        end: sleepEnd
                    ))
                }

                // Day naps (1-3 naps)
                let napCount = Int.random(in: 1...3)
                for napIndex in 0..<napCount {
                    let napHour = 10 + napIndex * 3
                    let napDuration = Double.random(in: 0.5...2.0)
                    if let napStart = calendar.date(byAdding: .hour, value: napHour, to: startOfDay),
                       let napEnd = calendar.date(byAdding: .hour, value: Int(napDuration), to: napStart) {
                        mockEvents.append(EventDTO(
                            kind: .sleep,
                            start: napStart,
                            end: napEnd
                        ))
                    }
                }
            }

            return mockEvents
        }

        func lastEvent(for kind: EventKind) async throws -> EventDTO? {
            nil
        }

        func stats(for day: Date) async throws -> EventDayStats {
            EventDayStats(date: day, totalEvents: 0, totalDuration: 0)
        }
    }
}
#endif
