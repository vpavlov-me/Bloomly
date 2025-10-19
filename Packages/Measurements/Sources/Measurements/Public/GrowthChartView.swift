//
//  GrowthChartView.swift
//  BabyTrack
//
//  Renders sample growth curves using Swift Charts.
//

import Charts
import SwiftUI

public struct GrowthChartSample: Identifiable, Sendable {
    public enum SampleType: String, Sendable {
        case height
        case weight
    }

    public let id: UUID
    public let type: SampleType
    public let month: Int
    public let value: Double

    public init(id: UUID = UUID(), type: SampleType, month: Int, value: Double) {
        self.id = id
        self.type = type
        self.month = month
        self.value = value
    }
}

public struct GrowthChartView: View {
    private let samples: [GrowthChartSample]
    private let showCharts: Bool

    public init(samples: [GrowthChartSample], showCharts: Bool = true) {
        self.samples = samples
        self.showCharts = showCharts && !samples.isEmpty
    }

    public var body: some View {
        Group {
            if showCharts {
                Chart(samples) { item in
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(by: .value("Type", item.type.rawValue.capitalized))
                }
                .chartYAxisLabel("Value")
                .chartXAxisLabel("Months")
            } else {
                ContentUnavailableView("No data", systemImage: "chart.xyaxis.line", description: Text("Add measurements to unlock charts."))
            }
        }
        .frame(minHeight: 200)
    }
}

#if DEBUG
struct GrowthChartView_Previews: PreviewProvider {
    static var previews: some View {
        GrowthChartView(samples: [
            GrowthChartSample(type: .weight, month: 0, value: 3.4),
            GrowthChartSample(type: .weight, month: 3, value: 5.1),
            GrowthChartSample(type: .weight, month: 6, value: 6.8),
            GrowthChartSample(type: .height, month: 0, value: 49.0),
            GrowthChartSample(type: .height, month: 3, value: 60.0),
            GrowthChartSample(type: .height, month: 6, value: 65.5)
        ])
        .padding()
    }
}
#endif
