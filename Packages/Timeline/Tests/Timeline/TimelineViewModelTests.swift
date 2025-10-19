import XCTest
import Tracking
import Measurements
@testable import Timeline

final class TimelineViewModelTests: XCTestCase {
    func testReloadCombinesEntries() async {
        let event = Event(
            id: UUID(),
            kind: .sleep,
            start: Date(),
            end: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isSynced: false
        )
        let measurement = MeasurementSample(
            id: UUID(),
            type: .weight,
            value: 5.0,
            unit: "kg",
            date: Date(),
            isSynced: false
        )
        let repo = StubEventsRepository(events: [event])
        let measurementsRepo = StubMeasurementsRepository(samples: [measurement])
        let viewModel = TimelineViewModel(eventsRepository: repo, measurementsRepository: measurementsRepo)
        await viewModel.reload()
        XCTAssertEqual(viewModel.entries.count, 2)
    }

    private struct StubEventsRepository: EventsRepository {
        let events: [Event]
        func events(in range: ClosedRange<Date>?, of kind: EventKind?) async throws -> [Event] { events }
        func upsert(_ event: EventInput) async throws {}
        func delete(id: UUID) async throws {}
    }

    private struct StubMeasurementsRepository: MeasurementsRepository {
        let samples: [MeasurementSample]
        func measurements(of type: MeasurementType) async throws -> [MeasurementSample] {
            samples.filter { $0.type == type }
        }
        func upsert(_ measurement: MeasurementInput) async throws {}
        func delete(id: UUID) async throws {}
    }
}
