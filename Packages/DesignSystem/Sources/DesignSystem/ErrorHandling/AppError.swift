import Foundation

/// Comprehensive error hierarchy for the entire application
/// Provides user-friendly messages and recovery suggestions
public enum AppError: LocalizedError, Identifiable {
    // MARK: - Data Layer Errors
    case dataCorruption(details: String)
    case storageFailure(underlying: Error)
    case constraintViolation(field: String, reason: String)
    case notFound(entity: String, id: String)
    case invalidState(reason: String)

    // MARK: - Network & Sync Errors
    case networkUnavailable
    case syncConflict(entity: String)
    case cloudKitFailure(underlying: Error)
    case authenticationRequired
    case quotaExceeded

    // MARK: - Permission Errors
    case permissionDenied(permission: Permission)
    case notificationPermissionDenied

    // MARK: - In-App Purchase Errors
    case purchaseFailed(reason: String)
    case productNotFound
    case receiptValidationFailed
    case restoreFailed

    // MARK: - Validation Errors
    case validationError(field: String, reason: String)
    case invalidInput(field: String)
    case dateRangeInvalid
    case requiredFieldMissing(field: String)

    // MARK: - State Management Errors
    case appInterrupted(activity: String)
    case stateRestorationFailed
    case concurrentModification

    // MARK: - System Errors
    case lowStorage
    case lowMemory
    case backgroundTaskFailed

    // MARK: - Unknown
    case unknown(Error)

    public var id: String {
        switch self {
        case .dataCorruption: return "data_corruption"
        case .storageFailure: return "storage_failure"
        case .constraintViolation: return "constraint_violation"
        case .notFound: return "not_found"
        case .invalidState: return "invalid_state"
        case .networkUnavailable: return "network_unavailable"
        case .syncConflict: return "sync_conflict"
        case .cloudKitFailure: return "cloudkit_failure"
        case .authenticationRequired: return "auth_required"
        case .quotaExceeded: return "quota_exceeded"
        case .permissionDenied: return "permission_denied"
        case .notificationPermissionDenied: return "notification_permission"
        case .purchaseFailed: return "purchase_failed"
        case .productNotFound: return "product_not_found"
        case .receiptValidationFailed: return "receipt_validation"
        case .restoreFailed: return "restore_failed"
        case .validationError: return "validation_error"
        case .invalidInput: return "invalid_input"
        case .dateRangeInvalid: return "date_range_invalid"
        case .requiredFieldMissing: return "required_field"
        case .appInterrupted: return "app_interrupted"
        case .stateRestorationFailed: return "state_restoration"
        case .concurrentModification: return "concurrent_modification"
        case .lowStorage: return "low_storage"
        case .lowMemory: return "low_memory"
        case .backgroundTaskFailed: return "background_task"
        case .unknown: return "unknown"
        }
    }

    // MARK: - User-Friendly Error Messages

    public var errorDescription: String? {
        switch self {
        // Data Layer
        case .dataCorruption:
            return "Data issue detected"
        case .storageFailure:
            return "Unable to save data"
        case .constraintViolation(let field, _):
            return "Invalid \(field)"
        case .notFound(let entity, _):
            return "\(entity.capitalized) not found"
        case .invalidState:
            return "Action cannot be completed right now"

        // Network & Sync
        case .networkUnavailable:
            return "No internet connection"
        case .syncConflict:
            return "Sync conflict detected"
        case .cloudKitFailure:
            return "Cloud sync error"
        case .authenticationRequired:
            return "Sign in required"
        case .quotaExceeded:
            return "Storage limit reached"

        // Permissions
        case .permissionDenied(let permission):
            return "\(permission.displayName) permission required"
        case .notificationPermissionDenied:
            return "Notification permission required"

        // In-App Purchase
        case .purchaseFailed:
            return "Purchase failed"
        case .productNotFound:
            return "Product unavailable"
        case .receiptValidationFailed:
            return "Unable to verify purchase"
        case .restoreFailed:
            return "Restore failed"

        // Validation
        case .validationError(let field, _):
            return "Invalid \(field)"
        case .invalidInput(let field):
            return "Please check \(field)"
        case .dateRangeInvalid:
            return "Invalid date range"
        case .requiredFieldMissing(let field):
            return "\(field.capitalized) is required"

        // State Management
        case .appInterrupted:
            return "Activity interrupted"
        case .stateRestorationFailed:
            return "Unable to restore previous state"
        case .concurrentModification:
            return "Data was modified elsewhere"

        // System
        case .lowStorage:
            return "Storage space low"
        case .lowMemory:
            return "Memory running low"
        case .backgroundTaskFailed:
            return "Background task failed"

        case .unknown:
            return "Something went wrong"
        }
    }

    // MARK: - Detailed Messages

    public var failureReason: String? {
        switch self {
        case .dataCorruption(let details):
            return details
        case .storageFailure(let error):
            return error.localizedDescription
        case .constraintViolation(_, let reason):
            return reason
        case .notFound(_, let id):
            return "ID: \(id)"
        case .invalidState(let reason):
            return reason
        case .cloudKitFailure(let error):
            return error.localizedDescription
        case .purchaseFailed(let reason):
            return reason
        case .validationError(_, let reason):
            return reason
        case .appInterrupted(let activity):
            return "During: \(activity)"
        case .unknown(let error):
            return error.localizedDescription
        default:
            return nil
        }
    }

    // MARK: - Recovery Suggestions

    public var recoverySuggestion: String? {
        switch self {
        // Data Layer
        case .dataCorruption:
            return "Please restart the app. If the problem persists, try reinstalling."
        case .storageFailure:
            return "Please try again. If the problem continues, free up device storage."
        case .constraintViolation:
            return "Please check your input and try again."
        case .notFound:
            return "The item may have been deleted. Pull to refresh."
        case .invalidState:
            return "Please try again in a moment."

        // Network & Sync
        case .networkUnavailable:
            return "Connect to the internet and try again."
        case .syncConflict:
            return "Your changes were saved locally. Sync will retry automatically."
        case .cloudKitFailure:
            return "Check your iCloud settings and internet connection."
        case .authenticationRequired:
            return "Sign in to iCloud in Settings."
        case .quotaExceeded:
            return "Free up iCloud storage or upgrade your plan."

        // Permissions
        case .permissionDenied(let permission):
            return "Enable \(permission.displayName) in Settings > \(Bundle.main.displayName ?? "App")."
        case .notificationPermissionDenied:
            return "Enable notifications in Settings to receive reminders."

        // In-App Purchase
        case .purchaseFailed:
            return "Check your payment method and try again."
        case .productNotFound:
            return "This product is temporarily unavailable. Try again later."
        case .receiptValidationFailed:
            return "Your purchase will be restored automatically. Contact support if the problem persists."
        case .restoreFailed:
            return "Make sure you're signed in with the correct Apple ID."

        // Validation
        case .validationError, .invalidInput:
            return "Please correct the highlighted fields."
        case .dateRangeInvalid:
            return "End time must be after start time."
        case .requiredFieldMissing:
            return "Please fill in all required fields."

        // State Management
        case .appInterrupted:
            return "Your progress was saved. You can continue from where you left off."
        case .stateRestorationFailed:
            return "Start fresh from the main screen."
        case .concurrentModification:
            return "Refresh to see the latest changes."

        // System
        case .lowStorage:
            return "Free up space by deleting unused apps or files."
        case .lowMemory:
            return "Close other apps and try again."
        case .backgroundTaskFailed:
            return "Background sync will retry automatically."

        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }

    // MARK: - Helper Methods

    /// Whether this error can be retried
    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .cloudKitFailure, .syncConflict,
             .storageFailure, .backgroundTaskFailed:
            return true
        case .dataCorruption, .constraintViolation, .validationError,
             .invalidInput, .dateRangeInvalid, .requiredFieldMissing:
            return false
        default:
            return true
        }
    }

    /// Whether this error should be reported to analytics
    public var shouldReport: Bool {
        switch self {
        case .validationError, .invalidInput, .dateRangeInvalid,
             .requiredFieldMissing, .networkUnavailable:
            return false // User errors, not bugs
        case .dataCorruption, .storageFailure, .constraintViolation,
             .stateRestorationFailed, .concurrentModification:
            return true // Critical issues
        default:
            return true
        }
    }

    /// Severity level for logging
    public var severity: ErrorSeverity {
        switch self {
        case .dataCorruption, .storageFailure, .stateRestorationFailed:
            return .critical
        case .cloudKitFailure, .syncConflict, .concurrentModification:
            return .error
        case .networkUnavailable, .permissionDenied, .validationError:
            return .warning
        default:
            return .info
        }
    }
}

// MARK: - Supporting Types

public enum Permission {
    case notifications
    case cloudKit
    case camera
    case photos

    public var displayName: String {
        switch self {
        case .notifications: return "Notifications"
        case .cloudKit: return "iCloud"
        case .camera: return "Camera"
        case .photos: return "Photos"
        }
    }
}

public enum ErrorSeverity: String {
    case critical = "CRITICAL"
    case error = "ERROR"
    case warning = "WARNING"
    case info = "INFO"
}

// MARK: - Error Mapping

public extension AppError {
    /// Convert domain-specific errors to AppError
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        // Map common system errors
        let nsError = error as NSError

        // CoreData errors
        if nsError.domain == "NSCocoaErrorDomain" {
            switch nsError.code {
            case 134030, 134060, 134090: // Validation, merge, constraint errors
                return .constraintViolation(field: "data", reason: nsError.localizedDescription)
            case 134020: // Not found
                return .notFound(entity: "record", id: "unknown")
            default:
                return .storageFailure(underlying: error)
            }
        }

        // CloudKit errors
        if nsError.domain == "CKErrorDomain" {
            switch nsError.code {
            case 1: // Internal error
                return .cloudKitFailure(underlying: error)
            case 3: // Network unavailable
                return .networkUnavailable
            case 9: // Not authenticated
                return .authenticationRequired
            case 25: // Quota exceeded
                return .quotaExceeded
            default:
                return .cloudKitFailure(underlying: error)
            }
        }

        // Network errors
        if nsError.domain == "NSURLErrorDomain" {
            return .networkUnavailable
        }

        return .unknown(error)
    }
}

// MARK: - Bundle Extension

private extension Bundle {
    var displayName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
