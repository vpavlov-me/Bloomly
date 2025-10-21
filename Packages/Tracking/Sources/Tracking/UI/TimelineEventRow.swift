import Content
import DesignSystem
import SwiftUI

public struct TimelineEventRow: View {
    private let event: EventDTO
    private let onEdit: (EventDTO) -> Void
    private let onDelete: (EventDTO) -> Void

    @Environment(\.eventsRepository) private var eventsRepository

    public init(event: EventDTO, onEdit: @escaping (EventDTO) -> Void, onDelete: @escaping (EventDTO) -> Void) {
        self.event = event
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(alignment: .top, spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: event.kind.symbol)
                .font(.system(size: 20))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.xs) {
                HStack {
                    Text(LocalizedStringKey(event.kind.titleKey))
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                    Text(timeRange)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }
                if let durationString {
                    Text(durationString)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }
                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(BabyTrackTheme.palette.primaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Menu {
                Button(role: .destructive) { onDelete(event) } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button { onEdit(event) } label: {
                    Label("Edit", systemImage: "pencil")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .padding(BabyTrackTheme.spacing.xs)
            }
        }
        .padding(.vertical, BabyTrackTheme.spacing.sm)
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        if let end = event.end {
            return "\(formatter.string(from: event.start)) – \(formatter.string(from: end))"
        }
        return formatter.string(from: event.start)
    }

    private var durationString: String? {
        guard let end = event.end else { return nil }
        let minutes = Int(end.timeIntervalSince(event.start) / 60)
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainder)m"
        }
        return "\(minutes)m"
    }
}

#if DEBUG
struct TimelineEventRow_Previews: PreviewProvider {
    static var previews: some View {
        TimelineEventRow(
            event: EventDTO(kind: .sleep, start: Date(), end: Date().addingTimeInterval(3600), notes: "Morning nap"),
            onEdit: { _ in },
            onDelete: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
