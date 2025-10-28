import Foundation

public enum ChartAggregationError: Error {
    case invalidRange
}

/// Aggregates event data into chart-friendly series with caching.
public actor ChartDataAggregator {
    public let eventsRepository: any EventsRepository
    private let calendar: Calendar
    private let cacheTTL: TimeInterval
    private let maximumCacheEntries: Int

    private var cache: [CacheKey: CacheEntry] = [:]
    private var lruKeys: [CacheKey] = []

    public init(
        eventsRepository: any EventsRepository,
        calendar: Calendar = .current,
        cacheTTL: TimeInterval = 120,
        maximumCacheEntries: Int = 20
    ) {
        self.eventsRepository = eventsRepository
        self.calendar = calendar
        self.cacheTTL = cacheTTL
        self.maximumCacheEntries = maximumCacheEntries
    }

    /// Returns a chart-ready series for the selected metric/period within the provided date range.
    public func series(
        for metric: ChartMetric,
        in range: DateInterval,
        period: AggregationPeriod
    ) async throws -> ChartSeries {
        guard range.end > range.start else {
            throw ChartAggregationError.invalidRange
        }

        let key = CacheKey(metric: metric, period: period, range: range)
        if let cached = cachedSeries(for: key) {
            return cached
        }

        let buckets = makeBuckets(for: range, period: period)
        guard !buckets.isEmpty else {
            let empty = ChartSeries(
                metric: metric,
                period: period,
                unit: metric.unit,
                points: [],
                statistics: ChartStatistics(total: 0, average: 0, minimum: 0, maximum: 0, sampleCount: 0)
            )
            cacheSeries(empty, for: key)
            return empty
        }

        let events = try await fetchEvents(for: metric, in: range)
        let aggregated: AggregatedSeries

        switch metric {
        case .sleepTotal:
            aggregated = aggregateSleep(events: events, buckets: buckets, range: range)
        case .feedAverageDuration:
            aggregated = aggregateFeedAverage(events: events, buckets: buckets, range: range)
        case .feedFrequency:
            aggregated = aggregateFrequency(events: events, buckets: buckets, range: range, kind: .feeding)
        case .diaperFrequency:
            aggregated = aggregateFrequency(events: events, buckets: buckets, range: range, kind: .diaper)
        }

        let statistics = makeStatistics(for: metric, aggregated: aggregated)
        let series = ChartSeries(
            metric: metric,
            period: period,
            unit: metric.unit,
            points: aggregated.points,
            statistics: statistics
        )

        cacheSeries(series, for: key)
        return series
    }

    /// Removes all cached values, forcing a fresh aggregation on the next request.
    public func invalidateCache(metric: ChartMetric? = nil) {
        guard let metric else {
            cache.removeAll()
            lruKeys.removeAll()
            return
        }

        let keysToRemove = cache.keys.filter { $0.metric == metric }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        lruKeys.removeAll { keysToRemove.contains($0) }
    }

    // MARK: - Fetching

    private func fetchEvents(for metric: ChartMetric, in range: DateInterval) async throws -> [EventDTO] {
        let interval = fetchInterval(for: metric, range: range)
        let events = try await eventsRepository.events(in: interval, kind: metric.eventKind)
        return events.sorted { $0.start < $1.start }
    }

    private func fetchInterval(for metric: ChartMetric, range: DateInterval) -> DateInterval {
        switch metric {
        case .sleepTotal:
            let startBuffer = calendar.date(byAdding: .day, value: -1, to: range.start) ?? range.start
            return DateInterval(start: startBuffer, end: range.end)
        case .feedAverageDuration, .feedFrequency, .diaperFrequency:
            return range
        }
    }

    // MARK: - Aggregation

    private func aggregateSleep(
        events: [EventDTO],
        buckets: [DateInterval],
        range: DateInterval
    ) -> AggregatedSeries {
        guard !events.isEmpty else {
            return AggregatedSeries(points: buckets.map { ChartDataPoint(interval: $0, value: 0, sampleCount: 0) }, totalValue: 0, sampleCount: 0)
        }

        var bucketTotals = Array(repeating: 0.0, count: buckets.count)
        var bucketCounts = Array(repeating: 0, count: buckets.count)
        var totalEventCount = 0
        let now = Date()

        for event in events where event.kind == .sleep {
            let eventEnd = event.end ?? now
            if eventEnd <= range.start || event.start >= range.end {
                continue
            }

            totalEventCount += 1

            let adjustedStart = max(event.start, range.start)
            let adjustedEnd = min(eventEnd, range.end)
            if adjustedEnd <= adjustedStart {
                continue
            }

            for (index, bucket) in buckets.enumerated() {
                if bucket.end <= adjustedStart {
                    continue
                }
                if bucket.start >= adjustedEnd {
                    break
                }
                let segmentStart = max(adjustedStart, bucket.start)
                let segmentEnd = min(adjustedEnd, bucket.end)
                if segmentEnd <= segmentStart {
                    continue
                }

                let durationHours = segmentEnd.timeIntervalSince(segmentStart) / 3600.0
                bucketTotals[index] += durationHours
                bucketCounts[index] += 1
            }
        }

        let points = zip(buckets, zip(bucketTotals, bucketCounts)).map { bucket, totals -> ChartDataPoint in
            ChartDataPoint(interval: bucket, value: totals.0, sampleCount: totals.1)
        }

        return AggregatedSeries(
            points: points,
            totalValue: bucketTotals.reduce(0, +),
            sampleCount: totalEventCount
        )
    }

    private func aggregateFeedAverage(
        events: [EventDTO],
        buckets: [DateInterval],
        range: DateInterval
    ) -> AggregatedSeries {
        var bucketTotals = Array(repeating: 0.0, count: buckets.count)
        var bucketCounts = Array(repeating: 0, count: buckets.count)
        var totalDuration = 0.0
        var totalSamples = 0

        for event in events where event.kind == .feeding {
            guard event.start >= range.start && event.start < range.end else {
                continue
            }
            guard let bucketIndex = index(containing: event.start, buckets: buckets) else {
                continue
            }
            let duration = max(0, (event.end ?? event.start).timeIntervalSince(event.start))
            let minutes = duration / 60.0
            bucketTotals[bucketIndex] += minutes
            bucketCounts[bucketIndex] += 1
            totalDuration += minutes
            totalSamples += 1
        }

        let points = zip(buckets, zip(bucketTotals, bucketCounts)).map { bucket, entry -> ChartDataPoint in
            let total = entry.0
            let count = entry.1
            let average = count > 0 ? total / Double(count) : 0
            return ChartDataPoint(interval: bucket, value: average, sampleCount: count)
        }

        return AggregatedSeries(points: points, totalValue: totalDuration, sampleCount: totalSamples)
    }

    private func aggregateFrequency(
        events: [EventDTO],
        buckets: [DateInterval],
        range: DateInterval,
        kind: EventKind
    ) -> AggregatedSeries {
        var bucketCounts = Array(repeating: 0, count: buckets.count)
        var totalCount = 0

        for event in events where event.kind == kind {
            guard event.start >= range.start && event.start < range.end else {
                continue
            }
            guard let bucketIndex = index(containing: event.start, buckets: buckets) else {
                continue
            }
            bucketCounts[bucketIndex] += 1
            totalCount += 1
        }

        let points = zip(buckets, bucketCounts).map { bucket, count in
            ChartDataPoint(interval: bucket, value: Double(count), sampleCount: count)
        }

        return AggregatedSeries(points: points, totalValue: Double(totalCount), sampleCount: totalCount)
    }

    // MARK: - Statistics

    private func makeStatistics(for metric: ChartMetric, aggregated: AggregatedSeries) -> ChartStatistics {
        let nonEmptyPoints = aggregated.points.filter { $0.sampleCount > 0 }
        let minValue = nonEmptyPoints.map(\.value).min() ?? 0
        let maxValue = nonEmptyPoints.map(\.value).max() ?? 0
        let average: Double

        switch metric {
        case .feedAverageDuration:
            let divisor = Double(aggregated.sampleCount)
            average = divisor > 0 ? aggregated.totalValue / divisor : 0
        case .sleepTotal, .feedFrequency, .diaperFrequency:
            let divisor = Double(nonEmptyPoints.count)
            average = divisor > 0 ? aggregated.totalValue / divisor : 0
        }

        return ChartStatistics(
            total: aggregated.totalValue,
            average: average,
            minimum: minValue,
            maximum: maxValue,
            sampleCount: aggregated.sampleCount
        )
    }

    // MARK: - Buckets

    private func makeBuckets(for range: DateInterval, period: AggregationPeriod) -> [DateInterval] {
        var buckets: [DateInterval] = []
        var currentStart = alignedStart(for: range.start, period: period)

        if currentStart > range.start {
            if let previous = calendar.date(byAdding: calendarComponent(for: period), value: -1, to: currentStart) {
                currentStart = previous
            }
        }

        while currentStart < range.end {
            guard let next = calendar.date(byAdding: calendarComponent(for: period), value: 1, to: currentStart) else {
                break
            }
            let bucketEnd = min(next, range.end)
            buckets.append(DateInterval(start: currentStart, end: bucketEnd))
            currentStart = next
        }

        return buckets
    }

    private func alignedStart(for date: Date, period: AggregationPeriod) -> Date {
        switch period {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        case .month:
            return calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    private func calendarComponent(for period: AggregationPeriod) -> Calendar.Component {
        switch period {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        }
    }

    private func index(containing date: Date, buckets: [DateInterval]) -> Int? {
        for (index, bucket) in buckets.enumerated() {
            if date >= bucket.start && date < bucket.end {
                return index
            }
        }
        return nil
    }

    // MARK: - Caching helpers

    private func cachedSeries(for key: CacheKey) -> ChartSeries? {
        guard cacheTTL > 0, let entry = cache[key] else {
            return nil
        }

        if Date().timeIntervalSince(entry.createdAt) > cacheTTL {
            cache.removeValue(forKey: key)
            lruKeys.removeAll { $0 == key }
            return nil
        }

        promoteKey(key)
        return entry.series
    }

    private func cacheSeries(_ series: ChartSeries, for key: CacheKey) {
        guard cacheTTL > 0 else { return }
        cache[key] = CacheEntry(series: series, createdAt: Date())
        promoteKey(key)
        trimCacheIfNeeded()
    }

    private func promoteKey(_ key: CacheKey) {
        lruKeys.removeAll { $0 == key }
        lruKeys.append(key)
    }

    private func trimCacheIfNeeded() {
        while cache.count > maximumCacheEntries, let key = lruKeys.first {
            cache.removeValue(forKey: key)
            lruKeys.removeFirst()
        }
    }

    // MARK: - Nested types

    private struct CacheKey: Hashable {
        let metric: ChartMetric
        let period: AggregationPeriod
        let start: TimeInterval
        let end: TimeInterval

        init(metric: ChartMetric, period: AggregationPeriod, range: DateInterval) {
            self.metric = metric
            self.period = period
            self.start = range.start.timeIntervalSinceReferenceDate
            self.end = range.end.timeIntervalSinceReferenceDate
        }
    }

    private struct CacheEntry {
        let series: ChartSeries
        let createdAt: Date
    }

    private struct AggregatedSeries {
        let points: [ChartDataPoint]
        let totalValue: Double
        let sampleCount: Int
    }
}

private extension ChartMetric {
    var eventKind: EventKind? {
        switch self {
        case .sleepTotal:
            return .sleep
        case .feedAverageDuration, .feedFrequency:
            return .feeding
        case .diaperFrequency:
            return .diaper
        }
    }
}
