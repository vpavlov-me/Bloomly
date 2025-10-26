import Foundation

/// Represents the logical metric that should be plotted on a chart.
public enum ChartMetric: Sendable, Hashable {
    case sleepTotal
    case feedAverageDuration
    case feedFrequency
    case diaperFrequency

    public var unit: ChartUnit {
        switch self {
        case .sleepTotal:
            return .hours
        case .feedAverageDuration:
            return .minutes
        case .feedFrequency, .diaperFrequency:
            return .count
        }
    }
}

/// Defines the aggregation granularity that should be used for chart buckets.
public enum AggregationPeriod: Sendable, Hashable {
    case day
    case week
    case month
}

/// Simple unit marker that helps consumers present aggregated values.
public enum ChartUnit: Sendable {
    case hours
    case minutes
    case count
}

/// Represents a single point on a chart, including the covered interval.
public struct ChartDataPoint: Equatable, Sendable {
    public let interval: DateInterval
    public let value: Double
    public let sampleCount: Int

    public init(interval: DateInterval, value: Double, sampleCount: Int) {
        self.interval = interval
        self.value = value
        self.sampleCount = sampleCount
    }
}

/// Summary statistics calculated over an entire chart series.
public struct ChartStatistics: Equatable, Sendable {
    public let total: Double
    public let average: Double
    public let minimum: Double
    public let maximum: Double
    public let sampleCount: Int

    public init(total: Double, average: Double, minimum: Double, maximum: Double, sampleCount: Int) {
        self.total = total
        self.average = average
        self.minimum = minimum
        self.maximum = maximum
        self.sampleCount = sampleCount
    }
}

/// A full chart series containing all points and summary statistics.
public struct ChartSeries: Equatable, Sendable {
    public let metric: ChartMetric
    public let period: AggregationPeriod
    public let unit: ChartUnit
    public let points: [ChartDataPoint]
    public let statistics: ChartStatistics

    public init(metric: ChartMetric, period: AggregationPeriod, unit: ChartUnit, points: [ChartDataPoint], statistics: ChartStatistics) {
        self.metric = metric
        self.period = period
        self.unit = unit
        self.points = points
        self.statistics = statistics
    }
}
