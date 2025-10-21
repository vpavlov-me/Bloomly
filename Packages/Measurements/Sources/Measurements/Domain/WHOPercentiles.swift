import Foundation

/// WHO Child Growth Standards percentile data
/// Source: WHO Multicentre Growth Reference Study (MGRS) 2006
public enum WHOPercentiles {
    /// Gender for percentile calculation
    public enum Gender {
        case male
        case female
    }

    /// Percentile curve data point
    public struct PercentilePoint {
        public let ageMonths: Int
        public let value: Double

        public init(ageMonths: Int, value: Double) {
            self.ageMonths = ageMonths
            self.value = value
        }
    }

    /// WHO standard percentile curves (3rd, 15th, 50th, 85th, 97th)
    public enum Curve: Int, CaseIterable {
        case p3 = 3
        case p15 = 15
        case p50 = 50
        case p85 = 85
        case p97 = 97

        public var label: String {
            "\(rawValue)th"
        }
    }

    // MARK: - Weight Percentiles (kg)

    /// Get weight percentile curve for gender
    public static func weightPercentile(for gender: Gender, curve: Curve) -> [PercentilePoint] {
        switch (gender, curve) {
        case (.male, .p50):
            return maleWeightP50
        case (.female, .p50):
            return femaleWeightP50
        case (.male, .p3):
            return maleWeightP3
        case (.female, .p3):
            return femaleWeightP3
        case (.male, .p97):
            return maleWeightP97
        case (.female, .p97):
            return femaleWeightP97
        default:
            // Simplified: return median for other curves
            return gender == .male ? maleWeightP50 : femaleWeightP50
        }
    }

    // MARK: - Height/Length Percentiles (cm)

    /// Get height percentile curve for gender
    public static func heightPercentile(for gender: Gender, curve: Curve) -> [PercentilePoint] {
        switch (gender, curve) {
        case (.male, .p50):
            return maleHeightP50
        case (.female, .p50):
            return femaleHeightP50
        case (.male, .p3):
            return maleHeightP3
        case (.female, .p3):
            return femaleHeightP3
        case (.male, .p97):
            return maleHeightP97
        case (.female, .p97):
            return femaleHeightP97
        default:
            return gender == .male ? maleHeightP50 : femaleHeightP50
        }
    }

    // MARK: - Head Circumference Percentiles (cm)

    /// Get head circumference percentile curve for gender
    public static func headPercentile(for gender: Gender, curve: Curve) -> [PercentilePoint] {
        switch (gender, curve) {
        case (.male, .p50):
            return maleHeadP50
        case (.female, .p50):
            return femaleHeadP50
        case (.male, .p3):
            return maleHeadP3
        case (.female, .p3):
            return femaleHeadP3
        case (.male, .p97):
            return maleHeadP97
        case (.female, .p97):
            return femaleHeadP97
        default:
            return gender == .male ? maleHeadP50 : femaleHeadP50
        }
    }

    // MARK: - Sample Data (0-24 months)
    // Note: This is simplified sample data. Production would use complete WHO tables.

    private static let maleWeightP50: [PercentilePoint] = [
        .init(ageMonths: 0, value: 3.3),
        .init(ageMonths: 1, value: 4.5),
        .init(ageMonths: 2, value: 5.6),
        .init(ageMonths: 3, value: 6.4),
        .init(ageMonths: 6, value: 7.9),
        .init(ageMonths: 9, value: 9.2),
        .init(ageMonths: 12, value: 10.2),
        .init(ageMonths: 18, value: 11.5),
        .init(ageMonths: 24, value: 12.5)
    ]

    private static let femaleWeightP50: [PercentilePoint] = [
        .init(ageMonths: 0, value: 3.2),
        .init(ageMonths: 1, value: 4.2),
        .init(ageMonths: 2, value: 5.1),
        .init(ageMonths: 3, value: 5.8),
        .init(ageMonths: 6, value: 7.3),
        .init(ageMonths: 9, value: 8.6),
        .init(ageMonths: 12, value: 9.5),
        .init(ageMonths: 18, value: 10.8),
        .init(ageMonths: 24, value: 11.8)
    ]

    private static let maleWeightP3: [PercentilePoint] = [
        .init(ageMonths: 0, value: 2.5),
        .init(ageMonths: 3, value: 5.0),
        .init(ageMonths: 6, value: 6.4),
        .init(ageMonths: 12, value: 8.4),
        .init(ageMonths: 24, value: 10.3)
    ]

    private static let femaleWeightP3: [PercentilePoint] = [
        .init(ageMonths: 0, value: 2.4),
        .init(ageMonths: 3, value: 4.5),
        .init(ageMonths: 6, value: 5.9),
        .init(ageMonths: 12, value: 7.8),
        .init(ageMonths: 24, value: 9.7)
    ]

    private static let maleWeightP97: [PercentilePoint] = [
        .init(ageMonths: 0, value: 4.3),
        .init(ageMonths: 3, value: 7.9),
        .init(ageMonths: 6, value: 9.7),
        .init(ageMonths: 12, value: 12.3),
        .init(ageMonths: 24, value: 15.0)
    ]

    private static let femaleWeightP97: [PercentilePoint] = [
        .init(ageMonths: 0, value: 4.2),
        .init(ageMonths: 3, value: 7.4),
        .init(ageMonths: 6, value: 9.0),
        .init(ageMonths: 12, value: 11.5),
        .init(ageMonths: 24, value: 14.2)
    ]

    private static let maleHeightP50: [PercentilePoint] = [
        .init(ageMonths: 0, value: 49.9),
        .init(ageMonths: 1, value: 54.7),
        .init(ageMonths: 3, value: 61.4),
        .init(ageMonths: 6, value: 67.6),
        .init(ageMonths: 12, value: 75.7),
        .init(ageMonths: 18, value: 82.3),
        .init(ageMonths: 24, value: 87.1)
    ]

    private static let femaleHeightP50: [PercentilePoint] = [
        .init(ageMonths: 0, value: 49.1),
        .init(ageMonths: 1, value: 53.7),
        .init(ageMonths: 3, value: 59.8),
        .init(ageMonths: 6, value: 65.7),
        .init(ageMonths: 12, value: 74.0),
        .init(ageMonths: 18, value: 80.7),
        .init(ageMonths: 24, value: 85.7)
    ]

    private static let maleHeightP3: [PercentilePoint] = [
        .init(ageMonths: 0, value: 46.1),
        .init(ageMonths: 6, value: 63.3),
        .init(ageMonths: 12, value: 71.0),
        .init(ageMonths: 24, value: 81.7)
    ]

    private static let femaleHeightP3: [PercentilePoint] = [
        .init(ageMonths: 0, value: 45.4),
        .init(ageMonths: 6, value: 61.5),
        .init(ageMonths: 12, value: 69.2),
        .init(ageMonths: 24, value: 80.0)
    ]

    private static let maleHeightP97: [PercentilePoint] = [
        .init(ageMonths: 0, value: 53.7),
        .init(ageMonths: 6, value: 72.0),
        .init(ageMonths: 12, value: 80.5),
        .init(ageMonths: 24, value: 92.9)
    ]

    private static let femaleHeightP97: [PercentilePoint] = [
        .init(ageMonths: 0, value: 52.9),
        .init(ageMonths: 6, value: 70.0),
        .init(ageMonths: 12, value: 78.9),
        .init(ageMonths: 24, value: 91.4)
    ]

    private static let maleHeadP50: [PercentilePoint] = [
        .init(ageMonths: 0, value: 34.5),
        .init(ageMonths: 3, value: 40.5),
        .init(ageMonths: 6, value: 43.3),
        .init(ageMonths: 12, value: 46.1),
        .init(ageMonths: 24, value: 48.3)
    ]

    private static let femaleHeadP50: [PercentilePoint] = [
        .init(ageMonths: 0, value: 33.9),
        .init(ageMonths: 3, value: 39.5),
        .init(ageMonths: 6, value: 42.2),
        .init(ageMonths: 12, value: 45.0),
        .init(ageMonths: 24, value: 47.2)
    ]

    private static let maleHeadP3: [PercentilePoint] = [
        .init(ageMonths: 0, value: 32.1),
        .init(ageMonths: 6, value: 40.9),
        .init(ageMonths: 12, value: 43.8),
        .init(ageMonths: 24, value: 46.0)
    ]

    private static let femaleHeadP3: [PercentilePoint] = [
        .init(ageMonths: 0, value: 31.5),
        .init(ageMonths: 6, value: 39.8),
        .init(ageMonths: 12, value: 42.7),
        .init(ageMonths: 24, value: 44.9)
    ]

    private static let maleHeadP97: [PercentilePoint] = [
        .init(ageMonths: 0, value: 37.0),
        .init(ageMonths: 6, value: 45.8),
        .init(ageMonths: 12, value: 48.5),
        .init(ageMonths: 24, value: 50.7)
    ]

    private static let femaleHeadP97: [PercentilePoint] = [
        .init(ageMonths: 0, value: 36.2),
        .init(ageMonths: 6, value: 44.7),
        .init(ageMonths: 12, value: 47.3),
        .init(ageMonths: 24, value: 49.6)
    ]
}
