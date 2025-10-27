import Foundation

public enum BabyRepositoryError: LocalizedError {
    case notFound
    case validationFailed(reason: String)
    case photoProcessingFailed(Error)
    case persistence(Error)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Baby profile not found"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .photoProcessingFailed(let error):
            return "Photo processing failed: \(error.localizedDescription)"
        case .persistence(let error):
            return "Persistence error: \(error.localizedDescription)"
        }
    }
}

/// Repository protocol for baby profile management
public protocol BabyRepository: Sendable {
    /// Create a new baby profile
    /// - Parameter dto: Baby data transfer object
    /// - Returns: Created baby with generated ID
    /// - Throws: `BabyRepositoryError` if creation fails
    func create(_ dto: BabyDTO) async throws -> BabyDTO

    /// Read a baby profile by ID
    /// - Parameter id: Baby's unique identifier
    /// - Returns: Baby profile if found
    /// - Throws: `BabyRepositoryError.notFound` if baby doesn't exist
    func read(id: UUID) async throws -> BabyDTO

    /// Update an existing baby profile
    /// - Parameter dto: Updated baby data
    /// - Returns: Updated baby profile
    /// - Throws: `BabyRepositoryError` if update fails
    func update(_ dto: BabyDTO) async throws -> BabyDTO

    /// Soft delete a baby profile (marks as deleted but doesn't remove from database)
    /// - Parameter id: Baby's unique identifier
    /// - Throws: `BabyRepositoryError` if deletion fails
    func delete(id: UUID) async throws

    /// Fetch all non-deleted baby profiles
    /// - Returns: Array of all baby profiles
    /// - Throws: `BabyRepositoryError` if fetch fails
    func fetchAll() async throws -> [BabyDTO]

    /// Fetch the active baby (for single baby MVP)
    /// Returns the first non-deleted baby or nil if none exists
    /// - Returns: Active baby profile or nil
    /// - Throws: `BabyRepositoryError` if fetch fails
    func fetchActive() async throws -> BabyDTO?
}
