import SwiftUI
import WidgetKit

// MARK: - Widget Bundle

public struct BloomlyWidgets: WidgetBundle {
    public init() {}

    public var body: some Widget {
        SmallWidget()
        MediumWidget()
        LargeWidget()
    }
}

// MARK: - Small Widget (Last Feed)

public struct SmallWidget: Widget {
    let kind: String = "SmallWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmallWidgetProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Last Feed")
        .description("Time since last feeding")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallWidgetEntry {
        SmallWidgetEntry(date: Date(), timeSinceLastFeed: "2h 30m", lastFeedType: "Bottle")
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallWidgetEntry) -> Void) {
        let entry = SmallWidgetEntry(date: Date(), timeSinceLastFeed: "2h 30m", lastFeedType: "Bottle")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallWidgetEntry>) -> Void) {
        Task {
            let data = await WidgetDataManager.shared.fetchLastFeedData()
            let entry = SmallWidgetEntry(
                date: Date(),
                timeSinceLastFeed: data.timeSince,
                lastFeedType: data.feedType
            )

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct SmallWidgetEntry: TimelineEntry {
    let date: Date
    let timeSinceLastFeed: String
    let lastFeedType: String
}

struct SmallWidgetView: View {
    let entry: SmallWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)

                Text(entry.timeSinceLastFeed)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(entry.lastFeedType)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget (Summary)

public struct MediumWidget: Widget {
    let kind: String = "MediumWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Activity Summary")
        .description("Quick overview of today's activities")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediumWidgetEntry {
        MediumWidgetEntry(
            date: Date(),
            lastFeed: "2h 30m",
            lastSleep: "1h 15m",
            lastDiaper: "45m"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MediumWidgetEntry) -> Void) {
        let entry = MediumWidgetEntry(
            date: Date(),
            lastFeed: "2h 30m",
            lastSleep: "1h 15m",
            lastDiaper: "45m"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediumWidgetEntry>) -> Void) {
        Task {
            let data = await WidgetDataManager.shared.fetchSummaryData()
            let entry = MediumWidgetEntry(
                date: Date(),
                lastFeed: data.lastFeed,
                lastSleep: data.lastSleep,
                lastDiaper: data.lastDiaper
            )

            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct MediumWidgetEntry: TimelineEntry {
    let date: Date
    let lastFeed: String
    let lastSleep: String
    let lastDiaper: String
}

struct MediumWidgetView: View {
    let entry: MediumWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            HStack(spacing: 0) {
                ActivityItem(
                    icon: "drop.fill",
                    color: .blue,
                    label: "Feed",
                    time: entry.lastFeed
                )

                Divider()
                    .padding(.vertical, 8)

                ActivityItem(
                    icon: "moon.fill",
                    color: .purple,
                    label: "Sleep",
                    time: entry.lastSleep
                )

                Divider()
                    .padding(.vertical, 8)

                ActivityItem(
                    icon: "humidity.fill",
                    color: .orange,
                    label: "Diaper",
                    time: entry.lastDiaper
                )
            }
            .padding()
        }
    }
}

struct ActivityItem: View {
    let icon: String
    let color: Color
    let label: String
    let time: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(time)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Large Widget (Timeline)

public struct LargeWidget: Widget {
    let kind: String = "LargeWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LargeWidgetProvider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Timeline")
        .description("View recent events and daily stats")
        .supportedFamilies([.systemLarge])
    }
}

struct LargeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LargeWidgetEntry {
        LargeWidgetEntry(
            date: Date(),
            totalFeeds: 8,
            totalDiapers: 6,
            totalSleepHours: 12.5,
            recentEvents: [
                RecentEvent(icon: "drop.fill", time: "2h ago", description: "Bottle feed"),
                RecentEvent(icon: "moon.fill", time: "4h ago", description: "Nap (1.5h)"),
                RecentEvent(icon: "humidity.fill", time: "5h ago", description: "Diaper change")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LargeWidgetEntry) -> Void) {
        let entry = LargeWidgetEntry(
            date: Date(),
            totalFeeds: 8,
            totalDiapers: 6,
            totalSleepHours: 12.5,
            recentEvents: [
                RecentEvent(icon: "drop.fill", time: "2h ago", description: "Bottle feed"),
                RecentEvent(icon: "moon.fill", time: "4h ago", description: "Nap (1.5h)")
            ]
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LargeWidgetEntry>) -> Void) {
        Task {
            let data = await WidgetDataManager.shared.fetchTimelineData()
            let entry = LargeWidgetEntry(
                date: Date(),
                totalFeeds: data.totalFeeds,
                totalDiapers: data.totalDiapers,
                totalSleepHours: data.totalSleepHours,
                recentEvents: data.recentEvents
            )

            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct LargeWidgetEntry: TimelineEntry {
    let date: Date
    let totalFeeds: Int
    let totalDiapers: Int
    let totalSleepHours: Double
    let recentEvents: [RecentEvent]
}

public struct RecentEvent {
    public let icon: String
    public let time: String
    public let description: String

    public init(icon: String, time: String, description: String) {
        self.icon = icon
        self.time = time
        self.description = description
    }
}

struct LargeWidgetView: View {
    let entry: LargeWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(alignment: .leading, spacing: 12) {
                // Header with stats
                HStack(spacing: 16) {
                    StatBadge(icon: "drop.fill", value: "\(entry.totalFeeds)", color: .blue)
                    StatBadge(icon: "humidity.fill", value: "\(entry.totalDiapers)", color: .orange)
                    StatBadge(icon: "moon.fill", value: String(format: "%.1fh", entry.totalSleepHours), color: .purple)
                }

                Divider()

                // Recent events
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Activity")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(entry.recentEvents.indices, id: \.self) { index in
                        let event = entry.recentEvents[index]
                        HStack(spacing: 8) {
                            Image(systemName: event.icon)
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .frame(width: 20)

                            Text(event.time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 50, alignment: .leading)

                            Text(event.description)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                    }
                }

                Spacer()

                Text("Tap to view timeline")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}
