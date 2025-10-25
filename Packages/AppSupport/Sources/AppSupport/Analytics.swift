import Foundation

public struct AnalyticsEvent: Sendable {
    public let name: String
    public let metadata: [String: String]

    public init(name: String, metadata: [String: String] = [:]) {
        self.name = name
        self.metadata = metadata
    }
}

public protocol Analytics: Sendable {
    func track(_ event: AnalyticsEvent)
}
