import Foundation
import SwiftUI

/// Deep link destinations from widgets
public enum WidgetDeepLink: String {
    case timeline = "timeline"
    case addFeed = "add-feed"
    case addSleep = "add-sleep"
    case addDiaper = "add-diaper"

    /// Create URL for widget deep link
    public var url: URL {
        URL(string: "bloomy://widget/\(rawValue)")!
    }

    /// Parse URL to deep link
    public static func parse(_ url: URL) -> WidgetDeepLink? {
        guard url.scheme == "bloomy",
              url.host == "widget",
              let path = url.pathComponents.last else {
            return nil
        }
        return WidgetDeepLink(rawValue: path)
    }
}

/// Environment key for widget deep link handling
struct WidgetDeepLinkKey: EnvironmentKey {
    static let defaultValue: ((WidgetDeepLink) -> Void)? = nil
}

extension EnvironmentValues {
    var handleWidgetDeepLink: ((WidgetDeepLink) -> Void)? {
        get { self[WidgetDeepLinkKey.self] }
        set { self[WidgetDeepLinkKey.self] = newValue }
    }
}

/// View modifier for handling widget deep links
struct WidgetDeepLinkHandler: ViewModifier {
    let handler: (WidgetDeepLink) -> Void

    func body(content: Content) -> some View {
        content
            .environment(\.handleWidgetDeepLink, handler)
            .onOpenURL { url in
                if let deepLink = WidgetDeepLink.parse(url) {
                    handler(deepLink)
                }
            }
    }
}

extension View {
    /// Handle widget deep links
    public func handleWidgetDeepLinks(_ handler: @escaping (WidgetDeepLink) -> Void) -> some View {
        modifier(WidgetDeepLinkHandler(handler: handler))
    }
}
