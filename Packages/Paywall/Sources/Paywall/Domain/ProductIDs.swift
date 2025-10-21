import Foundation

public enum ProductIDs {
    public static let monthly = "com.example.babytrack.premium.monthly"
    public static let yearly = "com.example.babytrack.premium.yearly"

    public static var all: [String] { [monthly, yearly] }
}
