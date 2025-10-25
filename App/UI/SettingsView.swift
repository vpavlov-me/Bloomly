import Content
import DesignSystem
import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var container: DependencyContainer
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var notificationManager: NotificationManager

    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var toastMessage: ToastMessage?

    private let exportService: DataExportService

    public init(container: DependencyContainer) {
        self._container = ObservedObject(initialValue: container)
        self._notificationManager = ObservedObject(initialValue: container.notificationManager)
        self.exportService = DataExportService(
            eventsRepository: container.eventsRepository,
            measurementsRepository: container.measurementsRepository
        )
    }

    public var body: some View {
        Form {
            // MARK: - Notifications Section
            Section {
                Toggle(AppCopy.string(for: "settings.notifications.enable"), isOn: $notificationManager.isNotificationEnabled)
                    .onChange(of: notificationManager.isNotificationEnabled) { _, newValue in
                        if newValue {
                            Task {
                                await notificationManager.requestNotificationPermission()
                            }
                        }
                    }

                if notificationManager.isNotificationEnabled {
                    Picker(AppCopy.string(for: "settings.notifications.feeding.interval"), selection: $settings.feedingReminderInterval) {
                        ForEach(ReminderInterval.allCases) { interval in
                            Text(interval.localizedName).tag(interval)
                        }
                    }

                    Toggle(AppCopy.string(for: "settings.notifications.sleep.enable"), isOn: $settings.sleepReminderEnabled)

                    if settings.sleepReminderEnabled {
                        DatePicker(
                            AppCopy.string(for: "settings.notifications.sleep.time"),
                            selection: $settings.sleepReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
            } header: {
                Text(AppCopy.string(for: "settings.notifications"))
            }

            // MARK: - Appearance Section
            Section {
                Picker(AppCopy.string(for: "settings.appearance.theme"), selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
            } header: {
                Text(AppCopy.string(for: "settings.appearance"))
            }

            // MARK: - Language Section
            Section {
                Picker(AppCopy.string(for: "settings.language"), selection: $settings.preferredLanguage) {
                    ForEach(LanguageOption.allCases) { language in
                        Text(language.localizedName).tag(language)
                    }
                }
            } header: {
                Text(AppCopy.string(for: "settings.language"))
            } footer: {
                Text(AppCopy.string(for: "settings.language.footer"))
            }

            // MARK: - Premium Section
            Section {
                HStack {
                    Text(AppCopy.string(for: "settings.premium.status"))
                    Spacer()
                    Text(container.premiumState.isPremium ? AppCopy.string(for: "settings.premium.active") : AppCopy.string(for: "settings.premium.inactive"))
                        .foregroundStyle(container.premiumState.isPremium ? .green : BabyTrackTheme.palette.mutedText)
                    if container.premiumState.isPremium {
                        Image(systemName: Symbols.premium)
                            .foregroundStyle(.yellow)
                    }
                }

                Button(AppCopy.string(for: "settings.premium.manage")) {
                    showPaywall = true
                    container.analytics.track(AnalyticsEvent(name: "settings_premium_tapped"))
                }
            } header: {
                Text(AppCopy.string(for: "settings.premium"))
            }

            // MARK: - Privacy Section
            Section {
                Toggle(AppCopy.string(for: "settings.privacy.analytics"), isOn: $settings.analyticsEnabled)
                    .onChange(of: settings.analyticsEnabled) { _, newValue in
                        container.analytics.track(AnalyticsEvent(
                            name: "setting_changed",
                            metadata: ["setting": "analytics", "value": "\(newValue)"]
                        ))
                    }

                Button(AppCopy.string(for: "settings.export.csv")) {
                    Task { await performExport(format: .csv) }
                }
                .disabled(isExporting)

                Button(AppCopy.string(for: "settings.export.json")) {
                    Task { await performExport(format: .json) }
                }
                .disabled(isExporting)

                if isExporting {
                    HStack {
                        ProgressView()
                        Text(AppCopy.string(for: "settings.export.progress"))
                            .font(BabyTrackTheme.typography.caption.font)
                    }
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text(AppCopy.string(for: "settings.privacy.deleteData"))
                }
            } header: {
                Text(AppCopy.string(for: "settings.privacy"))
            } footer: {
                Text(AppCopy.string(for: "settings.privacy.footer"))
            }

            // MARK: - About Section
            Section {
                HStack {
                    Text(AppCopy.string(for: "settings.about.version"))
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }

                Link(AppCopy.string(for: "settings.about.privacy"), destination: URL(string: "https://example.com/privacy")!)

                Link(AppCopy.string(for: "settings.about.terms"), destination: URL(string: "https://example.com/terms")!)

                Button(AppCopy.string(for: "settings.about.licenses")) {
                    // Open licenses view
                }

                Button(AppCopy.string(for: "settings.about.support")) {
                    if let url = URL(string: "mailto:support@babytrack.app") {
                        UIApplication.shared.open(url)
                    }
                }

                Button(AppCopy.string(for: "settings.about.rate")) {
                    // Request App Store review
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            } header: {
                Text(AppCopy.string(for: "settings.about"))
            }
        }
        .navigationTitle(Text(AppCopy.SettingsCopy.title))
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeClient: container.storeClient, premiumState: container.premiumState)
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .alert(AppCopy.string(for: "settings.privacy.deleteData.title"), isPresented: $showDeleteConfirmation) {
            Button(AppCopy.string(for: "settings.privacy.deleteData.confirm"), role: .destructive) {
                Task { await deleteAllData() }
            }
            Button(AppCopy.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppCopy.string(for: "settings.privacy.deleteData.message"))
        }
        .toast($toastMessage)
        .task {
            container.analytics.track(AnalyticsEvent(name: "settings_viewed"))
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    private enum ExportFormat {
        case csv
        case json
    }

    private func performExport(format: ExportFormat) async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url: URL
            switch format {
            case .csv:
                url = try await exportService.exportToCSV(dateRange: nil)
            case .json:
                url = try await exportService.exportToJSON(dateRange: nil)
            }

            await MainActor.run {
                exportURL = url
                showExportSheet = true
                toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "settings.export.success"))
                container.analytics.track(AnalyticsEvent(
                    name: "data_exported",
                    metadata: ["format": format == .csv ? "csv" : "json"]
                ))
            }
        } catch {
            await MainActor.run {
                toastMessage = ToastMessage(type: .error, message: AppCopy.string(for: "errors.export"))
            }
        }
    }

    private func deleteAllData() async {
        do {
            // Delete all events
            let events = try await container.eventsRepository.events(in: nil, kind: nil)
            for event in events {
                try await container.eventsRepository.delete(id: event.id)
            }

            // Delete all measurements
            let measurements = try await container.measurementsRepository.measurements(in: nil, type: nil)
            for measurement in measurements {
                try await container.measurementsRepository.delete(id: measurement.id)
            }

            toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "settings.privacy.deleteData.success"))
            container.analytics.track(AnalyticsEvent(name: "data_deleted"))
        } catch {
            toastMessage = ToastMessage(type: .error, message: AppCopy.string(for: "errors.generic"))
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Imports for StoreKit

import StoreKit
