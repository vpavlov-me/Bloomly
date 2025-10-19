//
//  TimelineViewModel.swift
//  BabyTrack
//
//  Aggregates events and measurements for presentation.
//

import Foundation
import Tracking
import Measurements

public struct TimelineEntry: Identifiable, Sendable {
    public enum EntryKind: Sendable {
        case event(Event)
        case measurement(MeasurementSample)
    }

    public let id: UUID
    public let date: Date
    public let kind: EntryKind

    public init(id: UUID, date: Date, kind: EntryKind) {
        self.id = id
        self.date = date
        self.kind = kind
    }
}

@MainActor
public final class TimelineViewModel: ObservableObject {
    @Published public private(set) var entries: [TimelineEntry] = []
    @Published public private(set) var isLoading = false

    private let eventsRepository: EventsRepository
    private let measurementsRepository: MeasurementsRepository

    public init(eventsRepository: EventsRepository, measurementsRepository: MeasurementsRepository) {
        self.eventsRepository = eventsRepository
        self.measurementsRepository = measurementsRepository
    }

    public func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let events = eventsRepository.events(in: nil, of: nil)
            async let measurements = gatherMeasurements()
            let combined = try await events.map { event in
                TimelineEntry(id: event.id, date: event.start, kind: .event(event))
            } + measurements
            entries = combined.sorted(by: { $0.date > $1.date })
        } catch {
            entries = []
        }
    }

    private func gatherMeasurements() async throws -> [TimelineEntry] {
        try await MeasurementType.allCases
            .asyncFlatMap { type in try await measurementsRepository.measurements(of: type) }
            .map { measurement in
                TimelineEntry(id: measurement.id, date: measurement.date, kind: .measurement(measurement))
            }
    }
}

private extension Sequence {
    func asyncFlatMap<T>(_ transform: (Element) async throws -> [T]) async rethrows -> [T] {
        var aggregated: [T] = []
        for element in self {
            let value = try await transform(element)
            aggregated.append(contentsOf: value)
        }
        return aggregated
    }
}
