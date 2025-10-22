import AppSupport
import Content
import DesignSystem
import SwiftUI

public struct EventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.eventsRepository) private var eventsRepository
    @Environment(\.analytics) private var analytics

    @StateObject private var viewModel: ViewModel

    public init(event: EventDTO? = nil, onComplete: @escaping (EventDTO) -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(event: event, onComplete: onComplete))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BabyTrackTheme.spacing.lg) {
                    Card {
                        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.md) {
                            SegmentedControl(options: EventKind.allCases, selection: $viewModel.kind) { kind in
                                LocalizedStringKey(kind.titleKey)
                            }
                            FormField(title: AppCopy.string(for: "event.form.start")) {
                                DatePicker("", selection: $viewModel.start)
                                    .datePickerStyle(.graphical)
                            }
                            FormField(
                                title: AppCopy.string(for: "event.form.end"),
                                helper: viewModel.hasEnd ? nil : AppCopy.string(for: "event.form.duration")
                            ) {
                                Toggle(isOn: $viewModel.hasEnd) {
                                    Text(viewModel.hasEnd ? LocalizedStringKey("event.form.end") : LocalizedStringKey("event.form.duration"))
                                }
                                .toggleStyle(.switch)
                                if viewModel.hasEnd {
                                    DatePicker("", selection: $viewModel.end, in: viewModel.start...)
                                        .datePickerStyle(.compact)
                                }
                            }
                        }
                    }
                    Card {
                        FormField(title: AppCopy.string(for: "event.form.notes"), error: viewModel.validationMessage) {
                            TextEditor(text: $viewModel.notes)
                                .frame(minHeight: 120)
                        }
                    }
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundStyle(BabyTrackTheme.palette.destructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, BabyTrackTheme.spacing.md)
                    }
                    PrimaryButton(isLoading: viewModel.isSaving, action: save) {
                        Text(LocalizedStringKey("event.form.save"))
                    }
                    .padding(.horizontal, BabyTrackTheme.spacing.md)
                }
                .padding(.vertical, BabyTrackTheme.spacing.lg)
            }
            .background(BabyTrackTheme.palette.background.ignoresSafeArea())
            .navigationTitle(viewModel.isEditing ? Text(LocalizedStringKey("event.form.title.edit")) : Text(LocalizedStringKey("event.form.title.new")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.string(for: "event.form.cancel"), action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func save() {
        Task {
            await viewModel.save(eventsRepository: eventsRepository, analytics: analytics)
            if viewModel.error == nil {
                dismiss()
            }
        }
    }
}

extension EventFormView {
    final class ViewModel: ObservableObject {
        @Published var kind: EventKind
        @Published var start: Date
        @Published var hasEnd: Bool
        @Published var end: Date
        @Published var notes: String
        @Published private(set) var isSaving = false
        @Published private(set) var error: String?
        @Published private(set) var validationMessage: String?

        private let existingEvent: EventDTO?
        private let onComplete: (EventDTO) -> Void

        var isEditing: Bool { existingEvent != nil }

        init(event: EventDTO?, onComplete: @escaping (EventDTO) -> Void) {
            if let event {
                self.kind = event.kind
                self.start = event.start
                self.hasEnd = event.end != nil
                self.end = event.end ?? event.start
                self.notes = event.notes ?? ""
            } else {
                self.kind = .sleep
                self.start = Date()
                self.hasEnd = false
                self.end = Date()
                self.notes = ""
            }
            self.existingEvent = event
            self.onComplete = onComplete
        }

        @MainActor
        func save(eventsRepository: any EventsRepository, analytics: any Analytics) async {
            guard validate() else { return }
            isSaving = true
            defer { isSaving = false }

            do {
                let dto = EventDTO(
                    id: existingEvent?.id ?? UUID(),
                    kind: kind,
                    start: start,
                    end: hasEnd ? end : nil,
                    notes: notes.isEmpty ? nil : notes,
                    createdAt: existingEvent?.createdAt ?? Date(),
                    updatedAt: Date(),
                    isSynced: existingEvent?.isSynced ?? false
                )
                let result: EventDTO
                if existingEvent != nil {
                    result = try await eventsRepository.update(dto)
                    analytics.track(AnalyticsEvent(name: "event_updated", metadata: ["kind": kind.rawValue]))
                } else {
                    result = try await eventsRepository.create(dto)
                    analytics.track(AnalyticsEvent(name: "event_created", metadata: ["kind": kind.rawValue]))
                }
                onComplete(result)
                error = nil
            } catch {
                self.error = error.localizedDescription
            }
        }

        private func validate() -> Bool {
            validationMessage = nil
            if hasEnd && end < start {
                validationMessage = AppCopy.string(for: "event.form.validation.endBeforeStart")
                error = AppCopy.string(for: "errors.validation")
                return false
            }
            error = nil
            return true
        }
    }
}

#if DEBUG
struct EventFormView_Previews: PreviewProvider {
    static var previews: some View {
        EventFormView { _ in }
            .environment(\.eventsRepository, QuickLogBar_Previews.PreviewEventsRepository())
            .environment(\.analytics, AnalyticsLogger())
    }
}
#endif
