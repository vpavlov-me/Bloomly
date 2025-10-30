import CloudKit
import Dispatch
import Foundation

public protocol CloudKitTokenStore: Sendable {
    func serverChangeToken(forKey key: String) -> CKServerChangeToken?
    func setServerChangeToken(_ token: CKServerChangeToken?, forKey key: String)
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

public final class UserDefaultsTokenStore {
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.vibecoding.bloomly.cloudkit-token-store")

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

extension UserDefaultsTokenStore: CloudKitTokenStore {
    public func serverChangeToken(forKey key: String) -> CKServerChangeToken? {
        queue.sync {
            guard let data = defaults.data(forKey: key) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
        }
    }

    public func setServerChangeToken(_ token: CKServerChangeToken?, forKey key: String) {
        queue.sync {
            if let token,
               let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                defaults.set(data, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    public func bool(forKey key: String) -> Bool {
        queue.sync {
            defaults.bool(forKey: key)
        }
    }

    public func set(_ value: Bool, forKey key: String) {
        queue.sync {
            defaults.set(value, forKey: key)
        }
    }
}

extension UserDefaultsTokenStore: @unchecked Sendable {}
