import SwiftUI
import WatchApp
import Tracking

@main
struct BabyTrackWatchExtensionApp: App {
    @State private var events: [Event] = Preview.events

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(events: events) { kind in
                let newEvent = Event(
                    id: UUID(),
                    kind: kind,
                    start: Date(),
                    end: nil,
                    notes: nil,
                    createdAt: Date(),
                    updatedAt: Date(),
                    isSynced: false
                )
                events.insert(newEvent, at: 0)
            }
        }
    }
}

private enum Preview {
    static let events: [Event] = [
        Event(
            id: UUID(),
            kind: .feed,
            start: Date().addingTimeInterval(-900),
            end: nil,
            notes: "Watch log",
            createdAt: Date(),
            updatedAt: Date(),
            isSynced: false
        )
    ]
}
