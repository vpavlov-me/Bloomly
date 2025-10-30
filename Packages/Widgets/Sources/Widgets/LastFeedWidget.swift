import Content
import SwiftUI
import WidgetKit

struct LastFeedEntry: TimelineEntry {
    let date: Date
    let lastFeed: Date?
}

struct LastFeedProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.vibecoding.bloomly")

    func placeholder(in context: Context) -> LastFeedEntry {
        LastFeedEntry(date: Date(), lastFeed: Date().addingTimeInterval(-3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (LastFeedEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastFeedEntry>) -> Void) {
        let entry = loadEntry()
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadEntry() -> LastFeedEntry {
        let timestamp = userDefaults?.object(forKey: "lastFeedDate") as? Date
        return LastFeedEntry(date: Date(), lastFeed: timestamp)
    }
}

struct LastFeedWidgetEntryView: View {
    var entry: LastFeedProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(colors: [.pink.opacity(0.8), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 8) {
                Label(AppCopy.string(for: "event.kind.feed"), systemImage: Symbols.feed)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let lastFeed = entry.lastFeed {
                    Text(lastFeed, style: .time)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(relativeString(from: lastFeed))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text(AppCopy.string(for: "timeline.empty.action"))
                        .font(.footnote)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func relativeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LastFeedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LastFeedWidget", provider: LastFeedProvider()) { entry in
            LastFeedWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName(AppCopy.string(for: "event.kind.feed"))
        .description(AppCopy.string(for: "timeline.search.scope.feed"))
    }
}

#if DEBUG
struct LastFeedWidget_Previews: PreviewProvider {
    static var previews: some View {
        LastFeedWidgetEntryView(entry: LastFeedEntry(date: Date(), lastFeed: Date().addingTimeInterval(-5400)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
