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
            async let height = measurementsRepository.measurements(of: .height)
            async let weight = measurementsRepository.measurements(of: .weight)
            let combined = try await events.map { event in
                TimelineEntry(id: event.id, date: event.start, kind: .event(event))
            } + height.map { measurement in
                TimelineEntry(id: measurement.id, date: measurement.date, kind: .measurement(measurement))
            } + weight.map { measurement in
                TimelineEntry(id: measurement.id, date: measurement.date, kind: .measurement(measurement))
            }
            entries = combined.sorted(by: { $0.date > $1.date })
        } catch {
            entries = []
        }
    }
}
