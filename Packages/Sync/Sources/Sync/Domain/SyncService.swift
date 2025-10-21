import Foundation

public enum ConflictResolutionStrategy {
    case lastWriteWins
}

public protocol SyncService: Sendable {
    func pullChanges() async
    func pushPending() async
    func resolveConflicts(_ strategy: ConflictResolutionStrategy) async
}

public protocol RecordMapper: Sendable {
    associatedtype LocalModel
    func toRecord(_ model: LocalModel) -> [String: Any]
    func merge(local: LocalModel, remote: [String: Any]) -> LocalModel
}
