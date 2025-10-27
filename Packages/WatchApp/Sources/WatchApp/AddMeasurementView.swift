import Content
import Measurements
import SwiftUI

public struct AddMeasurementView: View {
    @Environment(\.measurementsRepository) private var measurementsRepository
    @State private var type: MeasurementType = .height
    @State private var value: String = ""
    @State private var unit: String = MeasurementType.height.defaultUnit
    @State private var date: Date = Date()
    @State private var confirmation: String?

    public init() {}

    public var body: some View {
        Form {
            Picker(AppCopy.Measurements.type, selection: $type) {
                ForEach(MeasurementType.allCases) { type in
                    Text(LocalizedStringKey(type.titleKey)).tag(type)
                }
            }
            TextField(AppCopy.Measurements.value, text: $value)
                .keyboardType(.decimalPad)
            TextField(AppCopy.Measurements.unit, text: $unit)
            DatePicker(AppCopy.Measurements.date, selection: $date, displayedComponents: [.date, .hourAndMinute])
            Button(AppCopy.Common.save) {
                Task { await save() }
            }
        }
        .navigationTitle(AppCopy.WatchApp.measureTitle)
        .alert(AppCopy.string(for: "measurements.add"), isPresented: Binding(
            get: { confirmation != nil },
            set: { if !$0 { confirmation = nil } }
        )) {
            Button(AppCopy.Common.ok, role: .cancel) {}
        } message: {
            Text(confirmation ?? "")
        }
        .onChange(of: type) { newValue in
            unit = newValue.defaultUnit
        }
    }

    private func save() async {
        guard let numericValue = Double(value) else {
            confirmation = AppCopy.string(for: "errors.validation")
            return
        }
        let dto = MeasurementDTO(type: type, value: numericValue, unit: unit, date: date)
        do {
            _ = try await measurementsRepository.create(dto)
            confirmation = AppCopy.string(for: "paywall.restore.success")
            value = ""
        } catch {
            confirmation = error.localizedDescription
        }
    }
}
