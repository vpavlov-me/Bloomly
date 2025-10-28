import Foundation
import SwiftUI

/// Global app settings manager using UserDefaults
@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Appearance

    @Published public var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
            applyAppearance()
        }
    }

    // MARK: - Language

    @Published public var preferredLanguage: LanguageOption {
        didSet {
            defaults.set(preferredLanguage.rawValue, forKey: Keys.preferredLanguage)
        }
    }

    // MARK: - Notifications

    @Published public var feedingReminderInterval: ReminderInterval {
        didSet {
            defaults.set(feedingReminderInterval.rawValue, forKey: Keys.feedingReminderInterval)
        }
    }

    @Published public var sleepReminderEnabled: Bool {
        didSet {
            defaults.set(sleepReminderEnabled, forKey: Keys.sleepReminderEnabled)
        }
    }

    @Published public var sleepReminderTime: Date {
        didSet {
            defaults.set(sleepReminderTime.timeIntervalSince1970, forKey: Keys.sleepReminderTime)
        }
    }

    // MARK: - Privacy

    @Published public var analyticsEnabled: Bool {
        didSet {
            defaults.set(analyticsEnabled, forKey: Keys.analyticsEnabled)
        }
    }

    // MARK: - Initialization

    private init() {
        // Load appearance
        if let modeString = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: modeString) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .auto
        }

        // Load language
        if let langString = defaults.string(forKey: Keys.preferredLanguage),
           let lang = LanguageOption(rawValue: langString) {
            self.preferredLanguage = lang
        } else {
            self.preferredLanguage = .system
        }

        // Load notifications
        if let intervalString = defaults.string(forKey: Keys.feedingReminderInterval),
           let interval = ReminderInterval(rawValue: intervalString) {
            self.feedingReminderInterval = interval
        } else {
            self.feedingReminderInterval = .threeHours
        }

        self.sleepReminderEnabled = defaults.bool(forKey: Keys.sleepReminderEnabled)

        if let timeInterval = defaults.object(forKey: Keys.sleepReminderTime) as? TimeInterval {
            self.sleepReminderTime = Date(timeIntervalSince1970: timeInterval)
        } else {
            // Default to 8 PM
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 20
            components.minute = 0
            self.sleepReminderTime = Calendar.current.date(from: components) ?? Date()
        }

        // Load privacy
        self.analyticsEnabled = defaults.object(forKey: Keys.analyticsEnabled) as? Bool ?? true

        applyAppearance()
    }

    // MARK: - Methods

    private func applyAppearance() {
        let style: UIUserInterfaceStyle
        switch appearanceMode {
        case .auto:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    public func resetToDefaults() {
        appearanceMode = .auto
        preferredLanguage = .system
        feedingReminderInterval = .threeHours
        sleepReminderEnabled = false
        analyticsEnabled = true
    }

    // MARK: - Keys

    private enum Keys {
        static let appearanceMode = "settings.appearance.mode"
        static let preferredLanguage = "settings.language.preferred"
        static let feedingReminderInterval = "settings.notifications.feeding.interval"
        static let sleepReminderEnabled = "settings.notifications.sleep.enabled"
        static let sleepReminderTime = "settings.notifications.sleep.time"
        static let analyticsEnabled = "settings.privacy.analytics"
    }
}

// MARK: - Enums

public enum AppearanceMode: String, CaseIterable, Identifiable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    public var localizedName: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

public enum LanguageOption: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case russian = "ru"

    public var id: String { rawValue }

    public var localizedName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .russian: return "Russian"
        }
    }
}

public enum ReminderInterval: String, CaseIterable, Identifiable {
    case twoHours = "2h"
    case threeHours = "3h"
    case fourHours = "4h"

    public var id: String { rawValue }

    public var localizedName: String {
        switch self {
        case .twoHours: return "Every 2 hours"
        case .threeHours: return "Every 3 hours"
        case .fourHours: return "Every 4 hours"
        }
    }

    public var timeInterval: TimeInterval {
        switch self {
        case .twoHours: return 2 * 3600
        case .threeHours: return 3 * 3600
        case .fourHours: return 4 * 3600
        }
    }
}
