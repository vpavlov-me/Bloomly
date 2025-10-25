import Foundation
import SwiftUI

/// Represents a baby's profile information
public struct BabyProfile: Codable, Identifiable {
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

    // MARK: - Computed Properties

    /// Age in days from birth date
    public var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
    }

    /// Age in weeks from birth date
    public var ageInWeeks: Int {
        ageInDays / 7
    }

    /// Age in months from birth date
    public var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }

    /// Formatted age string based on age
    public var ageText: String {
        if ageInDays <= 7 {
            // 0-7 days: "X days old"
            return ageInDays == 1 ? "1 day old" : "\(ageInDays) days old"
        } else if ageInDays <= 90 {
            // 7-90 days: "X weeks old"
            return ageInWeeks == 1 ? "1 week old" : "\(ageInWeeks) weeks old"
        } else {
            // 90+ days: "X months old"
            return ageInMonths == 1 ? "1 month old" : "\(ageInMonths) months old"
        }
    }

    /// Baby's profile photo as UIImage
    public var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }

    // MARK: - Mutating Methods

    public mutating func updateName(_ newName: String) {
        name = newName
        updatedAt = Date()
    }

    public mutating func updatePhoto(_ image: UIImage?) {
        photoData = image?.jpegData(compressionQuality: 0.8)
        updatedAt = Date()
    }
}

/// Manages baby profile storage and retrieval
@MainActor
public final class BabyProfileStore: ObservableObject {
    public static let shared = BabyProfileStore()

    @Published public private(set) var currentProfile: BabyProfile?

    private let defaults = UserDefaults.standard
    private let profileKey = "baby.profile.current"

    private init() {
        loadProfile()
    }

    // MARK: - Public Methods

    /// Save or update the baby profile
    public func saveProfile(_ profile: BabyProfile) {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        if let encoded = try? JSONEncoder().encode(updatedProfile) {
            defaults.set(encoded, forKey: profileKey)
            currentProfile = updatedProfile
        }
    }

    /// Load the baby profile from storage
    public func loadProfile() {
        guard let data = defaults.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(BabyProfile.self, from: data) else {
            currentProfile = nil
            return
        }
        currentProfile = profile
    }

    /// Delete the current baby profile
    public func deleteProfile() {
        defaults.removeObject(forKey: profileKey)
        currentProfile = nil
    }

    /// Check if a profile exists
    public var hasProfile: Bool {
        currentProfile != nil
    }

    /// Create a new profile
    public func createProfile(name: String, birthDate: Date, photo: UIImage? = nil) -> BabyProfile {
        let profile = BabyProfile(
            name: name,
            birthDate: birthDate,
            photoData: photo?.jpegData(compressionQuality: 0.8)
        )
        saveProfile(profile)
        return profile
    }

    /// Update existing profile
    public func updateProfile(name: String? = nil, photo: UIImage? = nil) {
        guard var profile = currentProfile else { return }

        if let name = name {
            profile.updateName(name)
        }

        if let photo = photo {
            profile.updatePhoto(photo)
        }

        saveProfile(profile)
    }
}
