import SwiftUI

public enum AppCopy {
    private static func localized(_ key: String, _ arguments: CVarArg...) -> String {
        // Try main bundle first (for app-level localizations)
        let mainFormat = NSLocalizedString(key, tableName: nil, bundle: .main, comment: "")
        let format: String

        if mainFormat != key {
            // Found in main bundle
            format = mainFormat
        } else {
            // Try module bundle (Content_Content.bundle)
            format = NSLocalizedString(key, tableName: nil, bundle: .module, comment: "")
            if format == key {
                print("⚠️ Localization key not found: \(key)")
            }
        }

        if arguments.isEmpty {
            return format
        }
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    public static func string(for key: String) -> String {
        localized(key)
    }

    public static func text(for key: String) -> Text {
        Text(verbatim: localized(key))
    }

    public enum Timeline {
        public static let title = LocalizedStringKey("timeline.title")
        public static let searchPlaceholder = LocalizedStringKey("timeline.search.placeholder")
        public static let emptyTitle = LocalizedStringKey("timeline.empty.title")
        public static let emptyMessage = LocalizedStringKey("timeline.empty.message")
        public static let emptyAction = LocalizedStringKey("timeline.empty.action")
        public static let filterAll = LocalizedStringKey("timeline.filter.all")
        public static let filterEvents = LocalizedStringKey("timeline.filter.events")
        public static let filterMeasurements = LocalizedStringKey("timeline.filter.measurements")

        public static func eventsCount(_ count: Int) -> String {
            AppCopy.localized("timeline.summary.events", count)
        }

        public static func measurementsCount(_ count: Int) -> String {
            AppCopy.localized("timeline.summary.measurements", count)
        }
    }

    public enum Events {
        public static let formTitleNew = LocalizedStringKey("event.form.title.new")
        public static let formTitleEdit = LocalizedStringKey("event.form.title.edit")
        public static let start = LocalizedStringKey("event.form.start")
        public static let end = LocalizedStringKey("event.form.end")
        public static let duration = LocalizedStringKey("event.form.duration")
        public static let notes = LocalizedStringKey("event.form.notes")
        public static let save = LocalizedStringKey("event.form.save")
        public static let cancel = LocalizedStringKey("event.form.cancel")
        public static let deleteMessage = LocalizedStringKey("event.delete.message")
        public static let deleteUndo = LocalizedStringKey("event.delete.undo")
        public static let validationKind = LocalizedStringKey("event.form.validation.kind")
        public static let validationEnd = LocalizedStringKey("event.form.validation.endBeforeStart")

        public static func label(for kind: EventCopy.Kind) -> LocalizedStringKey {
            LocalizedStringKey(kind.rawValue)
        }
    }

    public enum Measurements {
        public static let title = LocalizedStringKey("measurements.title")
        public static let add = LocalizedStringKey("measurements.add")
        public static let formTitle = LocalizedStringKey("measurements.form.title")
        public static let type = LocalizedStringKey("measurements.form.type")
        public static let value = LocalizedStringKey("measurements.form.value")
        public static let unit = LocalizedStringKey("measurements.form.unit")
        public static let date = LocalizedStringKey("measurements.form.date")
        public static let emptyTitle = LocalizedStringKey("measurements.list.empty")
        public static let emptyMessage = LocalizedStringKey("measurements.list.empty.message")
        public static let growthTitle = LocalizedStringKey("measurements.growth.title")
        public static let growthSubtitle = LocalizedStringKey("measurements.growth.subtitle")
        public static let premiumMessage = LocalizedStringKey("measurements.growth.premium")

        public static func label(for type: MeasurementCopy.Kind) -> LocalizedStringKey {
            LocalizedStringKey(type.rawValue)
        }
    }

    public enum PaywallCopy {
        public static let title = LocalizedStringKey("paywall.title")
        public static let subtitle = LocalizedStringKey("paywall.subtitle")
        public static let loading = LocalizedStringKey("paywall.loading")
        public static let error = LocalizedStringKey("paywall.error.generic")
        public static let restore = LocalizedStringKey("paywall.restore")
        public static let restoreDescription = LocalizedStringKey("paywall.restore.description")
        public static let restoreSuccess = LocalizedStringKey("paywall.restore.success")
        public static let charts = LocalizedStringKey("paywall.feature.charts")
        public static let export = LocalizedStringKey("paywall.feature.export")
        public static let sync = LocalizedStringKey("paywall.feature.sync")
    }

    public enum SettingsCopy {
        public static let title = LocalizedStringKey("settings.title")
        public static let language = LocalizedStringKey("settings.language")
        public static let languageSystem = LocalizedStringKey("settings.language.system")
        public static let languageEnglish = LocalizedStringKey("settings.language.english")
        public static let languageRussian = LocalizedStringKey("settings.language.russian")
        public static let premiumStatus = LocalizedStringKey("settings.premium.status")
        public static let premiumActive = LocalizedStringKey("settings.premium.active")
        public static let premiumInactive = LocalizedStringKey("settings.premium.inactive")
        public static let export = LocalizedStringKey("settings.export")
        public static let manage = LocalizedStringKey("settings.premium.manage")
    }

    public enum Errors {
        public static let generic = LocalizedStringKey("errors.generic")
        public static let coreData = LocalizedStringKey("errors.coredata")
        public static let validation = LocalizedStringKey("errors.validation")
        public static let purchase = LocalizedStringKey("errors.purchase.failed")
        public static let network = LocalizedStringKey("errors.network.restricted")
    }

    public enum Notifications {
        public static let feedReminder = LocalizedStringKey("notification.feed.reminder")
        public static let feedBody = LocalizedStringKey("notification.feed.body")
        public static let sleepReminder = LocalizedStringKey("notification.sleep.reminder")
        public static let sleepBody = LocalizedStringKey("notification.sleep.body")
        public static let diaperReminder = LocalizedStringKey("notification.diaper.reminder")
        public static let diaperBody = LocalizedStringKey("notification.diaper.body")
        public static let requestTitle = LocalizedStringKey("notification.request.title")
        public static let requestMessage = LocalizedStringKey("notification.request.message")
        public static let quietHours = LocalizedStringKey("notification.quietHours")
        public static let quietHoursDescription = LocalizedStringKey("notification.quietHours.description")
    }

    public enum Common {
        public static let add = LocalizedStringKey("common.add")
        public static let edit = LocalizedStringKey("common.edit")
        public static let delete = LocalizedStringKey("common.delete")
        public static let save = LocalizedStringKey("common.save")
        public static let cancel = LocalizedStringKey("common.cancel")
        public static let dismiss = LocalizedStringKey("common.dismiss")
        public static let ok = LocalizedStringKey("common.ok")
        public static let loading = LocalizedStringKey("common.loading")
        public static let tryAgain = LocalizedStringKey("common.tryAgain")
    }

    public enum MainTabs {
        public static let timeline = LocalizedStringKey("main.tab.timeline")
        public static let add = LocalizedStringKey("main.tab.add")
        public static let measurements = LocalizedStringKey("main.tab.measurements")
        public static let settings = LocalizedStringKey("main.tab.settings")
    }

    public enum WatchApp {
        public static let quickLogTitle = LocalizedStringKey("watch.quicklog.title")
        public static let recentTitle = LocalizedStringKey("watch.recent.title")
        public static let measureTitle = LocalizedStringKey("watch.measure.title")
        public static let tabLog = LocalizedStringKey("watch.tab.log")
        public static let tabHistory = LocalizedStringKey("watch.tab.history")
        public static let tabMeasure = LocalizedStringKey("watch.tab.measure")
    }
}

public enum EventCopy {
    public enum Kind: String {
        case sleep = "event.kind.sleep"
        case feed = "event.kind.feed"
        case diaper = "event.kind.diaper"
    }
}

public enum MeasurementCopy {
    public enum Kind: String {
        case height = "measurement.type.height"
        case weight = "measurement.type.weight"
        case head = "measurement.type.head"
    }
}
