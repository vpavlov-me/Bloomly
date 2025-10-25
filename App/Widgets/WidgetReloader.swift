import Foundation
import WidgetKit

/// Manages widget timeline reloads when app data changes
@MainActor
public final class WidgetReloader {
    public static let shared = WidgetReloader()

    private init() {}

    /// Reload all widgets
    public func reloadAll() {
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// Reload specific widget kind
    public func reload(kind: String) {
        #if os(iOS)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }

    /// Reload widgets after significant event
    public func reloadAfterEvent() {
        // Small delay to ensure data is saved
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            reloadAll()
        }
    }
}
