import Content
import SwiftUI
import Tracking

public struct QuickLogView: View {
    @Environment(\.eventsRepository)
    private var eventsRepository
    @State private var processingKind: EventKind?
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        List(EventKind.allCases, id: \.self) { kind in
            Button {
                Task { await log(kind: kind) }
            } label: {
                HStack {
                    Image(systemName: kind.symbol)
                    Text(LocalizedStringKey(kind.titleKey))
                    if processingKind == kind {
                        Spacer()
                        ProgressView()
                    }
                }
            }
        }
        .navigationTitle(Text(AppCopy.WatchApp.quickLogTitle))
        .alert(AppCopy.string(for: "errors.generic"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(AppCopy.Common.ok, role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func log(kind: EventKind) async {
        processingKind = kind
        defer { processingKind = nil }
        do {
            let dto = EventDTO(kind: kind, start: Date())
            _ = try await eventsRepository.create(dto)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
