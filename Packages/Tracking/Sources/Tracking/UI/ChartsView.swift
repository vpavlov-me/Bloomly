import Content
import DesignSystem
import SwiftUI

/// Main charts screen showing all analytics tabs.
///
/// Features:
/// - Tab-based navigation for different chart types
/// - Sleep charts
/// - Feeding charts
/// - Diaper frequency charts
/// - Daily rhythm visualization
public struct ChartsView: View {
    @StateObject private var viewModel: ChartsViewModel
    @State private var selectedTab: ChartTab = .sleep

    public init(viewModel: ChartsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                chartTabSelector

                // Selected chart content
                TabView(selection: $selectedTab) {
                    SleepChartsView(viewModel: viewModel)
                        .tag(ChartTab.sleep)

                    FeedingChartsView(viewModel: viewModel)
                        .tag(ChartTab.feeding)

                    DailyRhythmView(viewModel: viewModel)
                        .tag(ChartTab.rhythm)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(Text(AppCopy.string(for: "charts.title")))
        }
    }

    private var chartTabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BabyTrackTheme.spacing.sm) {
                ForEach(ChartTab.allCases) { tab in
                    chartTabButton(tab)
                }
            }
            .padding(.horizontal, BabyTrackTheme.spacing.lg)
            .padding(.vertical, BabyTrackTheme.spacing.sm)
        }
        .background(BabyTrackTheme.palette.secondaryBackground)
    }

    private func chartTabButton(_ tab: ChartTab) -> some View {
        Button {
            withAnimation {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: BabyTrackTheme.spacing.xs) {
                Image(systemName: tab.icon)
                Text(LocalizedStringKey(tab.titleKey))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
            }
            .padding(.horizontal, BabyTrackTheme.spacing.md)
            .padding(.vertical, BabyTrackTheme.spacing.sm)
            .background(
                selectedTab == tab
                    ? BabyTrackTheme.palette.accent
                    : BabyTrackTheme.palette.background
            )
            .foregroundStyle(
                selectedTab == tab
                    ? .white
                    : BabyTrackTheme.palette.primaryText
            )
            .clipShape(RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft))
        }
    }
}

// MARK: - Supporting Types

private enum ChartTab: String, CaseIterable, Identifiable {
    case sleep
    case feeding
    case rhythm

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .sleep:
            return "charts.tab.sleep"
        case .feeding:
            return "charts.tab.feeding"
        case .rhythm:
            return "charts.tab.rhythm"
        }
    }

    var icon: String {
        switch self {
        case .sleep:
            return Symbols.sleep
        case .feeding:
            return Symbols.feed
        case .rhythm:
            return "clock.fill"
        }
    }
}

#if DEBUG
struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView(
            viewModel: ChartsViewModel(
                aggregator: ChartDataAggregator(eventsRepository: PreviewEventsRepository())
            )
        )
    }

    private struct PreviewEventsRepository: EventsRepository {
        func create(_ dto: EventDTO) async throws -> EventDTO { dto }
        func update(_ dto: EventDTO) async throws -> EventDTO { dto }
        func delete(id: UUID) async throws {}
        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] { [] }
        func lastEvent(for kind: EventKind) async throws -> EventDTO? { nil }
        func stats(for day: Date) async throws -> EventDayStats {
            .init(date: day, totalEvents: 0, totalDuration: 0)
        }
    }
}
#endif
