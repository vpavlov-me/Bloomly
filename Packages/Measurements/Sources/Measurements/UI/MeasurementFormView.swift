import Content
import DesignSystem
import SwiftUI

public struct MeasurementFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.measurementsRepository) private var measurementsRepository

    @StateObject private var viewModel: ViewModel

    public init(measurement: MeasurementDTO? = nil, onComplete: @escaping (MeasurementDTO) -> Void) {
        _viewModel = StateObject(wrappedValue: ViewModel(measurement: measurement, onComplete: onComplete))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(AppCopy.string(for: "measurements.form.type"))) {
                    Picker("", selection: $viewModel.type) {
                        ForEach(MeasurementType.allCases) { type in
                            Text(LocalizedStringKey(type.titleKey)).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text(AppCopy.string(for: "measurements.form.value"))) {
                    TextField(AppCopy.string(for: "measurements.form.value"), text: $viewModel.valueString)
                        .keyboardType(.decimalPad)
                    TextField(AppCopy.string(for: "measurements.form.unit"), text: $viewModel.unit)
                }

                Section(header: Text(AppCopy.string(for: "measurements.form.date"))) {
                    DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(BabyTrackTheme.palette.destructive)
                    }
                }
            }
            .navigationTitle(Text(AppCopy.Measurements.formTitle))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.string(for: "event.form.cancel"), action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button(AppCopy.string(for: "event.form.save")) { save() }
                    }
                }
            }
        }
    }

    private func save() {
        Task {
            await viewModel.save(repository: measurementsRepository)
            if viewModel.error == nil {
                dismiss()
            }
        }
    }
}

extension MeasurementFormView {
    final class ViewModel: ObservableObject {
        @Published var type: MeasurementType
        @Published var valueString: String
        @Published var unit: String
        @Published var date: Date
        @Published private(set) var error: String?
        @Published private(set) var isSaving = false

        private let measurement: MeasurementDTO?
        private let onComplete: (MeasurementDTO) -> Void

        init(measurement: MeasurementDTO?, onComplete: @escaping (MeasurementDTO) -> Void) {
            if let measurement {
                self.type = measurement.type
                self.valueString = String(measurement.value)
                self.unit = measurement.unit
                self.date = measurement.date
            } else {
                self.type = .height
                self.valueString = ""
                self.unit = MeasurementType.height.defaultUnit
                self.date = Date()
            }
            self.measurement = measurement
            self.onComplete = onComplete
        }

        @MainActor
        func save(repository: any MeasurementsRepository) async {
            error = nil
            guard let value = Double(valueString) else {
                error = AppCopy.string(for: "errors.validation")
                return
            }
            isSaving = true
            defer { isSaving = false }

            do {
                let dto = MeasurementDTO(
                    id: measurement?.id ?? UUID(),
                    type: type,
                    value: value,
                    unit: unit,
                    date: date,
                    notes: nil,
                    isSynced: measurement?.isSynced ?? false
                )
                let result: MeasurementDTO
                if measurement == nil {
                    result = try await repository.create(dto)
                } else {
                    result = try await repository.update(dto)
                }
                onComplete(result)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

#if DEBUG
struct MeasurementFormView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementFormView { _ in }
            .environment(\.measurementsRepository, PreviewMeasurementsRepository())
    }

    private struct PreviewMeasurementsRepository: MeasurementsRepository {
        func create(_ dto: MeasurementDTO) async throws -> MeasurementDTO { dto }
        func update(_ dto: MeasurementDTO) async throws -> MeasurementDTO { dto }
        func delete(id: UUID) async throws {}
        func measurements(in interval: DateInterval?, type: MeasurementType?) async throws -> [MeasurementDTO] { [] }
    }
}
#endif
