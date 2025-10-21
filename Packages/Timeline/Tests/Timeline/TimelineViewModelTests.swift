import XCTest
import Tracking
import Measurements
@testable import Timeline

final class TimelineViewModelTests: XCTestCase {
    func testRefreshBuildsSections() async throws {
        let eventsRepo = InMemoryEventsRepository()
        let measurementsRepo = StubMeasurementsRepository()
        let viewModel = await MainActor.run { TimelineViewModel(eventsRepository: eventsRepo, measurementsRepository: measurementsRepo) }

        let draft = EventDraft(kind: .feed, start: Date())
        _ = try await eventsRepo.save(draft: draft)
        await MainActor.run { viewModel.refresh() }
        try? await Task.sleep(nanoseconds: 50_000_000)
        await MainActor.run {
            XCTAssertFalse(viewModel.sections.isEmpty)
        }
    }
}

private final class StubMeasurementsRepository: MeasurementsRepository {
    func measurementsStream(for type: MeasurementType) -> AsyncStream<[MeasurementSample]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func fetchMeasurements(for type: MeasurementType, limit: Int?) async throws -> [MeasurementSample] {
        []
    }

    func save(draft: MeasurementDraft) async throws -> MeasurementSample {
        MeasurementSample(id: UUID(), type: draft.type, value: draft.value, unit: draft.unit, date: draft.date, isSynced: false)
    }

    func delete(id: UUID) async throws {}
}
