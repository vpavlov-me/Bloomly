import SwiftUI
import WidgetKit
import Widgets

@main
struct BloomlyWidgetsEntryPoint: WidgetBundle {
    var body: some Widget {
        SmallWidget()
        MediumWidget()
        LargeWidget()
    }
}
