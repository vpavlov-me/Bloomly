import Content
import Measurements
import SwiftUI
import Tracking

public struct WatchRootView: View {
    @State private var selection = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selection) {
            QuickLogView()
                .tag(0)
                .tabItem { Label(AppCopy.WatchApp.tabLog, systemImage: Symbols.add) }
            RecentEventsView()
                .tag(1)
                .tabItem { Label(AppCopy.WatchApp.tabHistory, systemImage: Symbols.timeline) }
            AddMeasurementView()
                .tag(2)
                .tabItem { Label(AppCopy.WatchApp.tabMeasure, systemImage: Symbols.measurement) }
        }
    }
}

#if DEBUG
struct WatchRootView_Previews: PreviewProvider {
    static var previews: some View {
        WatchRootView()
            .environment(\.eventsRepository, PreviewEventsRepository())
            .environment(\.measurementsRepository, PreviewMeasurementsRepository())
    }

    private struct PreviewEventsRepository: EventsRepository {
        func create(_ dto: EventDTO) async throws -> EventDTO { dto }
        func update(_ dto: EventDTO) async throws -> EventDTO { dto }
        func delete(id: UUID) async throws {}
        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
            [EventDTO(kind: .sleep, start: Date(), end: Date().addingTimeInterval(1800))]
        }
        func lastEvent(for kind: EventKind) async throws -> EventDTO? { nil }
        func stats(for day: Date) async throws -> EventDayStats { .init(date: Date(), totalEvents: 0, totalDuration: 0) }
    }

    private struct PreviewMeasurementsRepository: MeasurementsRepository {
        func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO { dto }
        func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO { dto }
        func delete(id: UUID) async throws {}
        func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] { [] }
    }
}
#endif
