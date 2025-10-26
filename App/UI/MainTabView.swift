import Content
import DesignSystem
import Measurements
import Paywall
import SwiftUI
import Timeline
import Tracking
import UniformTypeIdentifiers

public struct MainTabView: View {
    @ObservedObject private var container: DependencyContainer
    @StateObject private var timelineViewModel: TimelineViewModel
    @Binding var widgetDeepLink: WidgetDeepLink?

    @State private var showEventForm = false
    @State private var showMeasurementForm = false
    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var editingEvent: EventDTO?
    @State private var editingMeasurement: MeasurementDTO?
    @State private var measurements: [MeasurementDTO] = []
    @State private var isLoadingMeasurements = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var toastMessage: ToastMessage?
    @State private var selectedTab = 0

    private var exportService: DataExportService {
        DataExportService(
            eventsRepository: container.eventsRepository,
            measurementsRepository: container.measurementsRepository
        )
    }

    public init(container: DependencyContainer, widgetDeepLink: Binding<WidgetDeepLink?> = .constant(nil)) {
        self._container = ObservedObject(initialValue: container)
        self._widgetDeepLink = widgetDeepLink
        _timelineViewModel = StateObject(
            wrappedValue: TimelineViewModel(
                eventsRepository: container.eventsRepository,
                measurementsRepository: container.measurementsRepository
            )
        )
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(
                    viewModel: DashboardViewModel(eventsRepository: container.eventsRepository)
                ) { kind in
                    container.analytics.track(AnalyticsEvent(
                        name: "quick_action_tapped",
                        metadata: ["kind": kind.rawValue, "source": "dashboard"]
                    ))
                    showEventForm = true
                }
                .environment(\.eventsRepository, container.eventsRepository)
                .environment(\.analytics, container.analytics)
            }
            .tabItem { Label("Dashboard", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                TimelineView(viewModel: timelineViewModel)
                    .onAppear(perform: bindTimelineCallbacks)
            }
            .tabItem { Label(AppCopy.MainTabs.timeline, systemImage: "list.bullet") }
            .tag(1)

            NavigationStack {
                ChartsView(
                    viewModel: ChartsViewModel(
                        aggregator: container.chartAggregator
                    )
                )
            }
            .tabItem { Label("Charts", systemImage: "chart.bar.fill") }
            .tag(2)

            NavigationStack {
                ProfileView(container: container)
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(3)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            container.analytics.track(AnalyticsEvent(
                name: "tab_switched",
                metadata: ["from": "\(oldValue)", "to": "\(newValue)"]
            ))
        }
        .onChange(of: widgetDeepLink) { _, deepLink in
            guard let deepLink = deepLink else { return }
            handleDeepLink(deepLink)
            widgetDeepLink = nil
        }
        .sheet(isPresented: $showEventForm, onDismiss: { editingEvent = nil }) {
            EventFormView(event: editingEvent) { event in
                timelineViewModel.append(event: event)
                toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "event.saved"))
            }
            .environment(\.eventsRepository, container.eventsRepository)
            .environment(\.analytics, container.analytics)
        }
        .sheet(isPresented: $showMeasurementForm, onDismiss: { editingMeasurement = nil }) {
            MeasurementFormView(measurement: editingMeasurement) { _ in
                Task {
                    await loadMeasurements()
                    toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "measurement.saved"))
                }
            }
            .environment(\.measurementsRepository, container.measurementsRepository)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeClient: container.storeClient, premiumState: container.premiumState)
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .toast($toastMessage)
        .task { await loadMeasurements() }
    }

    private func bindTimelineCallbacks() {
        timelineViewModel.onPresentEventForm = { event in
            editingEvent = event
            showEventForm = true
        }
        timelineViewModel.onPresentMeasurementForm = { measurement in
            editingMeasurement = measurement
            showMeasurementForm = true
        }
    }

    private var addTab: some View {
        List {
            Section {
                QuickLogBar { event in
                    timelineViewModel.append(event: event)
                    toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "event.saved"))
                }
                .environment(\.eventsRepository, container.eventsRepository)
                .environment(\.analytics, container.analytics)
            }
            Section {
                Button(AppCopy.string(for: "measurements.add")) {
                    showMeasurementForm = true
                }
            }
        }
        .navigationTitle(Text(AppCopy.MainTabs.add))
    }

    private var measurementsTab: some View {
        ScrollView {
            VStack(spacing: BabyTrackTheme.spacing.lg) {
                if isLoadingMeasurements {
                    ProgressView()
                }
                if measurements.isEmpty {
                    EmptyStateView(
                        icon: Symbols.measurement,
                        title: AppCopy.string(for: "measurements.list.empty"),
                        message: AppCopy.string(for: "measurements.list.empty.message"),
                        actionTitle: AppCopy.string(for: "measurements.add")
                    ) {
                        showMeasurementForm = true
                    }
                } else {
                    VStack(spacing: BabyTrackTheme.spacing.sm) {
                        ForEach(measurements, id: \.id) { measurement in
                            MeasurementRow(
                                measurement: measurement,
                                onEdit: { measurement in
                                    editingMeasurement = measurement
                                    showMeasurementForm = true
                                },
                                onDelete: { measurement in
                                    Task { await deleteMeasurement(measurement) }
                                }
                            )
                            Divider()
                        }
                    }
                    GrowthChartsView(
                        measurements: measurements,
                        isPremium: container.premiumState.isPremium
                    )
                }
            }
            .padding(BabyTrackTheme.spacing.lg)
        }
        .navigationTitle(Text(AppCopy.Measurements.title))
    }

    private var settingsTab: some View {
        Form {
            Section(header: Text(AppCopy.string(for: "settings.notifications"))) {
                Toggle(AppCopy.string(for: "settings.notifications.enable"), isOn: $container.notificationManager.isNotificationEnabled)
                    .onChange(of: container.notificationManager.isNotificationEnabled) { _, newValue in
                        if newValue {
                            Task {
                                await container.notificationManager.requestNotificationPermission()
                            }
                        }
                    }
            }

            Section(header: Text(AppCopy.string(for: "settings.premium.status"))) {
                HStack {
                    Text(container.premiumState.isPremium ? AppCopy.string(for: "settings.premium.active") : AppCopy.string(for: "settings.premium.inactive"))
                    Spacer()
                    if container.premiumState.isPremium {
                        Image(systemName: Symbols.premium)
                            .foregroundStyle(.yellow)
                    }
                }
                Button(AppCopy.string(for: "settings.premium.manage")) {
                    showPaywall = true
                }
            }

            Section(header: Text(AppCopy.string(for: "settings.export"))) {
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
            }
        }
        .navigationTitle(Text(AppCopy.SettingsCopy.title))
    }

    // MARK: - Actions

    private func loadMeasurements() async {
        isLoadingMeasurements = true
        defer { isLoadingMeasurements = false }
        do {
            let interval = DateInterval(
                start: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                end: Date()
            )
            let data = try await container.measurementsRepository.measurements(in: interval, type: nil)
            await MainActor.run { measurements = data.sorted { $0.date > $1.date } }
        } catch {
            await MainActor.run {
                measurements = []
                toastMessage = ToastMessage(type: .error, message: AppCopy.string(for: "errors.load"))
            }
        }
    }

    private func deleteMeasurement(_ measurement: MeasurementDTO) async {
        do {
            try await container.measurementsRepository.delete(id: measurement.id)
            await loadMeasurements()
            toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "measurement.deleted"))
        } catch {
            toastMessage = ToastMessage(type: .error, message: AppCopy.string(for: "errors.delete"))
        }
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
                toastMessage = ToastMessage(type: .success, message: AppCopy.string(for: "settings.export.success"))
            }
        } catch {
            await MainActor.run {
                toastMessage = ToastMessage(type: .error, message: AppCopy.string(for: "errors.export"))
            }
        }
    }

    // MARK: - Widget Deep Linking

    private func handleDeepLink(_ deepLink: WidgetDeepLink) {
        switch deepLink {
        case .timeline:
            selectedTab = 1  // Timeline is now tab 1
        case .addFeed, .addSleep, .addDiaper:
            selectedTab = 0  // Dashboard for quick actions
            showEventForm = true
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
