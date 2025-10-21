import SwiftUI

public struct FormField<Content: View>: View {
    private let title: String
    private let helper: String?
    private let error: String?
    private let content: Content

    public init(title: String, helper: String? = nil, error: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.helper = helper
        self.error = error
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.xs) {
            BabyTrackTheme.typography.caption.text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            content
                .padding(.horizontal, BabyTrackTheme.spacing.sm)
                .padding(.vertical, BabyTrackTheme.spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft, style: .continuous)
                        .strokeBorder(error == nil ? BabyTrackTheme.palette.outline : BabyTrackTheme.palette.destructive, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft, style: .continuous)
                                .fill(BabyTrackTheme.palette.secondaryBackground)
                        )
                )
            if let helper, error == nil {
                BabyTrackTheme.typography.caption.text(helper)
            }
            if let error {
                Text(error)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(BabyTrackTheme.palette.destructive)
            }
        }
    }
}

#if DEBUG
struct FormField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BabyTrackTheme.spacing.lg) {
            FormField(title: "Notes", helper: "Optional") {
                TextField("", text: .constant("Nursery nap"))
                    .textFieldStyle(.plain)
            }
            FormField(title: "Duration", error: "End must be after start") {
                Text("10 min")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(BabyTrackTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
