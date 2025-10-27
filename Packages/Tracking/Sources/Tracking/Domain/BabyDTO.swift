import Foundation

/// Domain model representing a baby profile
public struct BabyDTO: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var birthDate: Date
    public var photoData: Data?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        photoData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.photoData = photoData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Age in months (rounded down)
    public var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }

    /// Age in days
    public var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
    }

    /// Formatted age string (e.g., "3 months", "2 weeks", "5 days")
    public var formattedAge: String {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: birthDate,
            to: Date()
        )

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if let days = components.day {
            if days >= 7 {
                let weeks = days / 7
                return weeks == 1 ? "1 week" : "\(weeks) weeks"
            } else {
                return days == 1 ? "1 day" : "\(days) days"
            }
        }
        return "0 days"
    }
}
