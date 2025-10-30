import SwiftUI

public struct FormField<Content: View>: View {
    private let title: String
    private let helper: String?
    private let error: String?
    private let content: Content

    public init(
        title: String,
        helper: String? = nil,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.helper = helper
        self.error = error
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BloomyTheme.spacing.xs) {
            BloomyTheme.typography.caption.text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            content
                .padding(.horizontal, BloomyTheme.spacing.sm)
                .padding(.vertical, BloomyTheme.spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BloomyTheme.radii.soft, style: .continuous)
                        .strokeBorder(
                            error == nil ? BloomyTheme.palette.outline : BloomyTheme.palette.destructive,
                            lineWidth: 1
                        )
                        .background(
                            RoundedRectangle(cornerRadius: BloomyTheme.radii.soft, style: .continuous)
                                .fill(BloomyTheme.palette.secondaryBackground)
                        )
                )
            if let helper, error == nil {
                BloomyTheme.typography.caption.text(helper)
            }
            if let error {
                Text(error)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(BloomyTheme.palette.destructive)
            }
        }
    }
}

#if DEBUG
struct FormField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: BloomyTheme.spacing.lg) {
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
        .background(BloomyTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
