import AppSupport
import Combine
import Foundation
import os.log

/// Feeding type
public enum FeedingType: String, CaseIterable, Identifiable {
    case breast = "Breast"
    case bottle = "Bottle"
    case solid = "Solid"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .breast: return "🤱"
        case .bottle: return "🍼"
        case .solid: return "🥄"
        }
    }
}

/// Breast side
public enum BreastSide: String, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .left: return "L"
        case .right: return "R"
        }
    }

    public var opposite: BreastSide {
        switch self {
        case .left: return .right
        case .right: return .left
        }
    }
}

/// Breast feeding state
public enum BreastFeedingState: Equatable {
    case idle
    case active(side: BreastSide, startTime: Date)
    case paused(side: BreastSide, elapsedTime: TimeInterval)
    case completed(leftDuration: TimeInterval, rightDuration: TimeInterval)
}

/// ViewModel for feeding tracking feature
@MainActor
public final class FeedingTrackingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var selectedType: FeedingType = .breast
    @Published public var breastState: BreastFeedingState = .idle
    @Published public var currentSide: BreastSide = .left
    @Published public var leftDuration: TimeInterval = 0
    @Published public var rightDuration: TimeInterval = 0
    @Published public var bottleVolume: Int = 0
    @Published public var solidDescription: String = ""
    @Published public var solidAmount: String = ""
    @Published public var notes: String = ""
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    @Published public var showSuccess: Bool = false
    @Published public var elapsedTime: TimeInterval = 0

    // MARK: - Dependencies

    private let repository: EventsRepository
    private let analytics: Analytics
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.example.babytrack", category: "FeedingTracking")
    private var timerCancellable: AnyCancellable?

    // MARK: - Constants

    private let lastBreastSideKey = "FeedingTracking.lastBreastSide"
    public let bottleVolumePresets = [60, 90, 120, 150, 180]

    // MARK: - Computed Properties

    public var isBreastActive: Bool {
        if case .active = breastState {
            return true
        }
        return false
    }

    public var isBreastPaused: Bool {
        if case .paused = breastState {
            return true
        }
        return false
    }

    public var formattedElapsedTime: String {
        formatDuration(elapsedTime)
    }

    public var formattedLeftDuration: String {
        formatDuration(leftDuration)
    }

    public var formattedRightDuration: String {
        formatDuration(rightDuration)
    }

    public var totalBreastDuration: TimeInterval {
        leftDuration + rightDuration
    }

    public var canSave: Bool {
        switch selectedType {
        case .breast:
            return totalBreastDuration > 0
        case .bottle:
            return bottleVolume > 0
        case .solid:
            return !solidDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Initialization

    public init(
        repository: EventsRepository,
        analytics: Analytics,
        userDefaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.analytics = analytics
        self.userDefaults = userDefaults

        // Load last breast side
        if let lastSideRaw = userDefaults.string(forKey: lastBreastSideKey),
           let lastSide = BreastSide(rawValue: lastSideRaw) {
            self.currentSide = lastSide
        }
    }

    // MARK: - Type Selection

    /// Select feeding type
    public func selectType(_ type: FeedingType) {
        guard selectedType != type else { return }

        logger.info("Switching feeding type to \(type.rawValue)")
        selectedType = type

        // Track analytics
        analytics.track(AnalyticsEvent(
            type: .feedingTracked,
            metadata: ["action": "typeSelected", "type": type.rawValue]
        ))

        // Reset state when switching types
        if type != .breast {
            stopBreastFeeding()
        }
    }

    // MARK: - Breast Feeding Actions

    /// Start breast feeding on current side
    public func startBreastFeeding() {
        guard case .idle = breastState else { return }

        logger.info("Starting breast feeding on \(self.currentSide.rawValue) side")

        let now = Date()
        breastState = .active(side: currentSide, startTime: now)
        elapsedTime = 0

        // Start timer
        startTimer()

        // Track analytics
        analytics.track(AnalyticsEvent(
            type: .feedingTracked,
            metadata: [
                "action": "started",
                "type": "breast",
                "side": currentSide.rawValue
            ]
        ))
    }

    /// Pause breast feeding
    public func pauseBreastFeeding() {
        guard case .active(let side, let startTime) = breastState else { return }

        logger.info("Pausing breast feeding")

        let elapsed = Date().timeIntervalSince(startTime)
        breastState = .paused(side: side, elapsedTime: elapsed)

        // Update duration for current side
        updateSideDuration(side: side, additionalTime: elapsed)

        // Stop timer
        stopTimer()
    }

    /// Resume breast feeding on paused side
    public func resumeBreastFeeding() {
        guard case .paused(let side, _) = breastState else { return }

        logger.info("Resuming breast feeding on \(side.rawValue) side")

        let now = Date()
        breastState = .active(side: side, startTime: now)
        currentSide = side
        elapsedTime = 0

        // Restart timer
        startTimer()
    }

    /// Switch to opposite breast side
    public func switchBreastSide() {
        guard isBreastActive else { return }

        guard case .active(let currentSide, let startTime) = breastState else { return }

        logger.info("Switching breast side from \(currentSide.rawValue) to \(currentSide.opposite.rawValue)")

        // Save time for current side
        let elapsed = Date().timeIntervalSince(startTime)
        updateSideDuration(side: currentSide, additionalTime: elapsed)

        // Switch to opposite side
        let newSide = currentSide.opposite
        self.currentSide = newSide
        let now = Date()
        breastState = .active(side: newSide, startTime: now)
        elapsedTime = 0

        // Timer continues running
    }

    /// Stop breast feeding
    public func stopBreastFeeding() {
        guard isBreastActive || isBreastPaused else { return }

        logger.info("Stopping breast feeding")

        // If active, save current elapsed time
        if case .active(let side, let startTime) = breastState {
            let elapsed = Date().timeIntervalSince(startTime)
            updateSideDuration(side: side, additionalTime: elapsed)
        }

        breastState = .completed(leftDuration: leftDuration, rightDuration: rightDuration)
        stopTimer()

        // Save last side for next feeding
        let lastSide = leftDuration >= rightDuration ? BreastSide.left : BreastSide.right
        userDefaults.set(lastSide.opposite.rawValue, forKey: lastBreastSideKey)
    }

    // MARK: - Bottle Actions

    /// Set bottle volume with preset
    public func setBottleVolume(_ volume: Int) {
        logger.debug("Setting bottle volume to \(volume)ml")
        bottleVolume = volume
    }

    /// Adjust bottle volume by delta
    public func adjustBottleVolume(by delta: Int) {
        let newVolume = max(0, bottleVolume + delta)
        logger.debug("Adjusting bottle volume by \(delta)ml to \(newVolume)ml")
        bottleVolume = newVolume
    }

    // MARK: - Save Action

    /// Save feeding session
    public func saveFeeding() async {
        guard canSave else {
            error = "Please complete feeding information"
            return
        }

        logger.info("Saving feeding: type=\(self.selectedType.rawValue)")

        isLoading = true
        error = nil

        do {
            let now = Date()
            var metadata: [String: String] = [:]
            var startTime = now

            switch selectedType {
            case .breast:
                let duration = totalBreastDuration
                startTime = now.addingTimeInterval(-duration)
                metadata["leftDuration"] = String(Int(leftDuration))
                metadata["rightDuration"] = String(Int(rightDuration))
                metadata["totalDuration"] = String(Int(duration))

            case .bottle:
                metadata["volume"] = String(bottleVolume)

            case .solid:
                metadata["description"] = solidDescription
                if !solidAmount.isEmpty {
                    metadata["amount"] = solidAmount
                }
            }

            let event = EventDTO(
                kind: .feeding,
                start: startTime,
                end: now,
                notes: buildNotes(),
                metadata: metadata
            )

            _ = try await repository.create(event)

            // Track analytics
            analytics.track(AnalyticsEvent(
                type: .feedingTracked,
                metadata: [
                    "action": "completed",
                    "type": selectedType.rawValue,
                    "hasNotes": String(!notes.isEmpty)
                ].merging(metadata) { $1 }
            ))

            // Show success
            showSuccess = true
            logger.info("Feeding saved successfully")

            // Reset form
            resetForm()

            // Hide success after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccess = false

        } catch {
            logger.error("Failed to save feeding: \(error.localizedDescription)")
            self.error = "Failed to save feeding. Please try again."
            isLoading = false
        }
    }

    /// Reset form to defaults
    public func resetForm() {
        breastState = .idle
        leftDuration = 0
        rightDuration = 0
        elapsedTime = 0
        bottleVolume = 0
        solidDescription = ""
        solidAmount = ""
        notes = ""
        error = nil
        isLoading = false
        stopTimer()
    }

    // MARK: - Private Helpers

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case .active(_, let startTime) = self.breastState {
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        elapsedTime = 0
    }

    private func updateSideDuration(side: BreastSide, additionalTime: TimeInterval) {
        switch side {
        case .left:
            leftDuration += additionalTime
        case .right:
            rightDuration += additionalTime
        }
    }

    public func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func buildNotes() -> String {
        var components: [String] = []

        // Add type-specific info
        switch selectedType {
        case .breast:
            if leftDuration > 0 && rightDuration > 0 {
                components.append("L: \(formattedLeftDuration) • R: \(formattedRightDuration)")
            } else if leftDuration > 0 {
                components.append("Left: \(formattedLeftDuration)")
            } else if rightDuration > 0 {
                components.append("Right: \(formattedRightDuration)")
            }

        case .bottle:
            components.append("\(bottleVolume) ml")

        case .solid:
            if !solidAmount.isEmpty {
                components.append(solidAmount)
            }
        }

        // Add user notes
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.append(notes)
        }

        return components.joined(separator: " • ")
    }
}
