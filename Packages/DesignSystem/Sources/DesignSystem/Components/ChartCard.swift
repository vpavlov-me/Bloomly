import SwiftUI
import Charts

public struct ChartCard<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let content: Content
    private let accessory: AnyView?

    public init(title: String, subtitle: String? = nil, accessory: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.content = content()
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        BabyTrackTheme.typography.headline.text(title)
                        if let subtitle {
                            BabyTrackTheme.typography.caption.text(subtitle)
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
                    LineMark(x: .value("Day", day), y: .value("Hours", Double.random(in: 8...11)))
                }
            }
        }
        .padding()
        .background(BabyTrackTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
