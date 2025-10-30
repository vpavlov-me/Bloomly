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
    @Environment(\.colorScheme)
    private var colorScheme

    public init(viewModel: ChartsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: BloomyTheme.spacing.lg) {
                // Date range selector
                dateRangeSelector

                // Total sleep per day chart
                totalSleepChart

                // Statistics summary
                if let series = viewModel.series(for: .sleepTotal) {
                    statisticsSummary(for: series)
                }
            }
            .padding(.vertical, BloomyTheme.spacing.lg)
        }
        .background(BloomyTheme.palette.background.ignoresSafeArea())
        .task {
            await viewModel.loadChart(for: .sleepTotal)
        }
    }

    // MARK: - Date Range Selector

    private var dateRangeSelector: some View {
        VStack(alignment: .leading, spacing: BloomyTheme.spacing.sm) {
            Text("Time Period")
                .font(BloomyTheme.typography.headline.font)
                .foregroundStyle(BloomyTheme.palette.primaryText)
                .padding(.horizontal, BloomyTheme.spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BloomyTheme.spacing.sm) {
                    ForEach(DateRangePreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                        dateRangeButton(preset)
                    }
                }
                .padding(.horizontal, BloomyTheme.spacing.md)
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
                .font(BloomyTheme.typography.callout.font)
                .foregroundStyle(
                    viewModel.selectedDateRange == preset
                        ? BloomyTheme.palette.accentContrast
                        : BloomyTheme.palette.primaryText
                )
                .padding(.horizontal, BloomyTheme.spacing.md)
                .padding(.vertical, BloomyTheme.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BloomyTheme.radii.soft)
                        .fill(
                            viewModel.selectedDateRange == preset
                                ? BloomyTheme.palette.accent
                                : BloomyTheme.palette.secondaryBackground
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
                .cornerRadius(BloomyTheme.radii.soft)
                .annotation(position: .top, alignment: .center) {
                    if point.value > 0 {
                        Text(formatHours(point.value))
                            .font(BloomyTheme.typography.caption.font)
                            .foregroundStyle(BloomyTheme.palette.mutedText)
                    }
                }
            }

            // Average line
            if series.statistics.sampleCount > 0 {
                RuleMark(y: .value("Average", series.statistics.average))
                    .foregroundStyle(BloomyTheme.palette.warning.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(formatHours(series.statistics.average))")
                            .font(BloomyTheme.typography.caption.font)
                            .foregroundStyle(BloomyTheme.palette.warning)
                            .padding(.horizontal, BloomyTheme.spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(BloomyTheme.palette.background)
                            )
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: series.points.count)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDate(date))
                            .font(BloomyTheme.typography.caption.font)
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
                            .font(BloomyTheme.typography.caption.font)
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
                BloomyTheme.palette.accent.opacity(0.8),
                BloomyTheme.palette.accent
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Statistics Summary

    private func statisticsSummary(for series: ChartSeries) -> some View {
        ChartCard(title: "Sleep Statistics") {
            HStack(spacing: BloomyTheme.spacing.lg) {
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
            .padding(.vertical, BloomyTheme.spacing.sm)
        }
    }

    private func statisticItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: BloomyTheme.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(BloomyTheme.palette.accent)

            Text(value)
                .font(BloomyTheme.typography.title3.font)
                .foregroundStyle(BloomyTheme.palette.primaryText)

            Text(title)
                .font(BloomyTheme.typography.caption.font)
                .foregroundStyle(BloomyTheme.palette.mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: BloomyTheme.spacing.md) {
            ProgressView()
                .tint(BloomyTheme.palette.accent)
            Text("Loading sleep data...")
                .font(BloomyTheme.typography.callout.font)
                .foregroundStyle(BloomyTheme.palette.mutedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: BloomyTheme.spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(BloomyTheme.palette.destructive)
            Text("Error loading data")
                .font(BloomyTheme.typography.headline.font)
                .foregroundStyle(BloomyTheme.palette.primaryText)
            Text(message)
                .font(BloomyTheme.typography.callout.font)
                .foregroundStyle(BloomyTheme.palette.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(BloomyTheme.spacing.md)
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
        let hoursValue = totalMinutes / 60
        let minutesValue = totalMinutes % 60
        if minutesValue == 0 {
            return "\(hoursValue)h"
        }
        return "\(hoursValue)h \(minutesValue)m"
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
        let mockRepository = MockEventsRepository()
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
}
#endif
