// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum BloomlyStrings: Sendable {

  public enum Accessibility: Sendable {
  /// Add new event
    public static let addEvent = BloomlyStrings.tr("Localizable", "accessibility.add_event")
    /// Back
    public static let back = BloomlyStrings.tr("Localizable", "accessibility.back")
    /// Close
    public static let close = BloomlyStrings.tr("Localizable", "accessibility.close")
    /// Delete event
    public static let deleteEvent = BloomlyStrings.tr("Localizable", "accessibility.delete_event")
    /// Edit event
    public static let editEvent = BloomlyStrings.tr("Localizable", "accessibility.edit_event")
    /// Export data
    public static let exportData = BloomlyStrings.tr("Localizable", "accessibility.export_data")
    /// Filter events
    public static let filterEvents = BloomlyStrings.tr("Localizable", "accessibility.filter_events")
    /// Open settings
    public static let openSettings = BloomlyStrings.tr("Localizable", "accessibility.open_settings")
  }

  public enum Charts: Sendable {
  /// Date
    public static let date = BloomlyStrings.tr("Localizable", "charts.date")
    /// No measurements to display
    public static let empty = BloomlyStrings.tr("Localizable", "charts.empty")
    /// Head Circumference Chart
    public static let head = BloomlyStrings.tr("Localizable", "charts.head")
    /// Height Chart
    public static let height = BloomlyStrings.tr("Localizable", "charts.height")
    /// Percentile
    public static let percentile = BloomlyStrings.tr("Localizable", "charts.percentile")
    /// Growth Charts
    public static let title = BloomlyStrings.tr("Localizable", "charts.title")
    /// Value
    public static let value = BloomlyStrings.tr("Localizable", "charts.value")
    /// Weight Chart
    public static let weight = BloomlyStrings.tr("Localizable", "charts.weight")

    public enum Empty: Sendable {
    /// Add measurements to see growth charts
      public static let message = BloomlyStrings.tr("Localizable", "charts.empty.message")
    }
  }

  public enum Common: Sendable {
  /// Add
    public static let add = BloomlyStrings.tr("Localizable", "common.add")
    /// Cancel
    public static let cancel = BloomlyStrings.tr("Localizable", "common.cancel")
    /// Close
    public static let close = BloomlyStrings.tr("Localizable", "common.close")
    /// Delete
    public static let delete = BloomlyStrings.tr("Localizable", "common.delete")
    /// Done
    public static let done = BloomlyStrings.tr("Localizable", "common.done")
    /// Edit
    public static let edit = BloomlyStrings.tr("Localizable", "common.edit")
    /// Error
    public static let error = BloomlyStrings.tr("Localizable", "common.error")
    /// Loading...
    public static let loading = BloomlyStrings.tr("Localizable", "common.loading")
    /// Month
    public static let month = BloomlyStrings.tr("Localizable", "common.month")
    /// No
    public static let no = BloomlyStrings.tr("Localizable", "common.no")
    /// OK
    public static let ok = BloomlyStrings.tr("Localizable", "common.ok")
    /// Save
    public static let save = BloomlyStrings.tr("Localizable", "common.save")
    /// Success
    public static let success = BloomlyStrings.tr("Localizable", "common.success")
    /// Today
    public static let today = BloomlyStrings.tr("Localizable", "common.today")
    /// Week
    public static let week = BloomlyStrings.tr("Localizable", "common.week")
    /// Yes
    public static let yes = BloomlyStrings.tr("Localizable", "common.yes")
    /// Yesterday
    public static let yesterday = BloomlyStrings.tr("Localizable", "common.yesterday")
  }

  public enum Dashboard: Sendable {
  /// Quick Log
    public static let quickLog = BloomlyStrings.tr("Localizable", "dashboard.quickLog")
    /// Recent Activity
    public static let recentActivity = BloomlyStrings.tr("Localizable", "dashboard.recentActivity")
    /// Today's Summary
    public static let summary = BloomlyStrings.tr("Localizable", "dashboard.summary")
    /// Dashboard
    public static let title = BloomlyStrings.tr("Localizable", "dashboard.title")
  }

  public enum Date: Sendable {

    public enum Format: Sendable {
    /// MMMM d, yyyy
      public static let long = BloomlyStrings.tr("Localizable", "date.format.long")
      /// MMM d
      public static let short = BloomlyStrings.tr("Localizable", "date.format.short")
      /// h:mm a
      public static let time = BloomlyStrings.tr("Localizable", "date.format.time")
    }
  }

  public enum Errors: Sendable {
  /// Database error occurred
    public static let coredata = BloomlyStrings.tr("Localizable", "errors.coredata")
    /// Something went wrong. Please try again.
    public static let generic = BloomlyStrings.tr("Localizable", "errors.generic")
    /// Please check your input
    public static let validation = BloomlyStrings.tr("Localizable", "errors.validation")

    public enum Network: Sendable {
    /// Network connection required
      public static let restricted = BloomlyStrings.tr("Localizable", "errors.network.restricted")
    }

    public enum Purchase: Sendable {
    /// Purchase failed. Please try again.
      public static let failed = BloomlyStrings.tr("Localizable", "errors.purchase.failed")
    }
  }

  public enum Event: Sendable {

    public enum Delete: Sendable {
    /// Event deleted
      public static let message = BloomlyStrings.tr("Localizable", "event.delete.message")
      /// Undo
      public static let undo = BloomlyStrings.tr("Localizable", "event.delete.undo")
    }

    public enum Form: Sendable {
    /// Cancel
      public static let cancel = BloomlyStrings.tr("Localizable", "event.form.cancel")
      /// Duration
      public static let duration = BloomlyStrings.tr("Localizable", "event.form.duration")
      /// End Time
      public static let end = BloomlyStrings.tr("Localizable", "event.form.end")
      /// Notes
      public static let notes = BloomlyStrings.tr("Localizable", "event.form.notes")
      /// Save
      public static let save = BloomlyStrings.tr("Localizable", "event.form.save")
      /// Start Time
      public static let start = BloomlyStrings.tr("Localizable", "event.form.start")

      public enum Title: Sendable {
      /// Edit Event
        public static let edit = BloomlyStrings.tr("Localizable", "event.form.title.edit")
        /// New Event
        public static let new = BloomlyStrings.tr("Localizable", "event.form.title.new")
      }

      public enum Validation: Sendable {
      /// End time must be after start time
        public static let endBeforeStart = BloomlyStrings.tr("Localizable", "event.form.validation.endBeforeStart")
        /// Please select an event type
        public static let kind = BloomlyStrings.tr("Localizable", "event.form.validation.kind")
      }
    }

    public enum Kind: Sendable {
    /// Diaper
      public static let diaper = BloomlyStrings.tr("Localizable", "event.kind.diaper")
      /// Feeding
      public static let feed = BloomlyStrings.tr("Localizable", "event.kind.feed")
      /// Sleep
      public static let sleep = BloomlyStrings.tr("Localizable", "event.kind.sleep")
    }
  }

  public enum Export: Sendable {
  /// Date Range
    public static let dateRange = BloomlyStrings.tr("Localizable", "export.date_range")
    /// Failed to export data
    public static let error = BloomlyStrings.tr("Localizable", "export.error")
    /// Export
    public static let export = BloomlyStrings.tr("Localizable", "export.export")
    /// Export Format
    public static let format = BloomlyStrings.tr("Localizable", "export.format")
    /// Include Events
    public static let includeEvents = BloomlyStrings.tr("Localizable", "export.include_events")
    /// Include Measurements
    public static let includeMeasurements = BloomlyStrings.tr("Localizable", "export.include_measurements")
    /// Data exported successfully
    public static let success = BloomlyStrings.tr("Localizable", "export.success")
    /// Export Data
    public static let title = BloomlyStrings.tr("Localizable", "export.title")

    public enum DateRange: Sendable {
    /// All Time
      public static let all = BloomlyStrings.tr("Localizable", "export.date_range.all")
      /// Last Month
      public static let lastMonth = BloomlyStrings.tr("Localizable", "export.date_range.last_month")
      /// Last Week
      public static let lastWeek = BloomlyStrings.tr("Localizable", "export.date_range.last_week")
      /// Last Year
      public static let lastYear = BloomlyStrings.tr("Localizable", "export.date_range.last_year")
    }

    public enum Format: Sendable {
    /// CSV (Excel compatible)
      public static let csv = BloomlyStrings.tr("Localizable", "export.format.csv")
      /// JSON (Developer friendly)
      public static let json = BloomlyStrings.tr("Localizable", "export.format.json")
    }
  }

  public enum Main: Sendable {

    public enum Tab: Sendable {
    /// Add
      public static let add = BloomlyStrings.tr("Localizable", "main.tab.add")
      /// Profile
      public static let profile = BloomlyStrings.tr("Localizable", "main.tab.profile")
      /// Timeline
      public static let timeline = BloomlyStrings.tr("Localizable", "main.tab.timeline")
    }
  }

  public enum Measurement: Sendable {

    public enum `Type`: Sendable {
    /// Head Circumference
      public static let head = BloomlyStrings.tr("Localizable", "measurement.type.head")
      /// Height
      public static let height = BloomlyStrings.tr("Localizable", "measurement.type.height")
      /// Weight
      public static let weight = BloomlyStrings.tr("Localizable", "measurement.type.weight")
    }

    public enum Unit: Sendable {
    /// cm
      public static let cm = BloomlyStrings.tr("Localizable", "measurement.unit.cm")
      /// in
      public static let `in` = BloomlyStrings.tr("Localizable", "measurement.unit.in")
      /// kg
      public static let kg = BloomlyStrings.tr("Localizable", "measurement.unit.kg")
      /// lb
      public static let lb = BloomlyStrings.tr("Localizable", "measurement.unit.lb")
    }
  }

  public enum Measurements: Sendable {
  /// Add Measurement
    public static let add = BloomlyStrings.tr("Localizable", "measurements.add")
    /// Measurements
    public static let title = BloomlyStrings.tr("Localizable", "measurements.title")

    public enum Form: Sendable {
    /// Date
      public static let date = BloomlyStrings.tr("Localizable", "measurements.form.date")
      /// New Measurement
      public static let title = BloomlyStrings.tr("Localizable", "measurements.form.title")
      /// Type
      public static let type = BloomlyStrings.tr("Localizable", "measurements.form.type")
      /// Unit
      public static let unit = BloomlyStrings.tr("Localizable", "measurements.form.unit")
      /// Value
      public static let value = BloomlyStrings.tr("Localizable", "measurements.form.value")
    }

    public enum Growth: Sendable {
    /// Upgrade to Premium for growth charts
      public static let premium = BloomlyStrings.tr("Localizable", "measurements.growth.premium")
      /// Track development with WHO percentiles
      public static let subtitle = BloomlyStrings.tr("Localizable", "measurements.growth.subtitle")
      /// Growth Charts
      public static let title = BloomlyStrings.tr("Localizable", "measurements.growth.title")
    }

    public enum List: Sendable {
    /// No measurements
      public static let empty = BloomlyStrings.tr("Localizable", "measurements.list.empty")

      public enum Empty: Sendable {
      /// Track your baby's growth
        public static let message = BloomlyStrings.tr("Localizable", "measurements.list.empty.message")
      }
    }
  }

  public enum Notification: Sendable {

    public enum Permission: Sendable {
    /// Allow
      public static let allow = BloomlyStrings.tr("Localizable", "notification.permission.allow")
      /// Maybe Later
      public static let later = BloomlyStrings.tr("Localizable", "notification.permission.later")
      /// Get reminders for feeding and sleep times
      public static let message = BloomlyStrings.tr("Localizable", "notification.permission.message")
      /// Enable Notifications
      public static let title = BloomlyStrings.tr("Localizable", "notification.permission.title")
    }
  }

  public enum Onboarding: Sendable {
  /// Get Started
    public static let getStarted = BloomlyStrings.tr("Localizable", "onboarding.getStarted")
    /// Skip
    public static let skip = BloomlyStrings.tr("Localizable", "onboarding.skip")

    public enum Features: Sendable {
    /// Sleep, feeding, diapers, and measurements
      public static let subtitle = BloomlyStrings.tr("Localizable", "onboarding.features.subtitle")
      /// Everything you need
      public static let title = BloomlyStrings.tr("Localizable", "onboarding.features.title")
    }

    public enum Privacy: Sendable {
    /// All data stored securely on your device
      public static let subtitle = BloomlyStrings.tr("Localizable", "onboarding.privacy.subtitle")
      /// Your data stays private
      public static let title = BloomlyStrings.tr("Localizable", "onboarding.privacy.title")
    }

    public enum Welcome: Sendable {
    /// Track your baby's daily activities and growth
      public static let subtitle = BloomlyStrings.tr("Localizable", "onboarding.welcome.subtitle")
      /// Welcome to bloomy
      public static let title = BloomlyStrings.tr("Localizable", "onboarding.welcome.title")
    }
  }

  public enum Paywall: Sendable {
  /// Loading...
    public static let loading = BloomlyStrings.tr("Localizable", "paywall.loading")
    /// Privacy Policy
    public static let privacy = BloomlyStrings.tr("Localizable", "paywall.privacy")
    /// Restore Purchases
    public static let restore = BloomlyStrings.tr("Localizable", "paywall.restore")
    /// Unlock unlimited history and sync
    public static let subtitle = BloomlyStrings.tr("Localizable", "paywall.subtitle")
    /// Terms of Service
    public static let terms = BloomlyStrings.tr("Localizable", "paywall.terms")
    /// bloomy Premium
    public static let title = BloomlyStrings.tr("Localizable", "paywall.title")

    public enum Error: Sendable {
    /// Unable to load products. Please try again.
      public static let generic = BloomlyStrings.tr("Localizable", "paywall.error.generic")
    }

    public enum Feature: Sendable {
    /// Advanced growth charts with WHO percentiles
      public static let charts = BloomlyStrings.tr("Localizable", "paywall.feature.charts")
      /// Export all data to CSV or JSON
      public static let export = BloomlyStrings.tr("Localizable", "paywall.feature.export")
      /// Cloud sync across all your devices
      public static let sync = BloomlyStrings.tr("Localizable", "paywall.feature.sync")
    }

    public enum Price: Sendable {
    /// Monthly
      public static let monthly = BloomlyStrings.tr("Localizable", "paywall.price.monthly")
      /// Yearly
      public static let yearly = BloomlyStrings.tr("Localizable", "paywall.price.yearly")
    }

    public enum Restore: Sendable {
    /// Already purchased? Restore your subscription.
      public static let description = BloomlyStrings.tr("Localizable", "paywall.restore.description")
      /// Purchases restored successfully!
      public static let success = BloomlyStrings.tr("Localizable", "paywall.restore.success")
    }
  }

  public enum Profile: Sendable {
  /// Age
    public static let age = BloomlyStrings.tr("Localizable", "profile.age")
    /// Birth Date
    public static let birthdate = BloomlyStrings.tr("Localizable", "profile.birthdate")
    /// Create Profile
    public static let create = BloomlyStrings.tr("Localizable", "profile.create")
    /// Edit Profile
    public static let edit = BloomlyStrings.tr("Localizable", "profile.edit")
    /// Gender
    public static let gender = BloomlyStrings.tr("Localizable", "profile.gender")
    /// Baby's Name
    public static let name = BloomlyStrings.tr("Localizable", "profile.name")
    /// Photo
    public static let photo = BloomlyStrings.tr("Localizable", "profile.photo")
    /// Profile
    public static let title = BloomlyStrings.tr("Localizable", "profile.title")

    public enum Gender: Sendable {
    /// Girl
      public static let female = BloomlyStrings.tr("Localizable", "profile.gender.female")
      /// Boy
      public static let male = BloomlyStrings.tr("Localizable", "profile.gender.male")
    }
  }

  public enum Settings: Sendable {
  /// About
    public static let about = BloomlyStrings.tr("Localizable", "settings.about")
    /// Appearance
    public static let appearance = BloomlyStrings.tr("Localizable", "settings.appearance")
    /// Export Data
    public static let export = BloomlyStrings.tr("Localizable", "settings.export")
    /// Language
    public static let language = BloomlyStrings.tr("Localizable", "settings.language")
    /// Notifications
    public static let notifications = BloomlyStrings.tr("Localizable", "settings.notifications")
    /// Privacy
    public static let privacy = BloomlyStrings.tr("Localizable", "settings.privacy")
    /// Settings
    public static let title = BloomlyStrings.tr("Localizable", "settings.title")
    /// Version
    public static let version = BloomlyStrings.tr("Localizable", "settings.version")

    public enum About: Sendable {
    /// Privacy Policy
      public static let privacy = BloomlyStrings.tr("Localizable", "settings.about.privacy")
      /// Rate Bloomly
      public static let rate = BloomlyStrings.tr("Localizable", "settings.about.rate")
      /// Contact Support
      public static let support = BloomlyStrings.tr("Localizable", "settings.about.support")
      /// Terms of Service
      public static let terms = BloomlyStrings.tr("Localizable", "settings.about.terms")
      /// Version
      public static let version = BloomlyStrings.tr("Localizable", "settings.about.version")
    }

    public enum Appearance: Sendable {
    /// Dark
      public static let dark = BloomlyStrings.tr("Localizable", "settings.appearance.dark")
      /// Light
      public static let light = BloomlyStrings.tr("Localizable", "settings.appearance.light")
      /// System
      public static let system = BloomlyStrings.tr("Localizable", "settings.appearance.system")
      /// Theme
      public static let theme = BloomlyStrings.tr("Localizable", "settings.appearance.theme")
    }

    public enum Export: Sendable {
    /// Export as CSV
      public static let csv = BloomlyStrings.tr("Localizable", "settings.export.csv")
      /// Export as JSON
      public static let json = BloomlyStrings.tr("Localizable", "settings.export.json")
      /// Exporting...
      public static let progress = BloomlyStrings.tr("Localizable", "settings.export.progress")
      /// Export successful
      public static let success = BloomlyStrings.tr("Localizable", "settings.export.success")
    }

    public enum Language: Sendable {
    /// English
      public static let english = BloomlyStrings.tr("Localizable", "settings.language.english")
      /// Русский
      public static let russian = BloomlyStrings.tr("Localizable", "settings.language.russian")
      /// System Default
      public static let system = BloomlyStrings.tr("Localizable", "settings.language.system")
    }

    public enum Notifications: Sendable {

      public enum Diaper: Sendable {
      /// Diaper Reminders
        public static let enable = BloomlyStrings.tr("Localizable", "settings.notifications.diaper.enable")
      }

      public enum Feeding: Sendable {
      /// Feeding Reminders
        public static let enable = BloomlyStrings.tr("Localizable", "settings.notifications.feeding.enable")
      }

      public enum Sleep: Sendable {
      /// Sleep Reminders
        public static let enable = BloomlyStrings.tr("Localizable", "settings.notifications.sleep.enable")
      }
    }

    public enum Premium: Sendable {
    /// Active
      public static let active = BloomlyStrings.tr("Localizable", "settings.premium.active")
      /// Not Active
      public static let inactive = BloomlyStrings.tr("Localizable", "settings.premium.inactive")
      /// Manage Subscription
      public static let manage = BloomlyStrings.tr("Localizable", "settings.premium.manage")
      /// Premium Status
      public static let status = BloomlyStrings.tr("Localizable", "settings.premium.status")
    }

    public enum Privacy: Sendable {
    /// Share Analytics
      public static let analytics = BloomlyStrings.tr("Localizable", "settings.privacy.analytics")

      public enum Analytics: Sendable {
      /// Help us improve Bloomly
        public static let description = BloomlyStrings.tr("Localizable", "settings.privacy.analytics.description")
      }
    }
  }

  public enum Sync: Sendable {
  /// Disable Cloud Sync
    public static let disable = BloomlyStrings.tr("Localizable", "sync.disable")
    /// Enable Cloud Sync
    public static let enable = BloomlyStrings.tr("Localizable", "sync.enable")
    /// Sync Error
    public static let error = BloomlyStrings.tr("Localizable", "sync.error")
    /// Last synced: %@
    public static func lastSync(_ p1: Any) -> String {
      return BloomlyStrings.tr("Localizable", "sync.last_sync",String(describing: p1))
    }
    /// Never synced
    public static let neverSynced = BloomlyStrings.tr("Localizable", "sync.never_synced")
    /// Sync Status
    public static let status = BloomlyStrings.tr("Localizable", "sync.status")
    /// Synced
    public static let synced = BloomlyStrings.tr("Localizable", "sync.synced")
    /// Syncing...
    public static let syncing = BloomlyStrings.tr("Localizable", "sync.syncing")
    /// Cloud Sync
    public static let title = BloomlyStrings.tr("Localizable", "sync.title")
  }

  public enum Tab: Sendable {
  /// Charts
    public static let charts = BloomlyStrings.tr("Localizable", "tab.charts")
    /// Dashboard
    public static let dashboard = BloomlyStrings.tr("Localizable", "tab.dashboard")
    /// Settings
    public static let settings = BloomlyStrings.tr("Localizable", "tab.settings")
    /// Timeline
    public static let timeline = BloomlyStrings.tr("Localizable", "tab.timeline")
  }

  public enum Time: Sendable {
  /// %@ ago
    public static func ago(_ p1: Any) -> String {
      return BloomlyStrings.tr("Localizable", "time.ago",String(describing: p1))
    }
    /// Just now
    public static let justNow = BloomlyStrings.tr("Localizable", "time.just_now")

    public enum Hours: Sendable {
    /// hours
      public static let long = BloomlyStrings.tr("Localizable", "time.hours.long")
      /// h
      public static let short = BloomlyStrings.tr("Localizable", "time.hours.short")
    }

    public enum Minutes: Sendable {
    /// minutes
      public static let long = BloomlyStrings.tr("Localizable", "time.minutes.long")
      /// m
      public static let short = BloomlyStrings.tr("Localizable", "time.minutes.short")
    }

    public enum Seconds: Sendable {
    /// s
      public static let short = BloomlyStrings.tr("Localizable", "time.seconds.short")
    }
  }

  public enum Timeline: Sendable {
  /// Timeline
    public static let title = BloomlyStrings.tr("Localizable", "timeline.title")

    public enum Empty: Sendable {
    /// Add First Event
      public static let action = BloomlyStrings.tr("Localizable", "timeline.empty.action")
      /// Start tracking your baby's activities
      public static let message = BloomlyStrings.tr("Localizable", "timeline.empty.message")
      /// No events yet
      public static let title = BloomlyStrings.tr("Localizable", "timeline.empty.title")
    }

    public enum Filter: Sendable {
    /// All
      public static let all = BloomlyStrings.tr("Localizable", "timeline.filter.all")
      /// Events
      public static let events = BloomlyStrings.tr("Localizable", "timeline.filter.events")
      /// Measurements
      public static let measurements = BloomlyStrings.tr("Localizable", "timeline.filter.measurements")
    }

    public enum Search: Sendable {
    /// Search events...
      public static let placeholder = BloomlyStrings.tr("Localizable", "timeline.search.placeholder")
    }

    public enum Summary: Sendable {
    /// %d events
      public static func events(_ p1: Int) -> String {
        return BloomlyStrings.tr("Localizable", "timeline.summary.events",p1)
      }
      /// %d measurements
      public static func measurements(_ p1: Int) -> String {
        return BloomlyStrings.tr("Localizable", "timeline.summary.measurements",p1)
      }
    }
  }

  public enum Widgets: Sendable {
  /// Last Feeding
    public static let lastFeed = BloomlyStrings.tr("Localizable", "widgets.lastFeed")
    /// Sleep Today
    public static let sleepSummary = BloomlyStrings.tr("Localizable", "widgets.sleepSummary")

    public enum Description: Sendable {
    /// View your baby's last feeding time
      public static let feed = BloomlyStrings.tr("Localizable", "widgets.description.feed")
      /// Track today's sleep duration
      public static let sleep = BloomlyStrings.tr("Localizable", "widgets.description.sleep")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension BloomlyStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
// swiftformat:enable all
// swiftlint:enable all
