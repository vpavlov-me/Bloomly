import Content
import SwiftUI
import WidgetKit

struct TodaySleepEntry: TimelineEntry {
    let date: Date
    let totalMinutes: Int
}

struct TodaySleepProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.vibecoding.bloomly")

    func placeholder(in context: Context) -> TodaySleepEntry {
        TodaySleepEntry(date: Date(), totalMinutes: 480)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySleepEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySleepEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date().addingTimeInterval(7200)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> TodaySleepEntry {
        let minutes = userDefaults?.integer(forKey: "todaySleepMinutes") ?? 0
        return TodaySleepEntry(date: Date(), totalMinutes: minutes)
    }
}

struct TodaySleepWidgetEntryView: View {
    let entry: TodaySleepProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.8), .indigo.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 6) {
                Label(AppCopy.string(for: "event.kind.sleep"), systemImage: Symbols.sleep)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(hoursString)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(AppCopy.string(for: "timeline.section.today"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private var hoursString: String {
        let hours = entry.totalMinutes / 60
        let minutes = entry.totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

struct TodaySleepWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodaySleepWidget", provider: TodaySleepProvider()) { entry in
            TodaySleepWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName(AppCopy.string(for: "event.kind.sleep"))
        .description(AppCopy.string(for: "timeline.search.scope.sleep"))
    }
}

#if DEBUG
struct TodaySleepWidget_Previews: PreviewProvider {
    static var previews: some View {
        TodaySleepWidgetEntryView(entry: TodaySleepEntry(date: Date(), totalMinutes: 390))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
