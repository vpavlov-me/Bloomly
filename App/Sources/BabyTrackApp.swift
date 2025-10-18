//
//  BabyTrackApp.swift
//  BabyTrack
//
//  Application entry point configuring dependency graph.
//

import SwiftUI
import Tracking
import Timeline
import Measurements
import Paywall
import Content
import DesignSystem

@main
struct BabyTrackApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            TabView {
                TimelineView(viewModel: TimelineViewModel(
                    eventsRepository: environment.eventsRepository,
                    measurementsRepository: environment.measurementsRepository
                ))
                .tabItem {
                    Label("Timeline", systemImage: "list.bullet")
                }

                PaywallView(viewModel: PaywallViewModel(storeClient: environment.storeClient))
                    .tabItem {
                        Label("Premium", systemImage: "star")
                    }
            }
            .environmentObject(environment)
        }
    }
}
