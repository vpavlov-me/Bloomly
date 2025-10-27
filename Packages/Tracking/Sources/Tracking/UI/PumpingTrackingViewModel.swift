import AppSupport
import Combine
import Foundation
import os.log

/// Pumping tracking state
public enum PumpingState: Equatable {
    case idle
    case active(startTime: Date)
    case completed(duration: TimeInterval)
}

/// ViewModel for pumping tracking feature
@MainActor
public final class PumpingTrackingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var state: PumpingState = .idle
    @Published public var leftBreastVolume: Int = 0
    @Published public var rightBreastVolume: Int = 0
    @Published public var notes: String = ""
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    @Published public var showSuccess: Bool = false
    @Published public var elapsedTime: TimeInterval = 0
    @Published public var todayTotal: Int = 0
    @Published public var weekTotal: Int = 0

    // MARK: - Constants

    public static let volumePresets = [30, 60, 90, 120]

    // MARK: - Dependencies

    private let repository: EventsRepository
    private let analytics: Analytics
    private let logger = Logger(subsystem: "com.example.babytrack", category: "PumpingTracking")
    private let calendar: Calendar
    private var timerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    public var totalVolume: Int {
        leftBreastVolume + rightBreastVolume
    }

    public var isActive: Bool {
        if case .active = state {
            return true
        }
        return false
    }

    public var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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

    /// Start pumping timer
    public func startPumping() {
        guard !isActive else { return }

        logger.info("Starting pumping session")

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
            type: .pumpingTracked,
            metadata: ["action": "started"]
        ))
    }

    /// Stop pumping timer
    public func stopPumping() {
        guard case .active(let startTime) = state else { return }

        logger.info("Stopping pumping session")

        let duration = Date().timeIntervalSince(startTime)
        state = .completed(duration: duration)
        timerCancellable?.cancel()
        timerCancellable = nil

        // Track analytics
        analytics.track(AnalyticsEvent(
            type: .pumpingTracked,
            metadata: [
                "action": "stopped",
                "duration": String(Int(duration / 60)) // minutes
            ]
        ))
    }

    /// Cancel active session
    public func cancelSession() {
        logger.info("Cancelling pumping session")
        timerCancellable?.cancel()
        timerCancellable = nil
        resetForm()
    }

    // MARK: - Volume Actions

    /// Set volume for left breast
    public func setLeftVolume(_ volume: Int) {
        leftBreastVolume = max(0, volume)
    }

    /// Set volume for right breast
    public func setRightVolume(_ volume: Int) {
        rightBreastVolume = max(0, volume)
    }

    /// Apply preset to left breast
    public func applyLeftPreset(_ volume: Int) {
        leftBreastVolume = volume
    }

    /// Apply preset to right breast
    public func applyRightPreset(_ volume: Int) {
        rightBreastVolume = volume
    }

    // MARK: - Save Action

    /// Save pumping session
    public func savePumping() async {
        guard case .completed(let duration) = state else {
            error = "Please stop the timer first"
            return
        }

        guard totalVolume > 0 else {
            error = "Please enter volume for at least one breast"
            return
        }

        logger.info("Saving pumping: left=\(self.leftBreastVolume)ml, right=\(self.rightBreastVolume)ml")

        isLoading = true
        error = nil

        do {
            let now = Date()
            let event = EventDTO(
                kind: .pumping,
                start: now.addingTimeInterval(-duration),
                end: now,
                notes: buildNotes()
            )

            _ = try await repository.create(event)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .pumpingTracked,
                metadata: [
                    "action": "completed",
                    "totalVolume": String(totalVolume),
                    "leftVolume": String(leftBreastVolume),
                    "rightVolume": String(rightBreastVolume),
                    "duration": String(Int(duration / 60))
                ]
            ))

            // Update totals
            todayTotal += totalVolume
            weekTotal += totalVolume

            // Show success
            showSuccess = true
            logger.info("Pumping saved successfully")

            // Reset form
            resetForm()

            // Hide success after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccess = false

        } catch {
            logger.error("Failed to save pumping: \(error.localizedDescription)")
            self.error = "Failed to save pumping session. Please try again."
            isLoading = false
        }
    }

    // MARK: - Data Loading

    /// Load today's and this week's totals
    public func loadTotals() async {
        do {
            // Today's total
            let todayEvents = try await repository.events(on: Date(), calendar: calendar)
            let todayPumping = todayEvents.filter { $0.kind == .pumping }
            todayTotal = calculateTotalVolume(from: todayPumping)

            // Week's total
            let weekStart = calendar.startOfWeek(for: Date())
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let weekInterval = DateInterval(start: weekStart, end: weekEnd)
            let weekEvents = try await repository.events(in: weekInterval, kind: .pumping)
            weekTotal = calculateTotalVolume(from: weekEvents)

            logger.debug("Loaded totals: today=\(self.todayTotal)ml, week=\(self.weekTotal)ml")
        } catch {
            logger.error("Failed to load totals: \(error.localizedDescription)")
        }
    }

    /// Reset form to defaults
    public func resetForm() {
        state = .idle
        leftBreastVolume = 0
        rightBreastVolume = 0
        notes = ""
        elapsedTime = 0
        error = nil
        isLoading = false
    }

    // MARK: - Private Helpers

    private func buildNotes() -> String {
        var components: [String] = []

        components.append("Left: \(leftBreastVolume)ml")
        components.append("Right: \(rightBreastVolume)ml")
        components.append("Total: \(totalVolume)ml")

        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.append(notes)
        }

        return components.joined(separator: " • ")
    }

    private func calculateTotalVolume(from events: [EventDTO]) -> Int {
        events.reduce(0) { total, event in
            // Extract volume from notes (format: "Total: XXml")
            guard let notes = event.notes else { return total }
            let components = notes.components(separatedBy: " • ")
            for component in components where component.contains("Total:") {
                let volumeString = component.replacingOccurrences(of: "Total:", with: "")
                    .replacingOccurrences(of: "ml", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let volume = Int(volumeString) {
                    return total + volume
                }
            }
            return total
        }
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
