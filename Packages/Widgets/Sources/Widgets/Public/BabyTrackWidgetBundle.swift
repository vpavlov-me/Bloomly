//
//  BabyTrackWidgetBundle.swift
//  BabyTrack
//
//  Provides widgets for recent feeds and sleep summary.
//

import SwiftUI
import WidgetKit
import Timeline
import Tracking
import Measurements
import Content

public struct LastFeedEntry: TimelineEntry {
    public let date: Date
    public let title: String
}

public struct SleepSummaryEntry: TimelineEntry {
    public let date: Date
    public let totalSleep: TimeInterval
}

public struct LastFeedProvider: TimelineProvider {
    private let provider = WidgetDataProvider()

    public init() {}

    public func placeholder(in context: Context) -> LastFeedEntry {
        LastFeedEntry(date: Date(), title: "2h ago")
    }

    public func getSnapshot(in context: Context, completion: @escaping (LastFeedEntry) -> Void) {
        completion(makeEntry())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LastFeedEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }

    private func makeEntry() -> LastFeedEntry {
        let summary = provider.lastFeedSummary()
        return LastFeedEntry(date: Date(), title: summary)
    }
}

public struct SleepSummaryProvider: TimelineProvider {
    private let provider = WidgetDataProvider()

    public init() {}

    public func placeholder(in context: Context) -> SleepSummaryEntry {
        SleepSummaryEntry(date: Date(), totalSleep: 3 * 3600)
    }

    public func getSnapshot(in context: Context, completion: @escaping (SleepSummaryEntry) -> Void) {
        completion(makeEntry())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<SleepSummaryEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .after(Date().addingTimeInterval(3600))))
    }

    private func makeEntry() -> SleepSummaryEntry {
        SleepSummaryEntry(date: Date(), totalSleep: provider.todaySleepDuration())
    }
}

public struct LastFeedWidget: Widget {
    public let kind = "LastFeedWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastFeedProvider()) { entry in
            VStack(alignment: .leading) {
                Text(L10n.widgetsLastFeed())
                    .font(.headline)
                Text(entry.title)
                    .font(.title3)
            }
            .padding()
        }
        .configurationDisplayName(L10n.widgetsLastFeed())
        .description("Shows the time since the last feed event.")
    }
}

public struct SleepSummaryWidget: Widget {
    public let kind = "SleepSummaryWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepSummaryProvider()) { entry in
            VStack(alignment: .leading) {
                Text(L10n.widgetsSleepSummary())
                    .font(.headline)
                Text(SleepSummaryFormatter.format(duration: entry.totalSleep))
                    .font(.title3)
            }
            .padding()
        }
        .configurationDisplayName(L10n.widgetsSleepSummary())
        .description("Displays today's total sleep duration.")
    }
}

public struct BabyTrackWidgets: WidgetBundle {
    public init() {}

    public var body: some Widget {
        LastFeedWidget()
        SleepSummaryWidget()
    }
}

enum SleepSummaryFormatter {
    static func format(duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
