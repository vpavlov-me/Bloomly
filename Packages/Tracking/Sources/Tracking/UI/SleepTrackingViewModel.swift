import AppSupport
import Combine
import Foundation
import os.log

/// Sleep tracking state
public enum SleepState: Equatable {
    case idle
    case active(startTime: Date)
    case completed(duration: TimeInterval)
}

/// Sleep quality rating
public enum SleepQuality: String, CaseIterable, Identifiable {
    case good = "Good"
    case restless = "Restless"
    case short = "Short"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .good: return "😴"
        case .restless: return "😵‍💫"
        case .short: return "🥱"
        }
    }
}

/// ViewModel for sleep tracking feature
@MainActor
public final class SleepTrackingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var state: SleepState = .idle
    @Published public var selectedQuality: SleepQuality?
    @Published public var notes: String = ""
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    @Published public var showSuccess: Bool = false
    @Published public var elapsedTime: TimeInterval = 0
    @Published public var todayTotalHours: Double = 0
    @Published public var weekTotalHours: Double = 0

    // MARK: - Dependencies

    private let repository: EventsRepository
    private let analytics: Analytics
    private let logger = Logger(subsystem: "com.vibecoding.bloomly", category: "SleepTracking")
    private let calendar: Calendar
    private var timerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    public var isActive: Bool {
        if case .active = state {
            return true
        }
        return false
    }

    public var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    public var formattedDuration: String {
        guard case .completed(let duration) = state else { return "" }

        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

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
            await loadTotals()
        }
    }

    // MARK: - Timer Actions

    /// Start sleep tracking
    public func startSleep() {
        guard !isActive else { return }

        logger.info("Starting sleep session")

        let startTime = Date()
        state = .active(startTime: startTime)
        elapsedTime = 0

        // Start timer
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case .active(let start) = self.state {
                    self.elapsedTime = Date().timeIntervalSince(start)
                }
            }

        // Track analytics
        analytics.track(AnalyticsEvent(
            type: .sleepTrackingStarted,
            metadata: ["action": "started"]
        ))
    }

    /// Stop sleep tracking
    public func stopSleep() {
        guard case .active(let startTime) = state else { return }

        logger.info("Stopping sleep session")

        let duration = Date().timeIntervalSince(startTime)
        state = .completed(duration: duration)
        timerCancellable?.cancel()
        timerCancellable = nil

        // Track analytics
        analytics.track(AnalyticsEvent(
            type: .sleepTrackingStopped,
            metadata: [
                "action": "stopped",
                "durationMinutes": String(Int(duration / 60))
            ]
        ))
    }

    /// Cancel active session
    public func cancelSession() {
        logger.info("Cancelling sleep session")
        timerCancellable?.cancel()
        timerCancellable = nil
        resetForm()
    }

    // MARK: - Save Action

    /// Save sleep session
    public func saveSleep() async {
        guard case .completed(let duration) = state else {
            error = "Please stop the timer first"
            return
        }

        logger.info("Saving sleep: duration=\(Int(duration/60))min, quality=\(self.selectedQuality?.rawValue ?? "none")")

        isLoading = true
        error = nil

        do {
            let now = Date()
            let event = EventDTO(
                kind: .sleep,
                start: now.addingTimeInterval(-duration),
                end: now,
                notes: buildNotes()
            )

            _ = try await repository.create(event)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .sleepTrackingStopped,
                metadata: [
                    "action": "completed",
                    "durationMinutes": String(Int(duration / 60)),
                    "hasQuality": String(selectedQuality != nil),
                    "quality": selectedQuality?.rawValue ?? "none"
                ]
            ))

            // Update totals
            let hours = duration / 3600
            todayTotalHours += hours
            weekTotalHours += hours

            // Show success
            showSuccess = true
            logger.info("Sleep saved successfully")

            // Reset form
            resetForm()

            // Hide success after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccess = false

        } catch {
            logger.error("Failed to save sleep: \(error.localizedDescription)")
            self.error = "Failed to save sleep session. Please try again."
            isLoading = false
        }
    }

    // MARK: - Data Loading

    /// Load today's and this week's totals
    public func loadTotals() async {
        do {
            // Today's total
            let todayEvents = try await repository.events(on: Date(), calendar: calendar)
            let todaySleep = todayEvents.filter { $0.kind == .sleep }
            todayTotalHours = calculateTotalHours(from: todaySleep)

            // Week's total
            let weekStart = calendar.startOfWeek(for: Date())
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let weekInterval = DateInterval(start: weekStart, end: weekEnd)
            let weekEvents = try await repository.events(in: weekInterval, kind: .sleep)
            weekTotalHours = calculateTotalHours(from: weekEvents)

            logger.debug("Loaded totals: today=\(self.todayTotalHours)h, week=\(self.weekTotalHours)h")
        } catch {
            logger.error("Failed to load totals: \(error.localizedDescription)")
        }
    }

    /// Reset form to defaults
    public func resetForm() {
        state = .idle
        selectedQuality = nil
        notes = ""
        elapsedTime = 0
        error = nil
        isLoading = false
    }

    // MARK: - Private Helpers

    private func buildNotes() -> String {
        var components: [String] = []

        if let quality = selectedQuality {
            components.append("Quality: \(quality.rawValue)")
        }

        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.append(notes)
        }

        return components.joined(separator: " • ")
    }

    private func calculateTotalHours(from events: [EventDTO]) -> Double {
        let totalSeconds = events.reduce(0.0) { $0 + $1.duration }
        return totalSeconds / 3600
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
