import SwiftUI
import Charts

public struct ChartCard<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let content: Content
    private let accessory: AnyView?

    public init(
        title: String,
        subtitle: String? = nil,
        accessory: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.content = content()
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: BloomyTheme.spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        BloomyTheme.typography.headline.text(title)
                        if let subtitle {
                            BloomyTheme.typography.caption.text(subtitle)
                        }
                    }
                    Spacer()
                    accessory
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                content
                    .frame(minHeight: 160)
            }
        }
    }
}

#if DEBUG
struct ChartCard_Previews: PreviewProvider {
    static var previews: some View {
        ChartCard(title: "Sleep", subtitle: "Last 7 days") {
            Chart {
                ForEach(0..<7, id: \.self) { day in
                    LineMark(
                        x: .value("Day", day),
                        y: .value("Hours", Double.random(in: 8...11))
                    )
                }
            }
        }
        .padding()
        .background(BloomyTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
