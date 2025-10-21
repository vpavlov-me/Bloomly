import Content
import DesignSystem
import Measurements
import SwiftUI
import Tracking

public struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel
    @State private var showUndoAlert = false

    public init(viewModel: TimelineViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.sections.isEmpty && viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sections.isEmpty {
                    EmptyStateView(
                        icon: Symbols.timeline,
                        title: AppCopy.string(for: "timeline.empty.title"),
                        message: AppCopy.string(for: "timeline.empty.message"),
                        actionTitle: AppCopy.string(for: "timeline.empty.action")
                    ) {
                        viewModel.presentNewEvent()
                    }
                } else {
                    listContent
                }
            }
            .navigationTitle(Text(AppCopy.Timeline.title))
            .task { await viewModel.refresh() }
            .alert(isPresented: $showUndoAlert) {
                Alert(
                    title: Text(AppCopy.string(for: "event.delete.message")),
                    primaryButton: .default(Text(AppCopy.string(for: "event.delete.undo"))) {
                        Task { await viewModel.undoDelete() }
                    },
                    secondaryButton: .cancel()
                )
            }
            .refreshable { await viewModel.refresh(force: true) }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: viewModel.searchText) { _ in
                viewModel.applyFilters()
            }
        }
    }

    private var listContent: some View {
        List {
            Section {
                QuickLogBar { event in
                    viewModel.append(event: event)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listRowBackground(Color.clear)

            Section {
                SegmentedControl(options: TimelineViewModel.Filter.allCases, selection: $viewModel.filter) { filter in
                    LocalizedStringKey(filter.titleKey)
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(Color.clear)

            ForEach(viewModel.sections, id: \.date) { section in
                Section(header: sectionHeader(for: section)) {
                    ForEach(section.items, id: \.id) { item in
                        row(for: item)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sectionHeader(for section: TimelineViewModel.DaySection) -> some View {
        SectionHeader(
            title: section.title,
            subtitle: section.summary
        )
    }

    @ViewBuilder
    private func row(for item: FeedItem) -> some View {
        switch item {
        case .event(let event):
            TimelineEventRow(
                event: event,
                onEdit: { viewModel.presentEdit(event: $0) },
                onDelete: { event in
                    Task { await viewModel.delete(.event(event)) }
                    showUndoAlert = true
                }
            )
        case .measurement(let measurement):
            MeasurementRow(
                measurement: measurement,
                onEdit: { viewModel.presentEdit(measurement: $0) },
                onDelete: { measurement in
                    Task { await viewModel.delete(.measurement(measurement)) }
                    showUndoAlert = true
                }
            )
        }
    }
}

public final class TimelineViewModel: ObservableObject {
    public struct DaySection: Identifiable, Hashable {
        public let id = UUID()
        public let date: Date
        public let title: String
        public let summary: String
        public let items: [FeedItem]
    }

    public enum Filter: Hashable, CaseIterable {
        case all
        case events
        case measurements

        fileprivate var titleKey: String {
            switch self {
            case .all: return "timeline.filter.all"
            case .events: return "timeline.filter.events"
            case .measurements: return "timeline.filter.measurements"
            }
        }
    }

    @Published public private(set) var sections: [DaySection] = []
    @Published public var searchText: String = ""
    @Published public var filter: Filter = .all {
        didSet { applyFilters() }
    }
    @Published public private(set) var isLoading = false

    private let eventsRepository: any EventsRepository
    private let measurementsRepository: any MeasurementsRepository
    private let calendar: Calendar
    private var cache: [FeedItem] = []
    private var lastDeleted: FeedItem?
    public var onPresentEventForm: ((EventDTO?) -> Void)?
    public var onPresentMeasurementForm: ((MeasurementDTO?) -> Void)?

    public init(eventsRepository: any EventsRepository, measurementsRepository: any MeasurementsRepository, calendar: Calendar = .current) {
        self.eventsRepository = eventsRepository
        self.measurementsRepository = measurementsRepository
        self.calendar = calendar
    }

    @MainActor
    public func refresh(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -30, to: end) ?? end.addingTimeInterval(-30 * 86400)
            let interval = DateInterval(start: start, end: end)

            async let eventsTask = eventsRepository.events(in: interval, kind: nil)
            async let measurementsTask = measurementsRepository.measurements(in: interval, type: nil)

            let events = try await eventsTask
            let measurements = try await measurementsTask

            cache = events.map(FeedItem.event) + measurements.map(FeedItem.measurement)
            applyFilters()
        } catch {
            // TODO: surface error to UI if needed
        }
    }

    @MainActor
    public func applyFilters() {
        var filtered = cache
        switch filter {
        case .all:
            break
        case .events:
            filtered = filtered.filter { if case .event = $0 { return true } else { return false } }
        case .measurements:
            filtered = filtered.filter { if case .measurement = $0 { return true } else { return false } }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                switch item {
                case .event(let event):
                    let noteMatch = event.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                    return noteMatch || event.kind.rawValue.localizedCaseInsensitiveContains(searchText)
                case .measurement(let measurement):
                    return measurement.unit.localizedCaseInsensitiveContains(searchText)
                        || measurement.type.rawValue.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        sections = buildSections(from: filtered)
    }

    @MainActor
    public func append(event: EventDTO) {
        cache.append(.event(event))
        applyFilters()
    }

    @MainActor
    public func presentNewEvent() {
        onPresentEventForm?(nil)
    }

    @MainActor
    public func presentEdit(event: EventDTO) {
        onPresentEventForm?(event)
    }

    @MainActor
    public func presentEdit(measurement: MeasurementDTO) {
        onPresentMeasurementForm?(measurement)
    }

    @MainActor
    public func delete(_ item: FeedItem) async {
        lastDeleted = item
        do {
            switch item {
            case .event(let event):
                try await eventsRepository.delete(id: event.id)
            case .measurement(let measurement):
                try await measurementsRepository.delete(id: measurement.id)
            }
            cache.removeAll { $0.id == item.id }
            applyFilters()
        } catch {
            // TODO: handle error
        }
    }

    @MainActor
    public func undoDelete() async {
        guard let lastDeleted else { return }
        do {
            switch lastDeleted {
            case .event(let event):
                let restored = try await eventsRepository.create(event)
                cache.append(.event(restored))
            case .measurement(let measurement):
                let restored = try await measurementsRepository.create(measurement)
                cache.append(.measurement(restored))
            }
            applyFilters()
        } catch {
            // TODO: handle error
        }
    }

    private func buildSections(from items: [FeedItem]) -> [DaySection] {
        let groups = Dictionary(grouping: items) { calendar.startOfDay(for: $0.date) }
        return groups
            .map { date, items in
                let sortedItems = items.sorted { $0.date > $1.date }
                let summary = summary(for: sortedItems)
                return DaySection(
                    date: date,
                    title: sectionTitle(for: date),
                    summary: summary,
                    items: sortedItems
                )
            }
            .sorted { $0.date > $1.date }
    }

    private func summary(for items: [FeedItem]) -> String {
        let eventsCount = items.compactMap { item -> EventDTO? in if case let .event(event) = item { return event } else { return nil } }.count
        let measurementsCount = items.count - eventsCount
        let eventSummary = AppCopy.Timeline.eventsCount(eventsCount)
        let measurementSummary = AppCopy.Timeline.measurementsCount(measurementsCount)
        return "\(eventSummary) • \(measurementSummary)"
    }

    private func sectionTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return AppCopy.string(for: "timeline.section.today")
        } else if calendar.isDateInYesterday(date) {
            return AppCopy.string(for: "timeline.section.yesterday")
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
