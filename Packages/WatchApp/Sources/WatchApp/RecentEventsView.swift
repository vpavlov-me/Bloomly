import Content
import SwiftUI
import Tracking

public struct RecentEventsView: View {
    @Environment(\.eventsRepository)
    private var eventsRepository
    @State private var events: [EventDTO] = []

    public init() {}

    public var body: some View {
        List(events, id: \.id) { event in
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(event.kind.titleKey))
                    .font(.headline)
                Text(timeRange(for: event))
                    .font(.footnote)
            }
        }
        .navigationTitle(Text(AppCopy.WatchApp.recentTitle))
        .task { await load() }
    }

    private func load() async {
        do {
            let interval = DateInterval(start: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), end: Date())
            let all = try await eventsRepository.events(in: interval, kind: nil)
            await MainActor.run {
                events = Array(all.prefix(10))
            }
        } catch {
            await MainActor.run { events = [] }
        }
    }

    private func timeRange(for event: EventDTO) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: event.start)
        if let end = event.end {
            return "\(start) – \(formatter.string(from: end))"
        }
        return start
    }
}
