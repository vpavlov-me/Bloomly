import Charts
import Content
import DesignSystem
import SwiftUI

public struct GrowthChartsView: View {
    private let measurements: [MeasurementDTO]
    private let isPremium: Bool
    private let babyGender: WHOPercentiles.Gender
    private let birthDate: Date

    public init(
        measurements: [MeasurementDTO],
        isPremium: Bool,
        babyGender: WHOPercentiles.Gender = .male,
        birthDate: Date = Date()
    ) {
        self.measurements = measurements
        self.isPremium = isPremium
        self.babyGender = babyGender
        self.birthDate = birthDate
    }

    public var body: some View {
        if measurements.isEmpty {
            EmptyStateView(
                icon: Symbols.chart,
                title: AppCopy.string(for: "measurements.list.empty"),
                message: AppCopy.string(for: "measurements.list.empty.message")
            )
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            VStack(spacing: BabyTrackTheme.spacing.lg) {
                if let heightSeries = series(for: .height) {
                    chartCard(
                        titleKey: MeasurementType.height.titleKey,
                        series: heightSeries,
                        type: .height
                    )
                }
                if let weightSeries = series(for: .weight) {
                    chartCard(
                        titleKey: MeasurementType.weight.titleKey,
                        series: weightSeries,
                        type: .weight
                    )
                }
                if let headSeries = series(for: .head), isPremium {
                    chartCard(
                        titleKey: MeasurementType.head.titleKey,
                        series: headSeries,
                        type: .head
                    )
                } else if !isPremium {
                    premiumBanner
                }
            }
        }
    }

    private var premiumBanner: some View {
        HStack(spacing: BabyTrackTheme.spacing.sm) {
            Image(systemName: Symbols.premium)
                .foregroundStyle(.yellow)
            Text(AppCopy.string(for: "measurements.growth.premium"))
                .font(BabyTrackTheme.typography.callout.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)
        }
        .padding(BabyTrackTheme.spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: BabyTrackTheme.radii.soft)
                .fill(BabyTrackTheme.palette.secondaryBackground)
        )
    }

    private func chartCard(
        titleKey: String,
        series: [MeasurementDTO],
        type: MeasurementType
    ) -> some View {
        ChartCard(
            title: AppCopy.string(for: titleKey),
            subtitle: isPremium ? AppCopy.string(for: "measurements.growth.subtitle") : nil
        ) {
            Chart {
                // WHO Percentile curves (Premium feature)
                if isPremium {
                    percentileLayer(for: type)
                }

                // User's actual measurements
                ForEach(series, id: \.id) { measurement in
                    LineMark(
                        x: .value("Date", measurement.date),
                        y: .value("Value", measurement.value)
                    )
                    .symbol(.circle)
                    .foregroundStyle(BabyTrackTheme.palette.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    PointMark(
                        x: .value("Date", measurement.date),
                        y: .value("Value", measurement.value)
                    )
                    .symbol(.circle)
                    .symbolSize(60)
                    .foregroundStyle(BabyTrackTheme.palette.accent)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
        }
    }

    @ChartContentBuilder
    private func percentileLayer(for type: MeasurementType) -> some ChartContent {
        // Show 3rd, 50th, and 97th percentile curves
        let curves: [WHOPercentiles.Curve] = [.p3, .p50, .p97]

        ForEach(curves, id: \.rawValue) { curve in
            let percentileData = percentilePoints(for: type, curve: curve)

            LineMark(
                x: .value("Age", \.date),
                y: .value("Value", \.value),
                series: .value("Percentile", curve.label)
            )
            .foregroundStyle(percentileColor(for: curve).opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .interpolationMethod(.catmullRom)
        }
    }

    private func percentilePoints(
        for type: MeasurementType,
        curve: WHOPercentiles.Curve
    ) -> [(date: Date, value: Double)] {
        let percentileData: [WHOPercentiles.PercentilePoint]

        switch type {
        case .height:
            percentileData = WHOPercentiles.heightPercentile(for: babyGender, curve: curve)
        case .weight:
            percentileData = WHOPercentiles.weightPercentile(for: babyGender, curve: curve)
        case .head:
            percentileData = WHOPercentiles.headPercentile(for: babyGender, curve: curve)
        }

        // Convert age in months to actual dates based on birth date
        let calendar = Calendar.current
        return percentileData.compactMap { point in
            guard let date = calendar.date(byAdding: .month, value: point.ageMonths, to: birthDate) else {
                return nil
            }
            return (date: date, value: point.value)
        }
    }

    private func percentileColor(for curve: WHOPercentiles.Curve) -> Color {
        switch curve {
        case .p3, .p97:
            return BabyTrackTheme.palette.warning
        case .p50:
            return BabyTrackTheme.palette.success
        default:
            return BabyTrackTheme.palette.mutedText
        }
    }

    private func series(for type: MeasurementType) -> [MeasurementDTO]? {
        let filtered = measurements.filter { $0.type == type }.sorted { $0.date < $1.date }
        return filtered.isEmpty ? nil : filtered
    }
}

#if DEBUG
struct GrowthChartsView_Previews: PreviewProvider {
    static var previews: some View {
        let birthDate = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        let samples = stride(from: 0, to: 12, by: 2).map { offset in
            let date = Calendar.current.date(byAdding: .month, value: offset, to: birthDate) ?? Date()
            return MeasurementDTO(
                type: .height,
                value: 50 + Double(offset) * 2.5,
                unit: "cm",
                date: date
            )
        }

        VStack {
            GrowthChartsView(
                measurements: samples,
                isPremium: true,
                babyGender: .male,
                birthDate: birthDate
            )
            .padding()

            Divider()

            GrowthChartsView(
                measurements: samples,
                isPremium: false,
                babyGender: .male,
                birthDate: birthDate
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
