import AppSupport
import Foundation
import os.log

/// Diaper type options
public enum DiaperType: String, CaseIterable, Identifiable {
    case wet = "Wet"
    case dirty = "Dirty"
    case both = "Both"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .wet: return "💧"
        case .dirty: return "💩"
        case .both: return "💧💩"
        }
    }
}

/// Consistency options for dirty diapers
public enum DiaperConsistency: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case loose = "Loose"
    case hard = "Hard"

    public var id: String { rawValue }
}

/// ViewModel for diaper tracking feature
@MainActor
public final class DiaperTrackingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var selectedType: DiaperType = .wet
    @Published public var consistency: DiaperConsistency?
    @Published public var notes: String = ""
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    @Published public var showSuccess: Bool = false
    @Published public var todayCount: Int = 0

    // MARK: - Dependencies

    private let repository: EventsRepository
    private let analytics: Analytics
    private let logger = Logger(subsystem: "com.example.babytrack", category: "DiaperTracking")
    private let calendar: Calendar

    // MARK: - Initialization

    public init(
        repository: EventsRepository,
        analytics: Analytics,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.analytics = analytics
        self.calendar = calendar

        Task {
            await loadTodayCount()
        }
    }

    // MARK: - Public Methods

    /// Log a diaper change
    public func logDiaper() async {
        logger.info("Logging diaper: \(self.selectedType.rawValue)")

        isLoading = true
        error = nil

        do {
            // Create event DTO
            let event = EventDTO(
                kind: .diaper,
                start: Date(),
                end: Date(),
                notes: buildNotes()
            )

            // Save to repository
            _ = try await repository.create(event)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .diaperTracked,
                metadata: [
                    "type": selectedType.rawValue.lowercased(),
                    "hasConsistency": (consistency != nil).description
                ]
            ))

            // Update counter
            todayCount += 1

            // Show success
            showSuccess = true
            logger.info("Diaper logged successfully")

            // Reset form
            resetForm()

            // Hide success after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showSuccess = false

        } catch {
            logger.error("Failed to log diaper: \(error.localizedDescription)")
            self.error = "Failed to save diaper change. Please try again."
            isLoading = false
        }
    }

    /// Load today's diaper count
    public func loadTodayCount() async {
        do {
            let events = try await repository.events(on: Date(), calendar: calendar)
            let diaperEvents = events.filter { $0.kind == .diaper }
            todayCount = diaperEvents.count
            logger.debug("Today's diaper count: \(self.todayCount)")
        } catch {
            logger.error("Failed to load today's count: \(error.localizedDescription)")
        }
    }

    /// Reset form to defaults
    public func resetForm() {
        selectedType = .wet
        consistency = nil
        notes = ""
        error = nil
        isLoading = false
    }

    // MARK: - Private Helpers

    private func buildNotes() -> String {
        var components: [String] = []

        components.append(selectedType.rawValue)

        if let consistency = consistency, selectedType != .wet {
            components.append("Consistency: \(consistency.rawValue)")
        }

        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.append(notes)
        }

        return components.joined(separator: " • ")
    }
}
