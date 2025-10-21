import DesignSystem
import SwiftUI

public struct MeasurementRow: View {
    private let measurement: MeasurementDTO
    private let onEdit: (MeasurementDTO) -> Void
    private let onDelete: (MeasurementDTO) -> Void

    public init(measurement: MeasurementDTO, onEdit: @escaping (MeasurementDTO) -> Void, onDelete: @escaping (MeasurementDTO) -> Void) {
        self.measurement = measurement
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: measurement.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(measurement.formattedValue) \(measurement.unit)")
                    .font(.system(.headline, design: .rounded))
                Text(dateString)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(BabyTrackTheme.palette.mutedText)
            }
            Spacer()
            Menu {
                Button("Edit") { onEdit(measurement) }
                Button(role: .destructive, action: { onDelete(measurement) }) {
                    Text("Delete")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .padding(BabyTrackTheme.spacing.xs)
            }
        }
        .padding(.vertical, BabyTrackTheme.spacing.sm)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: measurement.date)
    }
}

#if DEBUG
struct MeasurementRow_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementRow(
            measurement: MeasurementDTO(type: .height, value: 62.3, unit: "cm", date: Date()),
            onEdit: { _ in },
            onDelete: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
