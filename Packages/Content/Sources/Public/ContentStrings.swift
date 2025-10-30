import Foundation

public enum ContentStrings {
    public static func localized(_ key: String, table: String? = nil) -> String {
        NSLocalizedString(key, tableName: table, bundle: .module, comment: "")
    }
}

public enum ProductIdentifiers: String, CaseIterable {
    case premiumMonthly = "com.vibecoding.bloomly.premium.monthly"
    case premiumAnnual = "com.vibecoding.bloomly.premium.annual"
}
