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
    @StateObject private var store: WatchDataStore

    public init(store: @autoclosure @escaping () -> WatchDataStore = WatchDataStore.init) {
        _store = StateObject(wrappedValue: store())
    }

    public var body: some View {
        List {
            Section("Quick Log") {
                ForEach(EventKind.allCases, id: \.self) { kind in
                    Button(kind.rawValue.capitalized) {
                        store.log(kind: kind)
                    }
                }
            }

            Section("Recent") {
                if store.events.isEmpty {
                    Text(L10n.timelineEmptyState())
                } else {
                    ForEach(store.events.prefix(5)) { event in
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
        .onAppear { store.fetchRecentEvents(limit: 5) }
    }
}
