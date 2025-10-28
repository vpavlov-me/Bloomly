import AppSupport
import Content
import DesignSystem
import SwiftUI

public struct QuickLogBar: View {
    private let eventsRepository: any EventsRepository
    private let analytics: any Analytics
    private let onSubmit: (EventDTO) -> Void

    @State private var isLogging = false
    @State private var error: String?

    public init(
        eventsRepository: any EventsRepository,
        analytics: any Analytics,
        onSubmit: @escaping (EventDTO) -> Void
    ) {
        self.eventsRepository = eventsRepository
        self.analytics = analytics
        self.onSubmit = onSubmit
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
                BabyTrackTheme.typography.headline.text(AppCopy.string(for: "event.form.title.new"))
                HStack(spacing: BabyTrackTheme.spacing.sm) {
                    ForEach(EventKind.allCases) { kind in
                        Button {
                            Task { await log(kind: kind) }
                        } label: {
                            HStack(spacing: BabyTrackTheme.spacing.xs) {
                                Image(systemName: kind.symbol)
                                Text(LocalizedStringKey(kind.titleKey))
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BabyTrackTheme.spacing.xs)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BabyTrackTheme.palette.accent)
                        .disabled(isLogging)
                    }
                }
                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(BabyTrackTheme.palette.destructive)
                }
            }
        }
    }

    private func log(kind: EventKind) async {
        guard !isLogging else { return }
        isLogging = true
        defer { isLogging = false }
        do {
            let dto = EventDTO(kind: kind, start: Date(), end: nil, notes: nil)
            let created = try await eventsRepository.create(dto)
            analytics.track(AnalyticsEvent(name: "quick_log", metadata: ["kind": kind.rawValue]))
            await MainActor.run {
                onSubmit(created)
                error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
}

#if DEBUG
struct QuickLogBar_Previews: PreviewProvider {
    static var previews: some View {
        QuickLogBar(
            eventsRepository: MockEventsRepository(),
            analytics: AnalyticsLogger()
        ) { _ in }
            .padding()
            .background(BabyTrackTheme.palette.background)
            .previewLayout(.sizeThatFits)
    }

}
#endif
