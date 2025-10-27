import Charts
import Content
import DesignSystem
import SwiftUI

/// Displays feeding analytics with multiple chart types and interactive filters.
///
/// Features:
/// - Feedings per day (bar chart)
/// - Average feeding duration (line chart)
/// - Date range selector
/// - Loading and empty states
/// - Dark mode support
public struct FeedingChartsView: View {
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

                // Feeding frequency chart
                feedingFrequencyChart

                // Average duration chart
                averageDurationChart

                // Statistics summary
                if let frequencySeries = viewModel.series(for: .feedFrequency),
                   let durationSeries = viewModel.series(for: .feedAverageDuration) {
                    statisticsSummary(frequency: frequencySeries, duration: durationSeries)
                }
            }
            .padding(.vertical, BabyTrackTheme.spacing.lg)
        }
        .background(BabyTrackTheme.palette.background.ignoresSafeArea())
        .task {
            await loadCharts()
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

    // MARK: - Feeding Frequency Chart

    private var feedingFrequencyChart: some View {
        ChartCard(
            title: "Feedings Per Day",
            subtitle: viewModel.selectedDateRange.displayName
        ) {
            Group {
                if viewModel.isLoading(.feedFrequency) {
                    loadingView
                } else if let error = viewModel.error(for: .feedFrequency) {
                    errorView(error)
                } else if let series = viewModel.series(for: .feedFrequency) {
                    if series.points.isEmpty || series.statistics.sampleCount == 0 {
                        emptyStateView
                    } else {
                        feedingFrequencyBarChart(series: series)
                    }
                } else {
                    emptyStateView
                }
            }
            .frame(height: 220)
        }
    }

    private func feedingFrequencyBarChart(series: ChartSeries) -> some View {
        Chart {
            ForEach(series.points, id: \.interval.start) { point in
                BarMark(
                    x: .value("Date", point.interval.start, unit: .day),
                    y: .value("Count", point.value)
                )
                .foregroundStyle(feedingBarGradient)
                .cornerRadius(BabyTrackTheme.radii.soft)
                .annotation(position: .top, alignment: .center) {
                    if point.value > 0 {
                        Text("\(Int(point.value))")
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
                        Text("Avg: \(String(format: "%.1f", series.statistics.average))")
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
                    if let count = value.as(Double.self) {
                        Text("\(Int(count))")
                            .font(BabyTrackTheme.typography.caption.font)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYScale(domain: 0...(series.statistics.maximum * 1.2))
        .animation(.easeInOut(duration: 0.3), value: series.points.map(\.value))
    }

    private var feedingBarGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.pink.opacity(0.8),
                Color.pink
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Average Duration Chart

    private var averageDurationChart: some View {
        ChartCard(
            title: "Average Feeding Duration",
            subtitle: viewModel.selectedDateRange.displayName
        ) {
            Group {
                if viewModel.isLoading(.feedAverageDuration) {
                    loadingView
                } else if let error = viewModel.error(for: .feedAverageDuration) {
                    errorView(error)
                } else if let series = viewModel.series(for: .feedAverageDuration) {
                    if series.points.isEmpty || series.statistics.sampleCount == 0 {
                        emptyStateView
                    } else {
                        averageDurationLineChart(series: series)
                    }
                } else {
                    emptyStateView
                }
            }
            .frame(height: 220)
        }
    }

    private func averageDurationLineChart(series: ChartSeries) -> some View {
        Chart {
            ForEach(series.points, id: \.interval.start) { point in
                LineMark(
                    x: .value("Date", point.interval.start, unit: .day),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(Color.purple)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.interval.start, unit: .day),
                    y: .value("Minutes", point.value)
                )
                .foregroundStyle(Color.purple)
                .symbolSize(60)
            }

            // Average line
            if series.statistics.sampleCount > 0 {
                RuleMark(y: .value("Average", series.statistics.average))
                    .foregroundStyle(BabyTrackTheme.palette.success.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(Int(series.statistics.average))m")
                            .font(BabyTrackTheme.typography.caption.font)
                            .foregroundStyle(BabyTrackTheme.palette.success)
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
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes))m")
                            .font(BabyTrackTheme.typography.caption.font)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYScale(domain: 0...(series.statistics.maximum * 1.2))
        .animation(.easeInOut(duration: 0.3), value: series.points.map(\.value))
    }

    // MARK: - Statistics Summary

    private func statisticsSummary(frequency: ChartSeries, duration: ChartSeries) -> some View {
        ChartCard(title: "Feeding Statistics") {
            HStack(spacing: BabyTrackTheme.spacing.lg) {
                statisticItem(
                    title: "Total Feeds",
                    value: "\(Int(frequency.statistics.total))",
                    icon: "fork.knife"
                )

                Divider()
                    .frame(height: 40)

                statisticItem(
                    title: "Avg Duration",
                    value: "\(Int(duration.statistics.average))m",
                    icon: "clock.fill"
                )

                Divider()
                    .frame(height: 40)

                statisticItem(
                    title: "Longest",
                    value: "\(Int(duration.statistics.maximum))m",
                    icon: "star.fill"
                )
            }
            .padding(.vertical, BabyTrackTheme.spacing.sm)
        }
    }

    private func statisticItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: BabyTrackTheme.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.pink)

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
            Text("Loading feeding data...")
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
            icon: "fork.knife",
            title: "Not enough data",
            message: "Start tracking feedings to see patterns and statistics"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func loadCharts() async {
        await viewModel.loadChart(for: .feedFrequency)
        await viewModel.loadChart(for: .feedAverageDuration)
    }
}

// MARK: - Previews

#if DEBUG
struct FeedingChartsView_Previews: PreviewProvider {
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
            FeedingChartsView(viewModel: viewModel)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            // Dark mode
            FeedingChartsView(viewModel: viewModel)
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
            // Generate mock feeding events for the last 7 days
            let calendar = Calendar.current
            let now = Date()
            var mockEvents: [EventDTO] = []

            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let startOfDay = calendar.startOfDay(for: day)

                // 5-8 feedings per day
                let feedingCount = Int.random(in: 5...8)
                for feedingIndex in 0..<feedingCount {
                    let hour = 6 + feedingIndex * 3
                    let duration = Double.random(in: 10...30) * 60 // 10-30 minutes
                    if let feedStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay) {
                        let feedEnd = feedStart.addingTimeInterval(duration)
                        mockEvents.append(EventDTO(
                            kind: .feed,
                            start: feedStart,
                            end: feedEnd
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
