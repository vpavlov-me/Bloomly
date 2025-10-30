import AppSupport
import Foundation
import os.log

/// Centralized error logging and analytics tracking
public actor ErrorLogger {
    private let logger: Logger
    private let analytics: Analytics?
    private var errorHistory: [ErrorRecord] = []
    private let maxHistorySize = 100

    public init(subsystem: String = "com.vibecoding.bloomly", category: String = "Errors", analytics: Analytics? = nil) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.analytics = analytics
    }

    // MARK: - Logging

    /// Log an error with appropriate severity
    public func log(_ error: AppError, context: [String: String] = [:]) {
        let record = ErrorRecord(error: error, context: context)
        storeInHistory(record)

        // Log to system logger
        logToSystem(error, context: context)

        // Report to analytics if needed
        if error.shouldReport {
            reportToAnalytics(error, context: context)
        }
    }

    /// Log a generic error
    public func log(_ error: Error, context: [String: String] = [:]) {
        let appError = AppError.from(error)
        log(appError, context: context)
    }

    // MARK: - Error History

    /// Get recent errors for debugging
    public func recentErrors(limit: Int = 10) -> [ErrorRecord] {
        Array(errorHistory.suffix(limit))
    }

    /// Clear error history
    public func clearHistory() {
        errorHistory.removeAll()
    }

    // MARK: - Private Methods

    private func logToSystem(_ error: AppError, context: [String: String]) {
        let contextString = context.isEmpty ? "" : " Context: \(context)"
        let message = "\(error.errorDescription ?? "Unknown error")\(contextString)"

        switch error.severity {
        case .critical:
            logger.critical("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        }

        // Log additional details
        if let reason = error.failureReason {
            logger.debug("Reason: \(reason, privacy: .public)")
        }
        if let suggestion = error.recoverySuggestion {
            logger.debug("Suggestion: \(suggestion, privacy: .public)")
        }
    }

    private func reportToAnalytics(_ error: AppError, context: [String: String]) {
        guard let analytics = analytics else { return }

        var metadata = context
        metadata["error_id"] = error.id
        metadata["severity"] = error.severity.rawValue
        metadata["is_retryable"] = String(error.isRetryable)

        if let reason = error.failureReason {
            metadata["reason"] = reason
        }

        let event = AnalyticsEvent(name: "error_occurred", metadata: metadata)
        analytics.track(event)
    }

    private func storeInHistory(_ record: ErrorRecord) {
        errorHistory.append(record)

        // Keep history size manageable
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }
    }
}

// MARK: - Error Record

public struct ErrorRecord: Identifiable {
    public let id: UUID
    public let error: AppError
    public let timestamp: Date
    public let context: [String: String]

    init(error: AppError, context: [String: String] = [:]) {
        self.id = UUID()
        self.error = error
        self.timestamp = Date()
        self.context = context
    }

    public var description: String {
        var desc = "\(timestamp.formatted()): \(error.errorDescription ?? "Unknown")"
        if !context.isEmpty {
            desc += "\nContext: \(context)"
        }
        if let reason = error.failureReason {
            desc += "\nReason: \(reason)"
        }
        return desc
    }
}

// MARK: - Global Error Logger

public actor GlobalErrorLogger {
    public static let shared = GlobalErrorLogger()

    private var logger: ErrorLogger?

    private init() {}

    public func configure(analytics: Analytics? = nil) {
        logger = ErrorLogger(analytics: analytics)
    }

    public func log(_ error: AppError, context: [String: String] = [:]) {
        guard let logger = logger else {
            // Fallback to basic logging if not configured
            print("❌ Error: \(error.errorDescription ?? "Unknown") \(context)")
            return
        }

        Task {
            await logger.log(error, context: context)
        }
    }

    public func log(_ error: Error, context: [String: String] = [:]) {
        let appError = AppError.from(error)
        log(appError, context: context)
    }

    public func recentErrors(limit: Int = 10) async -> [ErrorRecord] {
        guard let logger = logger else { return [] }
        return await logger.recentErrors(limit: limit)
    }
}

// MARK: - Convenience Extensions

public extension Error {
    /// Convert to AppError and log
    func logError(context: [String: String] = [:]) {
        Task {
            await GlobalErrorLogger.shared.log(self, context: context)
        }
    }
}

public extension AppError {
    /// Log this error
    func log(context: [String: String] = [:]) {
        Task {
            await GlobalErrorLogger.shared.log(self, context: context)
        }
    }
}
