import Foundation

/// Centralized accessibility identifiers for UI testing and VoiceOver
public enum AccessibilityIdentifiers {
    // MARK: - Tab Bar
    public enum TabBar {
        public static let timeline = "tab.timeline"
        public static let add = "tab.add"
        public static let measurements = "tab.measurements"
        public static let settings = "tab.settings"
    }

    // MARK: - Buttons
    public enum Button {
        public static let primary = "button.primary"
        public static let save = "button.save"
        public static let cancel = "button.cancel"
        public static let delete = "button.delete"
        public static let edit = "button.edit"
        public static let add = "button.add"
        public static let export = "button.export"
        public static let restore = "button.restore"
    }

    // MARK: - Forms
    public enum Form {
        public static let eventForm = "form.event"
        public static let measurementForm = "form.measurement"
        public static let startTime = "form.startTime"
        public static let endTime = "form.endTime"
        public static let notes = "form.notes"
        public static let value = "form.value"
        public static let unit = "form.unit"
    }

    // MARK: - Lists
    public enum List {
        public static let timeline = "list.timeline"
        public static let measurements = "list.measurements"
        public static let eventRow = "list.row.event"
        public static let measurementRow = "list.row.measurement"
    }

    // MARK: - Empty States
    public enum EmptyState {
        public static let icon = "emptyState.icon"
        public static let title = "emptyState.title"
        public static let message = "emptyState.message"
        public static let action = "emptyState.action"
    }

    // MARK: - Charts
    public enum Chart {
        public static let growth = "chart.growth"
        public static let height = "chart.height"
        public static let weight = "chart.weight"
        public static let head = "chart.head"
    }
}

/// Accessibility labels and hints for VoiceOver
public enum AccessibilityLabels {
    // MARK: - Tab Bar
    public enum TabBar {
        public static let timeline = "Timeline tab"
        public static let add = "Add new entry tab"
        public static let measurements = "Measurements tab"
        public static let settings = "Settings tab"
    }

    // MARK: - Buttons
    public enum Button {
        public static func save(context: String = "") -> String {
            context.isEmpty ? "Save" : "Save \(context)"
        }

        public static func cancel(context: String = "") -> String {
            context.isEmpty ? "Cancel" : "Cancel \(context)"
        }

        public static func delete(item: String) -> String {
            "Delete \(item)"
        }

        public static func edit(item: String) -> String {
            "Edit \(item)"
        }

        public static func add(item: String) -> String {
            "Add \(item)"
        }
    }

    // MARK: - Events
    public enum Event {
        public static func row(kind: String, time: String) -> String {
            "\(kind) event at \(time)"
        }

        public static func duration(value: String) -> String {
            "Duration: \(value)"
        }
    }

    // MARK: - Measurements
    public enum Measurement {
        public static func row(type: String, value: String, unit: String, date: String) -> String {
            "\(type): \(value) \(unit) on \(date)"
        }
    }

    // MARK: - Empty States
    public enum EmptyState {
        public static func message(title: String, description: String) -> String {
            "\(title). \(description)"
        }
    }
}

/// Accessibility hints for VoiceOver
public enum AccessibilityHints {
    // MARK: - Buttons
    public enum Button {
        public static let save = "Double tap to save changes"
        public static let cancel = "Double tap to discard changes"
        public static let delete = "Double tap to delete this item"
        public static let edit = "Double tap to edit this item"
        public static let add = "Double tap to add a new item"
    }

    // MARK: - Forms
    public enum Form {
        public static let timePicker = "Double tap to select time"
        public static let textField = "Double tap to edit text"
        public static let picker = "Double tap to show options"
    }

    // MARK: - Lists
    public enum List {
        public static let row = "Double tap to view details, swipe left for actions"
        public static let emptyState = "No items to display. Use the add button to create your first entry"
    }
}
