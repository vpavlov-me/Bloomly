import XCTest
import SwiftUI
import SnapshotTesting
import Tracking
import Measurements
@testable import Timeline

final class TimelineSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    #if os(iOS)
    // MARK: - Basic Timeline Tests

    func testTimelineWithData() async throws {
        let now = Date()
        let events = [
            Event(
                id: UUID(),
                kind: .sleep,
                start: now.addingTimeInterval(-7200),
                end: now.addingTimeInterval(-3600),
                notes: "Good sleep",
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-3600),
                isSynced: false
            ),
            Event(
                id: UUID(),
                kind: .feeding,
                start: now.addingTimeInterval(-1200),
                end: nil,
                notes: "120ml",
                createdAt: now.addingTimeInterval(-1200),
                updatedAt: now.addingTimeInterval(-1200),
                isSynced: false
            )
        ]
        let measurements = [
            MeasurementSample(
                id: UUID(),
                type: .weight,
                value: 6.2,
                unit: "kg",
                date: now,
                isSynced: false
            )
        ]

        let viewModel = TimelineViewModel(
            eventsRepository: StubEventsRepository(events: events),
            measurementsRepository: StubMeasurementsRepository(samples: measurements)
        )
        await viewModel.reload()
        let view = TimelineView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testTimelineEmptyState() async throws {
        let viewModel = TimelineViewModel(
            eventsRepository: StubEventsRepository(events: []),
            measurementsRepository: StubMeasurementsRepository(samples: [])
        )
        await viewModel.reload()
        let view = TimelineView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testTimelineDarkMode() async throws {
        let now = Date()
        let events = [
            Event(
                id: UUID(),
                kind: .sleep,
                start: now.addingTimeInterval(-7200),
                end: now.addingTimeInterval(-3600),
                notes: "Night sleep",
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-3600),
                isSynced: false
            ),
            Event(
                id: UUID(),
                kind: .diaper,
                start: now.addingTimeInterval(-1800),
                end: now.addingTimeInterval(-1795),
                notes: "Wet",
                createdAt: now.addingTimeInterval(-1800),
                updatedAt: now.addingTimeInterval(-1795),
                isSynced: false
            )
        ]

        let viewModel = TimelineViewModel(
            eventsRepository: StubEventsRepository(events: events),
            measurementsRepository: StubMeasurementsRepository(samples: [])
        )
        await viewModel.reload()
        let view = TimelineView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - Device Size Variants

    func testTimelineiPhoneSE() async throws {
        let now = Date()
        let events = [
            Event(
                id: UUID(),
                kind: .feeding,
                start: now.addingTimeInterval(-1200),
                end: nil,
                notes: "120ml",
                createdAt: now.addingTimeInterval(-1200),
                updatedAt: now.addingTimeInterval(-1200),
                isSynced: false
            )
        ]

        let viewModel = TimelineViewModel(
            eventsRepository: StubEventsRepository(events: events),
            measurementsRepository: StubMeasurementsRepository(samples: [])
        )
        await viewModel.reload()
        let view = TimelineView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }

    func testTimelineiPhone15ProMax() async throws {
        let now = Date()
        let events = [
            Event(
                id: UUID(),
                kind: .feeding,
                start: now.addingTimeInterval(-1200),
                end: nil,
                notes: "120ml",
                createdAt: now.addingTimeInterval(-1200),
                updatedAt: now.addingTimeInterval(-1200),
                isSynced: false
            )
        ]

        let viewModel = TimelineViewModel(
            eventsRepository: StubEventsRepository(events: events),
            measurementsRepository: StubMeasurementsRepository(samples: [])
        )
        await viewModel.reload()
        let view = TimelineView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone15ProMax)))
    }
    #endif

    // MARK: - Helper Methods

    private func referenceExists(for testName: String) -> Bool {
        let testClass = String(describing: type(of: self))
        let snapshotsPath = "__Snapshots__/\(testClass)/\(testName).png"
        return FileManager.default.fileExists(atPath: snapshotsPath)
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
