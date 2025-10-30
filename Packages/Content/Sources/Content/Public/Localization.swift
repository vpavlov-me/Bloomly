//
//  Localization.swift
//  bloomy
//
//  Provides typed accessors to localized strings.
//

import Foundation

public enum L10n {
    public static func paywallTitle(locale: Locale = .current) -> String {
        NSLocalizedString("paywall.title", bundle: .module, comment: "Paywall title")
    }

    public static func paywallSubtitle(locale: Locale = .current) -> String {
        NSLocalizedString("paywall.subtitle", bundle: .module, comment: "Paywall subtitle")
    }

    public static func timelineEmptyState(locale: Locale = .current) -> String {
        NSLocalizedString("timeline.empty", bundle: .module, comment: "Timeline empty state")
    }

    public static func widgetsLastFeed(locale: Locale = .current) -> String {
        NSLocalizedString("widgets.lastFeed", bundle: .module, comment: "Widget last feed label")
    }

    public static func widgetsSleepSummary(locale: Locale = .current) -> String {
        NSLocalizedString("widgets.sleepSummary", bundle: .module, comment: "Widget sleep summary label")
    }
}
