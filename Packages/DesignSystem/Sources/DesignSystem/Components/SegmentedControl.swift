import SwiftUI

public struct SegmentedControl<Option: Hashable>: View {
    private let options: [Option]
    @Binding private var selection: Option
    private let label: (Option) -> LocalizedStringKey

    public init(options: [Option], selection: Binding<Option>, label: @escaping (Option) -> LocalizedStringKey) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        Picker("", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(label(option))
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, BloomyTheme.spacing.md)
    }
}

#if DEBUG
private enum DemoFilter: String, CaseIterable {
    case all, events, measurements
}

private struct StatefulPreviewWrapper<Value: Hashable, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

struct SegmentedControl_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(DemoFilter.all) { selection in
            SegmentedControl(options: DemoFilter.allCases, selection: selection) { option in
                LocalizedStringKey(option.rawValue.capitalized)
            }
        }
        .padding()
        .background(BloomyTheme.palette.background)
        .previewLayout(.sizeThatFits)
    }
}
#endif
