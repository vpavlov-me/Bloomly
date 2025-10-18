import XCTest
import SwiftUI
import SnapshotTesting
import Tracking
import Measurements
@testable import Timeline

final class TimelineSnapshotTests: XCTestCase {
    #if os(iOS)
    func testTimelineSnapshot() async {
        let events = [
            Event(
                id: UUID(),
                kind: .feed,
                start: Date().addingTimeInterval(-1200),
                end: nil,
                notes: "120ml",
                createdAt: Date(),
                updatedAt: Date(),
                isSynced: false
            )
        ]
        let measurements = [
            MeasurementSample(
                id: UUID(),
                type: .weight,
                value: 6.2,
                unit: "kg",
                date: Date(),
                isSynced: false
            )
        ]
        let viewModel = TimelineViewModel(eventsRepository: StubEventsRepository(events: events), measurementsRepository: StubMeasurementsRepository(samples: measurements))
        await viewModel.reload()
        let view = TimelineView(viewModel: viewModel)
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }
    #endif

    private struct StubEventsRepository: EventsRepository {
        let events: [Event]
        func events(in range: ClosedRange<Date>?, of kind: EventKind?) async throws -> [Event] { events }
        func upsert(_ event: EventInput) async throws {}
        func delete(id: UUID) async throws {}
    }

    private struct StubMeasurementsRepository: MeasurementsRepository {
        let samples: [MeasurementSample]
        func measurements(of type: MeasurementType) async throws -> [MeasurementSample] { samples }
        func upsert(_ measurement: MeasurementInput) async throws {}
        func delete(id: UUID) async throws {}
    }
}
