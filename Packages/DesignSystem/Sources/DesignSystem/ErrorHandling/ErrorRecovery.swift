import Foundation

/// Provides error recovery and retry mechanisms
public actor ErrorRecovery {
    private var retryAttempts: [String: Int] = [:]
    private let maxRetries: Int
    private let retryDelay: TimeInterval

    public init(maxRetries: Int = 3, retryDelay: TimeInterval = 2.0) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    // MARK: - Retry Logic

    /// Execute an operation with automatic retry on failure
    public func withRetry<T>(
        operationName: String,
        maxAttempts: Int? = nil,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        let attempts = maxAttempts ?? maxRetries
        var lastError: Error?

        for attempt in 1...attempts {
            do {
                let result = try await operation()
                // Success - reset retry count
                retryAttempts[operationName] = 0
                return result
            } catch {
                lastError = error
                let appError = AppError.from(error)

                // Log the error
                appError.log(context: [
                    "operation": operationName,
                    "attempt": "\(attempt)/\(attempts)"
                ])

                // Don't retry if error is not retryable
                if !appError.isRetryable {
                    throw appError
                }

                // Don't retry if this is the last attempt
                if attempt < attempts {
                    // Exponential backoff
                    let delay = retryDelay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    // Update retry count
                    retryAttempts[operationName] = attempt
                }
            }
        }

        // All retries failed
        throw lastError ?? AppError.unknown(NSError(domain: "ErrorRecovery", code: -1))
    }

    /// Check if operation should be retried
    public func shouldRetry(operation: String) -> Bool {
        let attempts = retryAttempts[operation] ?? 0
        return attempts < maxRetries
    }

    /// Reset retry count for an operation
    public func resetRetries(for operation: String) {
        retryAttempts[operation] = 0
    }

    // MARK: - Recovery Strategies

    /// Attempt to recover from a specific error
    public func recover(from error: AppError) async throws {
        switch error {
        case .networkUnavailable:
            // Wait for network to become available
            try await waitForNetwork()

        case .storageFailure:
            // Try to free up space or wait
            try await freeUpStorage()

        case .syncConflict:
            // Resolve conflict with last-write-wins
            // This would be handled by the sync service
            break

        case .stateRestorationFailed:
            // Clear corrupted state
            clearCorruptedState()

        case .lowMemory:
            // Clear caches
            clearCaches()

        default:
            // No automatic recovery for this error
            throw error
        }
    }

    // MARK: - Private Recovery Methods

    private func waitForNetwork(timeout: TimeInterval = 30) async throws {
        // In a real implementation, this would monitor network reachability
        // For now, we'll simulate with a delay
        let start = Date()

        while Date().timeIntervalSince(start) < timeout {
            // Check if network is available (simplified)
            if await isNetworkAvailable() {
                return
            }
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        throw AppError.networkUnavailable
    }

    private func isNetworkAvailable() async -> Bool {
        // Simplified check - in production, use Network framework
        return true
    }

    private func freeUpStorage() async throws {
        // Clear temporary files
        let tempURL = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tempURL)

        // Clear cache directories
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let contents = try? FileManager.default.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil
            )
            for url in contents ?? [] {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func clearCorruptedState() {
        // Clear UserDefaults for state restoration
        UserDefaults.standard.removeObject(forKey: "saved_state")
        UserDefaults.standard.synchronize()
    }

    private func clearCaches() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()

        // Clear image caches (if using custom image cache)
        // ImageCache.shared.clearAll()
    }
}

// MARK: - Retry Policy

public struct RetryPolicy {
    public let maxAttempts: Int
    public let initialDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let backoffMultiplier: Double

    public static let `default` = RetryPolicy(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        backoffMultiplier: 2.0
    )

    public static let aggressive = RetryPolicy(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 5.0,
        backoffMultiplier: 1.5
    )

    public static let conservative = RetryPolicy(
        maxAttempts: 2,
        initialDelay: 2.0,
        maxDelay: 15.0,
        backoffMultiplier: 3.0
    )

    public init(maxAttempts: Int, initialDelay: TimeInterval, maxDelay: TimeInterval, backoffMultiplier: Double) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }

    /// Calculate delay for a specific attempt
    public func delay(for attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Circuit Breaker

/// Prevents repeated calls to failing operations
public actor CircuitBreaker {
    private enum State {
        case closed // Normal operation
        case open(until: Date) // Failing, reject calls
        case halfOpen // Testing if service recovered
    }

    private var state: State = .closed
    private var failureCount: Int = 0
    private let failureThreshold: Int
    private let timeout: TimeInterval

    public init(failureThreshold: Int = 5, timeout: TimeInterval = 60) {
        self.failureThreshold = failureThreshold
        self.timeout = timeout
    }

    /// Execute operation through circuit breaker
    public func execute<T>(_ operation: @Sendable () async throws -> T) async throws -> T {
        // Check current state
        switch state {
        case .open(let until):
            if Date() < until {
                throw AppError.invalidState(reason: "Circuit breaker is open. Service temporarily unavailable.")
            }
            // Timeout passed, try half-open
            state = .halfOpen

        case .halfOpen, .closed:
            break
        }

        // Execute operation
        do {
            let result = try await operation()
            // Success - reset or close circuit
            if case .halfOpen = state {
                state = .closed
                failureCount = 0
            }
            return result
        } catch {
            // Failure - increment count
            failureCount += 1

            if failureCount >= failureThreshold {
                // Open circuit
                state = .open(until: Date().addingTimeInterval(timeout))
            }

            throw error
        }
    }

    /// Manually reset the circuit breaker
    public func reset() {
        state = .closed
        failureCount = 0
    }
}

// MARK: - Error Recovery Extensions

public extension Task where Failure == Error {
    /// Execute with automatic retry
    static func withRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 2.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let recovery = ErrorRecovery(maxRetries: maxAttempts, retryDelay: delay)
        return try await recovery.withRetry(operationName: "task", operation: operation)
    }
}
