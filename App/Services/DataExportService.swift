import Foundation
import Measurements
import Tracking
import UniformTypeIdentifiers

/// Data export service for generating CSV/JSON exports
@MainActor
public final class DataExportService {
    private let eventsRepository: any EventsRepository
    private let measurementsRepository: any MeasurementsRepository

    public init(
        eventsRepository: any EventsRepository,
        measurementsRepository: any MeasurementsRepository
    ) {
        self.eventsRepository = eventsRepository
        self.measurementsRepository = measurementsRepository
    }

    // MARK: - Export Methods

    /// Export all data to CSV format
    public func exportToCSV(dateRange: DateInterval?) async throws -> URL {
        let events = try await eventsRepository.events(in: dateRange, kind: nil)
        let measurements = try await measurementsRepository.measurements(in: dateRange, type: nil)

        let eventsCSV = generateEventsCSV(events)
        let measurementsCSV = generateMeasurementsCSV(measurements)

        // Combine both CSVs with section headers
        let combinedCSV = """
        EVENTS
        \(eventsCSV)

        MEASUREMENTS
        \(measurementsCSV)
        """

        return try saveToTemporaryFile(combinedCSV, filename: "BabyTrack_Export.csv")
    }

    /// Export all data to JSON format
    public func exportToJSON(dateRange: DateInterval?) async throws -> URL {
        let events = try await eventsRepository.events(in: dateRange, kind: nil)
        let measurements = try await measurementsRepository.measurements(in: dateRange, type: nil)

        let exportData = ExportData(
            exportDate: Date(),
            dateRange: dateRange,
            events: events.map(EventExport.init),
            measurements: measurements.map(MeasurementExport.init)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportData)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return try saveToTemporaryFile(jsonString, filename: "BabyTrack_Export.json")
    }

    // MARK: - Private Helpers

    private func generateEventsCSV(_ events: [EventDTO]) -> String {
        var csv = "ID,Kind,Start,End,Duration (min),Notes,Created At,Updated At\n"

        let formatter = ISO8601DateFormatter()

        for event in events {
            let id = event.id.uuidString
            let kind = event.kind.rawValue
            let start = formatter.string(from: event.start)
            let end = event.end.map { formatter.string(from: $0) } ?? ""
            let duration = String(format: "%.0f", event.duration / 60)
            let notes = escapeCSV(event.notes ?? "")
            let createdAt = formatter.string(from: event.createdAt)
            let updatedAt = formatter.string(from: event.updatedAt)

            csv += "\(id),\(kind),\(start),\(end),\(duration),\(notes),\(createdAt),\(updatedAt)\n"
        }

        return csv
    }

    private func generateMeasurementsCSV(_ measurements: [MeasurementDTO]) -> String {
        var csv = "ID,Type,Value,Unit,Date\n"

        let formatter = ISO8601DateFormatter()

        for measurement in measurements {
            let id = measurement.id.uuidString
            let type = measurement.type.rawValue
            let value = String(measurement.value)
            let unit = measurement.unit
            let date = formatter.string(from: measurement.date)

            csv += "\(id),\(type),\(value),\(unit),\(date)\n"
        }

        return csv
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    private func saveToTemporaryFile(_ content: String, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        try data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Export Models

private struct ExportData: Codable {
    let exportDate: Date
    let dateRange: DateInterval?
    let events: [EventExport]
    let measurements: [MeasurementExport]
}

private struct EventExport: Codable {
    let id: UUID
    let kind: String
    let start: Date
    let end: Date?
    let durationMinutes: Double
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    init(from dto: EventDTO) {
        self.id = dto.id
        self.kind = dto.kind.rawValue
        self.start = dto.start
        self.end = dto.end
        self.durationMinutes = dto.duration / 60
        self.notes = dto.notes
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}

private struct MeasurementExport: Codable {
    let id: UUID
    let type: String
    let value: Double
    let unit: String
    let date: Date

    init(from dto: MeasurementDTO) {
        self.id = dto.id
        self.type = dto.type.rawValue
        self.value = dto.value
        self.unit = dto.unit
        self.date = dto.date
    }
}

// MARK: - Errors

public enum ExportError: LocalizedError {
    case encodingFailed
    case saveFailed

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode export data"
        case .saveFailed:
            return "Failed to save export file"
        }
    }
}
