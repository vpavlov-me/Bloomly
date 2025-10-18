//
//  EventsRepository.swift
//  BabyTrack
//
//  Defines contracts for accessing baby care events.
//

import Foundation

public enum EventKind: String, CaseIterable, Codable, Sendable {
    case sleep
    case feed
    case diaper
}

public struct Event: Identifiable, Codable, Sendable {
    public let id: UUID
    public let kind: EventKind
    public let start: Date
    public let end: Date?
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let isSynced: Bool

    public init(
        id: UUID,
        kind: EventKind,
        start: Date,
        end: Date?,
        notes: String?,
        createdAt: Date,
        updatedAt: Date,
        isSynced: Bool
    ) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
    }
}

public struct EventInput: Sendable {
    public let id: UUID
    public let kind: EventKind
    public let start: Date
    public let end: Date?
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let isSynced: Bool

    public init(
        id: UUID = UUID(),
        kind: EventKind,
        start: Date,
        end: Date?,
        notes: String?,
        createdAt: Date,
        updatedAt: Date,
        isSynced: Bool
    ) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
    }
}

public protocol EventsRepository: Sendable {
    func events(in range: ClosedRange<Date>?, of kind: EventKind?) async throws -> [Event]
    func upsert(_ event: EventInput) async throws
    func delete(id: UUID) async throws
}

public extension EventsRepository {
    func events(for kind: EventKind) async throws -> [Event] {
        try await events(in: nil, of: kind)
    }
}
