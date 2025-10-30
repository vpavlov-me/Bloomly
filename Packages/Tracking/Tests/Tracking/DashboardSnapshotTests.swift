import XCTest
import SwiftUI
import SnapshotTesting
import AppSupport
@testable import Tracking

@MainActor
final class DashboardSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    // MARK: - Empty State Tests

    func testDashboardEmptyState() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = DashboardViewModel(eventsRepository: repository)
        let analytics = MockAnalytics()

        let view = DashboardView(
            viewModel: viewModel,
            analytics: analytics,
            onQuickAction: { _ in }
        )

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testDashboardEmptyStateDarkMode() throws {
        let repository = MockEventsRepository(events: [], lastEvents: [:])
        let viewModel = DashboardViewModel(eventsRepository: repository)
        let analytics = MockAnalytics()

        let view = DashboardView(
            viewModel: viewModel,
            analytics: analytics,
            onQuickAction: { _ in }
        )
        .preferredColorScheme(.dark)

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - With Data Tests

    func testDashboardWithCompletedEvents() throws {
        let now = Date()
        let events = [
            EventDTO(
                kind: .sleep,
                start: now.addingTimeInterval(-7200),
                end: now.addingTimeInterval(-3600)
            ),
            EventDTO(
                kind: .feeding,
                start: now.addingTimeInterval(-5400),
                end: now.addingTimeInterval(-4800)
            ),
            EventDTO(
                kind: .diaper,
                start: now.addingTimeInterval(-1800),
                end: now.addingTimeInterval(-1795)
            ),
            EventDTO(
                kind: .pumping,
                start: now.addingTimeInterval(-9000),
                end: now.addingTimeInterval(-8400)
            )
        ]

        let lastEvents: [EventKind: EventDTO] = [
            .sleep: events[0],
            .feeding: events[1],
            .diaper: events[2],
            .pumping: events[3]
        ]

        let repository = MockEventsRepository(events: events, lastEvents: lastEvents)
        let viewModel = DashboardViewModel(eventsRepository: repository)
        let analytics = MockAnalytics()

        let view = DashboardView(
            viewModel: viewModel,
            analytics: analytics,
            onQuickAction: { _ in }
        )

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    func testDashboardWithActiveEvent() throws {
        let now = Date()
        let events = [
            EventDTO(
                kind: .sleep,
                start: now.addingTimeInterval(-3600),
                end: nil  // Ongoing event
            ),
            EventDTO(
                kind: .feeding,
                start: now.addingTimeInterval(-5400),
                end: now.addingTimeInterval(-4800)
            )
        ]

        let lastEvents: [EventKind: EventDTO] = [
            .sleep: events[0],
            .feeding: events[1]
        ]

        let repository = MockEventsRepository(events: events, lastEvents: lastEvents)
        let viewModel = DashboardViewModel(eventsRepository: repository)
        let analytics = MockAnalytics()

        let view = DashboardView(
            viewModel: viewModel,
            analytics: analytics,
            onQuickAction: { _ in }
        )

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    // MARK: - Device Size Tests

    func testDashboardiPhoneSE() throws {
        let now = Date()
        let events = [
            EventDTO(
                kind: .sleep,
                start: now.addingTimeInterval(-7200),
                end: now.addingTimeInterval(-3600)
            ),
            EventDTO(
                kind: .feeding,
                start: now.addingTimeInterval(-1800),
                end: now.addingTimeInterval(-1200)
            )
        ]

        let repository = MockEventsRepository(
            events: events,
            lastEvents: [.sleep: events[0], .feeding: events[1]]
        )
        let viewModel = DashboardViewModel(eventsRepository: repository)
        let analytics = MockAnalytics()

        let view = DashboardView(
            viewModel: viewModel,
            analytics: analytics,
            onQuickAction: { _ in }
        )

        if !isRecording {
            guard referenceExists(for: #function) else {
                throw XCTSkip("Snapshot missing, record with SNAPSHOT_RECORD=1")
            }
        }

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhoneSe)))
    }

    func testDashboardiPhone15ProMax() throws {
        let now = Date()
        let events = [
            EventDTO(
                kind: .sleep,
                start: now.addingTimeInterval(-7200),
                end: now.addingTimeInterval(-3600)
            ),
            EventDTO(
                kind: .feeding,
                start: now.addingTimeInterval(-1800),
                end: now.addingTimeInterval(-1200)
            )
        ]

        let repository = MockEventsRepository(
            events: events,
            lastEvents: [.sleep: events[0], .feeding: events[1]]
        )
        let viewModel = DashboardViewModel(eventsRepository: repository)
        let analytics = MockAnalytics()

        let view = DashboardView(
            viewModel: viewModel,
            analytics: analytics,
            onQuickAction: { _ in }
        )

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

private struct MockAnalytics: Analytics {
    func track(_ event: AnalyticsEvent) {}
    func setUserProperty(key: String, value: String) {}
    func identify(userId: String) {}
}
