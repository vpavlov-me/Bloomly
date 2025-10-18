//
//  WatchDashboardView.swift
//  BabyTrack
//
//  Minimal watchOS dashboard for quick logging and recents.
//

import SwiftUI
import Tracking
import Content
import DesignSystem

public struct WatchDashboardView: View {
    let events: [Event]
    let logAction: (EventKind) -> Void

    public init(events: [Event], logAction: @escaping (EventKind) -> Void) {
        self.events = events
        self.logAction = logAction
    }

    public func trigger(kind: EventKind) {
        logAction(kind)
    }

    public var body: some View {
        List {
            Section("Quick Log") {
                ForEach(EventKind.allCases, id: \.self) { kind in
                    Button(kind.rawValue.capitalized) {
                        logAction(kind)
                    }
                }
            }

            Section("Recent") {
                if events.isEmpty {
                    Text(L10n.timelineEmptyState())
                } else {
                    ForEach(events.prefix(5)) { event in
                        VStack(alignment: .leading) {
                            Text(event.kind.rawValue.capitalized)
                                .font(.headline)
                            Text(event.start, style: .time)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
