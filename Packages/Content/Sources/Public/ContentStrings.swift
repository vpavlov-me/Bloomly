import Foundation

public enum ContentStrings {
    public static func localized(_ key: String, table: String? = nil) -> String {
        NSLocalizedString(key, tableName: table, bundle: .module, comment: "")
    }
}

public enum ProductIdentifiers: String, CaseIterable {
    case premiumMonthly = "com.example.babytrack.premium.monthly"
    case premiumAnnual = "com.example.babytrack.premium.annual"
}
