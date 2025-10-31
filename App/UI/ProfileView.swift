import AppSupport
import Content
import DesignSystem
import Paywall
import SwiftUI

/// Profile screen showing baby profile and app settings.
///
/// Features:
/// - Baby profile information with photo
/// - Premium status
/// - App settings (notifications, appearance, language)
/// - Data export and privacy controls
/// - About section
public struct ProfileView: View {
    @ObservedObject private var container: DependencyContainer
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var notificationManager: NotificationManager
    @ObservedObject private var profileStore = BabyProfileStore.shared

    @State private var showPaywall = false
    @State private var toastMessage: ToastMessage?

    public init(container: DependencyContainer) {
        self._container = ObservedObject(initialValue: container)
        self._notificationManager = ObservedObject(
            initialValue: container.notificationManager
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BloomyTheme.spacing.lg) {
                    // Baby profile card
                    babyProfileCard

                    // Premium status card
                    premiumStatusCard

                    // Settings sections
                    VStack(spacing: BloomyTheme.spacing.md) {
                        notificationsSection
                        appearanceSection
                        privacySection
                        aboutSection
                    }
                }
                .padding(BloomyTheme.spacing.lg)
            }
            .background(BloomyTheme.palette.background)
            .navigationTitle(Text(AppCopy.string(for: "profile.title")))
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    storeClient: container.storeClient,
                    premiumState: container.premiumState
                )
            }
            .toast($toastMessage)
            .task {
                container.analytics.track(AnalyticsEvent(name: "profile_viewed"))
            }
        }
    }

    // MARK: - Baby Profile Card

    private var babyProfileCard: some View {
        Card {
            Button {
                // Navigate to baby profile edit
            } label: {
                HStack(spacing: BloomyTheme.spacing.md) {
                    // Profile photo
                    if let profile = profileStore.currentProfile {
                        profileContent(for: profile)
                    } else {
                        emptyProfileContent
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(BloomyTheme.palette.mutedText)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func profileContent(for profile: BabyProfile) -> some View {
        if let photoData = profile.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(BloomyTheme.palette.accent.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(BloomyTheme.palette.accent)
                }
        }

        VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
            Text(profile.name)
                .font(BloomyTheme.typography.title.font)
                .foregroundStyle(BloomyTheme.palette.primaryText)

            Text(profile.ageText)
                .font(BloomyTheme.typography.body.font)
                .foregroundStyle(BloomyTheme.palette.mutedText)

            Text(formatBirthDate(profile.birthDate))
                .font(BloomyTheme.typography.caption.font)
                .foregroundStyle(BloomyTheme.palette.mutedText)
        }
    }

    private var emptyProfileContent: some View {
        HStack(spacing: BloomyTheme.spacing.md) {
            Circle()
                .fill(BloomyTheme.palette.accent.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 36))
                        .foregroundStyle(BloomyTheme.palette.accent)
                }

            Text(AppCopy.string(for: "profile.create"))
                .font(BloomyTheme.typography.body.font)
                .foregroundStyle(BloomyTheme.palette.primaryText)
        }
    }

    // MARK: - Premium Status Card

    private var premiumStatusCard: some View {
        Card {
            Button {
                showPaywall = true
                container.analytics.track(AnalyticsEvent(name: "profile_premium_tapped"))
            } label: {
                HStack {
                    Image(systemName: Symbols.premium)
                        .font(.system(size: 24))
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
                        Text(AppCopy.string(for: "settings.premium"))
                            .font(BloomyTheme.typography.headline.font)
                            .foregroundStyle(BloomyTheme.palette.primaryText)

                        Text(
                            container.premiumState.isPremium
                                ? AppCopy.string(for: "settings.premium.active")
                                : AppCopy.string(for: "settings.premium.inactive")
                        )
                        .font(BloomyTheme.typography.caption.font)
                        .foregroundStyle(
                            container.premiumState.isPremium
                                ? .green
                                : BloomyTheme.palette.mutedText
                        )
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(BloomyTheme.palette.mutedText)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.headline.text(
                    AppCopy.string(for: "settings.notifications")
                )

                VStack(spacing: BloomyTheme.spacing.sm) {
                    Toggle(
                        AppCopy.string(for: "settings.notifications.enable"),
                        isOn: $notificationManager.isNotificationEnabled
                    )
                    .onChange(of: notificationManager.isNotificationEnabled) { _, newValue in
                        if newValue {
                            Task {
                                await notificationManager.requestNotificationPermission()
                            }
                        }
                    }

                    if notificationManager.isNotificationEnabled {
                        Divider()

                        VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
                            Text(
                                AppCopy.string(for: "settings.notifications.feeding.interval")
                            )
                            .font(BloomyTheme.typography.caption.font)
                            .foregroundStyle(BloomyTheme.palette.mutedText)

                            Picker("", selection: $settings.feedingReminderInterval) {
                                ForEach(ReminderInterval.allCases) { interval in
                                    Text(interval.localizedName).tag(interval)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider()

                        Toggle(
                            AppCopy.string(for: "settings.notifications.sleep.enable"),
                            isOn: $settings.sleepReminderEnabled
                        )

                        if settings.sleepReminderEnabled {
                            DatePicker(
                                AppCopy.string(for: "settings.notifications.sleep.time"),
                                selection: $settings.sleepReminderTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.headline.text(
                    AppCopy.string(for: "settings.appearance")
                )

                VStack(spacing: BloomyTheme.spacing.sm) {
                    VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
                        Text(AppCopy.string(for: "settings.appearance.theme"))
                            .font(BloomyTheme.typography.body.font)

                        Picker("", selection: $settings.appearanceMode) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.localizedName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
                        Text(AppCopy.string(for: "settings.language"))
                            .font(BloomyTheme.typography.body.font)

                        Picker("", selection: $settings.preferredLanguage) {
                            ForEach(LanguageOption.allCases) { language in
                                Text(language.localizedName).tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.headline.text(
                    AppCopy.string(for: "settings.privacy")
                )

                VStack(spacing: BloomyTheme.spacing.sm) {
                    Toggle(
                        AppCopy.string(for: "settings.privacy.analytics"),
                        isOn: $settings.analyticsEnabled
                    )
                    .onChange(of: settings.analyticsEnabled) { _, newValue in
                        container.analytics.track(AnalyticsEvent(
                            name: "setting_changed",
                            metadata: ["setting": "analytics", "value": "\(newValue)"]
                        ))
                    }

                    Divider()

                    NavigationLink {
                        DataExportView(container: container)
                    } label: {
                        HStack {
                            Text(AppCopy.string(for: "settings.export"))
                                .font(BloomyTheme.typography.body.font)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(BloomyTheme.palette.mutedText)
                        }
                    }
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                BloomyTheme.typography.headline.text(
                    AppCopy.string(for: "settings.about")
                )

                VStack(spacing: BloomyTheme.spacing.sm) {
                    HStack {
                        Text(AppCopy.string(for: "settings.about.version"))
                            .font(BloomyTheme.typography.body.font)
                        Spacer()
                        Text(appVersion)
                            .font(BloomyTheme.typography.body.font)
                            .foregroundStyle(BloomyTheme.palette.mutedText)
                    }

                    Divider()

                    Link(destination: URL(string: "mailto:support@bloomy.app")!) {
                        HStack {
                            Text(AppCopy.string(for: "settings.about.support"))
                                .font(BloomyTheme.typography.body.font)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(BloomyTheme.palette.mutedText)
                        }
                    }

                    Divider()

                    Button {
                        if let scene = UIApplication.shared.connectedScenes.first
                            as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    } label: {
                        HStack {
                            Text(AppCopy.string(for: "settings.about.rate"))
                                .font(BloomyTheme.typography.body.font)
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func formatBirthDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Data Export View

private struct DataExportView: View {
    let container: DependencyContainer

    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var toastMessage: ToastMessage?

    private var exportService: DataExportService {
        DataExportService(
            eventsRepository: container.eventsRepository,
            measurementsRepository: container.measurementsRepository
        )
    }

    var body: some View {
        Form {
            Section {
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
                            .font(BloomyTheme.typography.caption.font)
                    }
                }
            } header: {
                Text(AppCopy.string(for: "settings.export"))
            } footer: {
                Text(AppCopy.string(for: "settings.export.footer"))
            }
        }
        .navigationTitle(Text(AppCopy.string(for: "settings.export")))
        .sheet(isPresented: $showExportSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .toast($toastMessage)
    }

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
                toastMessage = ToastMessage(
                    type: .success,
                    message: AppCopy.string(for: "settings.export.success")
                )
                container.analytics.track(AnalyticsEvent(
                    name: "data_exported",
                    metadata: ["format": format == .csv ? "csv" : "json"]
                ))
            }
        } catch {
            await MainActor.run {
                toastMessage = ToastMessage(
                    type: .error,
                    message: AppCopy.string(for: "errors.export")
                )
            }
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

// MARK: - Imports

import StoreKit
