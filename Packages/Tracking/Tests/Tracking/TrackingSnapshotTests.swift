import XCTest
import SwiftUI
import SnapshotTesting
import AppSupport
@testable import Tracking

@MainActor
final class TrackingSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    // MARK: - Sleep Tracking Tests

    func testSleepTrackingViewInitial() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = SleepTrackingViewModel(repository: repository)

        let view = SleepTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testSleepTrackingViewInitialDarkMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = SleepTrackingViewModel(repository: repository)

        let view = SleepTrackingView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - Feeding Tracking Tests

    func testFeedingTrackingViewInitial() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = FeedingTrackingViewModel(repository: repository)

        let view = FeedingTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testFeedingTrackingViewBreastMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = FeedingTrackingViewModel(repository: repository)
        // Set to breast mode
        viewModel.feedingType = .breast

        let view = FeedingTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testFeedingTrackingViewBottleMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = FeedingTrackingViewModel(repository: repository)
        // Set to bottle mode
        viewModel.feedingType = .bottle

        let view = FeedingTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testFeedingTrackingViewDarkMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = FeedingTrackingViewModel(repository: repository)

        let view = FeedingTrackingView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - Diaper Tracking Tests

    func testDiaperTrackingViewInitial() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = DiaperTrackingViewModel(repository: repository)

        let view = DiaperTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testDiaperTrackingViewDarkMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = DiaperTrackingViewModel(repository: repository)

        let view = DiaperTrackingView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - Pumping Tracking Tests

    func testPumpingTrackingViewInitial() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = PumpingTrackingViewModel(repository: repository)

        let view = PumpingTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testPumpingTrackingViewDarkMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = PumpingTrackingViewModel(repository: repository)

        let view = PumpingTrackingView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - Device Size Variants

    func testSleepTrackingViewiPhoneSE() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = SleepTrackingViewModel(repository: repository)

        let view = SleepTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }

    func testSleepTrackingViewiPhone15ProMax() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = SleepTrackingViewModel(repository: repository)

        let view = SleepTrackingView(viewModel: viewModel)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone15ProMax)))
    }

    // MARK: - Helper Methods

    private func referenceExists(for testName: String) -> Bool {
        let testClass = String(describing: type(of: self))
        let snapshotsPath = "__Snapshots__/\(testClass)/\(testName).png"
        return FileManager.default.fileExists(atPath: snapshotsPath)
    }
}

// MARK: - Mock Implementations

private final class MockEventsRepository: EventsRepository {
    let events: [EventDTO]
    let lastEvents: [EventKind: EventDTO]

    init(events: [EventDTO], lastEvents: [EventKind: EventDTO]) {
        self.events = events
        self.lastEvents = lastEvents
    }

    func create(_ dto: EventDTO) async throws -> EventDTO {
        dto
    }

    func read(id: UUID) async throws -> EventDTO {
        guard let event = events.first(where: { $0.id == id }) else {
            throw EventsRepositoryError.notFound
        }
        return event
    }

    func update(_ dto: EventDTO) async throws -> EventDTO {
        dto
    }

    func delete(id: UUID) async throws {}

    func upsert(_ dto: EventDTO) async throws -> EventDTO {
        dto
    }

    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
        var filtered = events

        if let interval = interval {
            filtered = filtered.filter { event in
                event.start >= interval.start && event.start < interval.end
            }
        }

        if let kind = kind {
            filtered = filtered.filter { $0.kind == kind }
        }

        return filtered
    }

    func events(for babyID: UUID, in interval: DateInterval?) async throws -> [EventDTO] {
        events
    }

    func lastEvent(for kind: EventKind) async throws -> EventDTO? {
        lastEvents[kind]
    }

    func stats(for day: Date) async throws -> EventDayStats {
        EventDayStats(date: day, totalEvents: events.count, totalDuration: 7200)
    }

    func batchCreate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        dtos
    }

    func batchUpdate(_ dtos: [EventDTO]) async throws -> [EventDTO] {
        dtos
    }
}
