import SnapshotTesting
import SwiftUI
import XCTest
@testable import Content
@testable import DesignSystem
@testable import Timeline
@testable import Tracking
@testable import Measurements

final class TimelineViewTests: XCTestCase {
    private let isRecording = false // Set to true to record new snapshots.

    func testTimelineViewRendering() {
        let events = [
            EventDTO(kind: .sleep, start: Date().addingTimeInterval(-3600), end: Date().addingTimeInterval(-1800), notes: "Morning nap"),
            EventDTO(kind: .feed, start: Date().addingTimeInterval(-7200), end: Date().addingTimeInterval(-6900), notes: "Bottle")
        ]
        let measurements = [
            MeasurementDTO(type: .height, value: 62.4, unit: "cm", date: Date().addingTimeInterval(-86400))
        ]
        let viewModel = TimelineViewModel(eventsRepository: MockEventsRepository(events: events), measurementsRepository: MockMeasurementsRepository(measurements: measurements))
        viewModel.applyFilters()

        let view = TimelineView(viewModel: viewModel)
            .environment(\.eventsRepository, MockEventsRepository(events: events))
            .environment(\.measurementsRepository, MockMeasurementsRepository(measurements: measurements))
            .frame(width: 390, height: 844)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Mini)), record: isRecording)
    }
}

private final class MockEventsRepository: EventsRepository {
    private var storage: [EventDTO]

    init(events: [EventDTO]) {
        self.storage = events
    }

    func create(_ dto: EventDTO) async throws -> EventDTO {
        storage.append(dto)
        return dto
    }

    func update(_ dto: EventDTO) async throws -> EventDTO { dto }

    func delete(id: UUID) async throws {
        storage.removeAll { $0.id == id }
    }

    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        storage
    }

    func lastEvent(for kind: EventKind) async throws -> EventDTO? { storage.first { $0.kind == kind } }

    func stats(for day: Date) async throws -> EventDayStats {
        EventDayStats(date: day, totalEvents: storage.count, totalDuration: 0)
    }
}

private final class MockMeasurementsRepository: MeasurementsRepository {
    private var storage: [MeasurementDTO]

    init(measurements: [MeasurementDTO]) {
        self.storage = measurements
    }

    func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO {
        storage.append(dto)
        return dto
    }

    func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO { dto }

    func delete(id: UUID) async throws {
        storage.removeAll { $0.id == id }
    }

    func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] {
        storage
    }
}
