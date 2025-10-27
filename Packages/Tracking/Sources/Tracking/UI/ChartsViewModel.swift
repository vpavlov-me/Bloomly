import Combine
import Foundation

/// ViewModel for managing chart data presentation and user interactions.
///
/// Responsibilities:
/// - Fetches aggregated chart data through ChartDataAggregator
/// - Manages loading states and errors
/// - Provides convenient date range presets (7/14/30 days)
/// - Exposes chart data for multiple metrics
/// - Handles metric-specific cache invalidation
@MainActor
public final class ChartsViewModel: ObservableObject {
    // MARK: - Published State

    /// Currently selected aggregation period (day/week/month)
    @Published public var selectedPeriod: AggregationPeriod = .day

    /// Currently selected date range preset
    @Published public var selectedDateRange: DateRangePreset = .last7Days

    /// Custom date range (used when preset is .custom)
    @Published public var customDateRange: DateInterval?

    /// Loading states per metric
    @Published public private(set) var loadingStates: [ChartMetric: Bool] = [:]

    /// Error messages per metric
    @Published public private(set) var errors: [ChartMetric: String] = [:]

    /// Cached chart series per metric
    @Published public private(set) var chartData: [ChartMetric: ChartSeries] = [:]

    // MARK: - Dependencies

    public let aggregator: ChartDataAggregator
    private let calendar: Calendar
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        aggregator: ChartDataAggregator,
        calendar: Calendar = .current
    ) {
        self.aggregator = aggregator
        self.calendar = calendar

        setupObservers()
    }

    // MARK: - Public API

    /// Returns the chart series for the specified metric, or nil if not yet loaded
    public func series(for metric: ChartMetric) -> ChartSeries? {
        chartData[metric]
    }

    /// Returns loading state for the specified metric
    public func isLoading(_ metric: ChartMetric) -> Bool {
        loadingStates[metric] ?? false
    }

    /// Returns error message for the specified metric
    public func error(for metric: ChartMetric) -> String? {
        errors[metric]
    }

    /// Loads chart data for the specified metric
    public func loadChart(for metric: ChartMetric) async {
        loadingStates[metric] = true
        errors[metric] = nil

        do {
            let range = effectiveDateRange()
            let series = try await aggregator.series(
                for: metric,
                in: range,
                period: selectedPeriod
            )
            chartData[metric] = series
            loadingStates[metric] = false
        } catch {
            errors[metric] = error.localizedDescription
            loadingStates[metric] = false
        }
    }

    /// Loads chart data for all available metrics
    public func loadAllCharts() async {
        await withTaskGroup(of: Void.self) { group in
            for metric in ChartMetric.allCases {
                group.addTask {
                    await self.loadChart(for: metric)
                }
            }
        }
    }

    /// Refreshes chart data for the specified metric (invalidates cache first)
    public func refreshChart(for metric: ChartMetric) async {
        await aggregator.invalidateCache(metric: metric)
        await loadChart(for: metric)
    }

    /// Refreshes all chart data (invalidates entire cache)
    public func refreshAllCharts() async {
        await aggregator.invalidateCache()
        await loadAllCharts()
    }

    /// Changes the selected period and reloads all visible charts
    public func changePeriod(_ period: AggregationPeriod) async {
        guard period != selectedPeriod else { return }
        selectedPeriod = period
        await reloadVisibleCharts()
    }

    /// Changes the selected date range and reloads all visible charts
    public func changeDateRange(_ preset: DateRangePreset) async {
        guard preset != selectedDateRange else { return }
        selectedDateRange = preset
        await reloadVisibleCharts()
    }

    /// Sets a custom date range and reloads all visible charts
    public func setCustomDateRange(_ range: DateInterval) async {
        customDateRange = range
        selectedDateRange = .custom
        await reloadVisibleCharts()
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Automatically reload charts when period or date range changes
        Publishers.CombineLatest($selectedPeriod, $selectedDateRange)
            .dropFirst() // Skip initial value
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    await self?.reloadVisibleCharts()
                }
            }
            .store(in: &cancellables)
    }

    private func reloadVisibleCharts() async {
        // Only reload charts that have been loaded before
        let metricsToReload = chartData.keys
        await withTaskGroup(of: Void.self) { group in
            for metric in metricsToReload {
                group.addTask {
                    await self.loadChart(for: metric)
                }
            }
        }
    }

    private func effectiveDateRange() -> DateInterval {
        if selectedDateRange == .custom, let custom = customDateRange {
            return custom
        }

        let end = calendar.startOfDay(for: Date().addingTimeInterval(86400)) // End of today
        let start: Date

        switch selectedDateRange {
        case .last7Days:
            start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        case .last14Days:
            start = calendar.date(byAdding: .day, value: -14, to: end) ?? end
        case .last30Days:
            start = calendar.date(byAdding: .day, value: -30, to: end) ?? end
        case .thisWeek:
            start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? end
        case .thisMonth:
            start = calendar.dateInterval(of: .month, for: Date())?.start ?? end
        case .custom:
            // Fallback if custom range is not set
            start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        }

        return DateInterval(start: start, end: end)
    }
}

// MARK: - Supporting Types

/// Predefined date range presets for quick selection
public enum DateRangePreset: String, CaseIterable, Sendable {
    case last7Days
    case last14Days
    case last30Days
    case thisWeek
    case thisMonth
    case custom

    public var displayName: String {
        switch self {
        case .last7Days:
            return "Last 7 Days"
        case .last14Days:
            return "Last 14 Days"
        case .last30Days:
            return "Last 30 Days"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        case .custom:
            return "Custom"
        }
    }
}

extension ChartMetric: CaseIterable {
    public static let allCases: [ChartMetric] = [
        .sleepTotal,
        .feedAverageDuration,
        .feedFrequency,
        .diaperFrequency
    ]
}
