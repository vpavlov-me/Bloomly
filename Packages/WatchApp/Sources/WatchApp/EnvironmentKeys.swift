import AppSupport
import Measurements
import SwiftUI
import Tracking

// MARK: - Environment keys for WatchApp

private struct EventsRepositoryKey: EnvironmentKey {
    static let defaultValue: any EventsRepository = NullEventsRepository()
}

private struct MeasurementsRepositoryKey: EnvironmentKey {
    static let defaultValue: any MeasurementsRepository = NullMeasurementsRepository()
}

private struct AnalyticsKey: EnvironmentKey {
    static let defaultValue: any Analytics = AnalyticsLogger()
}

public extension EnvironmentValues {
    var eventsRepository: any EventsRepository {
        get { self[EventsRepositoryKey.self] }
        set { self[EventsRepositoryKey.self] = newValue }
    }

    var measurementsRepository: any MeasurementsRepository {
        get { self[MeasurementsRepositoryKey.self] }
        set { self[MeasurementsRepositoryKey.self] = newValue }
    }

    var analytics: any Analytics {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }
}

// MARK: - Null objects

private struct NullEventsRepository: EventsRepository {
    func create(_ dto: EventDTO) async throws -> EventDTO { fatalError("EventsRepository not provided") }
    func update(_ dto: EventDTO) async throws -> EventDTO { fatalError("EventsRepository not provided") }
    func delete(id: UUID) async throws { fatalError("EventsRepository not provided") }
    func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] { fatalError("EventsRepository not provided") }
    func lastEvent(for kind: EventKind) async throws -> EventDTO? { fatalError("EventsRepository not provided") }
    func stats(for day: Date) async throws -> EventDayStats { fatalError("EventsRepository not provided") }
}

private struct NullMeasurementsRepository: MeasurementsRepository {
    func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO { fatalError("MeasurementsRepository not provided") }
    func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO { fatalError("MeasurementsRepository not provided") }
    func delete(id: UUID) async throws { fatalError("MeasurementsRepository not provided") }
    func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] { fatalError("MeasurementsRepository not provided") }
}
