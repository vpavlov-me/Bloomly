//
//  TimelineView.swift
//  BabyTrack
//
//  SwiftUI timeline list with accessibility support.
//

import SwiftUI
import Tracking
import Measurements
import Content
import DesignSystem

public struct TimelineView: View {
    @StateObject private var viewModel: TimelineViewModel

    public init(viewModel: @autoclosure @escaping () -> TimelineViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        List {
            if viewModel.entries.isEmpty && !viewModel.isLoading {
                Text(L10n.timelineEmptyState())
                    .font(BabyTrackFont.body(17))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.timelineEmptyState())
            } else {
                ForEach(viewModel.entries) { entry in
                    entryView(entry)
                        .listRowInsets(EdgeInsets(top: BabyTrackSpacing.small.rawValue, leading: BabyTrackSpacing.medium.rawValue, bottom: BabyTrackSpacing.small.rawValue, trailing: BabyTrackSpacing.medium.rawValue))
                }
            }
        }
        .task { await viewModel.reload() }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private func entryView(_ entry: TimelineEntry) -> some View {
        switch entry.kind {
        case let .event(event):
            EventRow(event: event)
        case let .measurement(measurement):
            MeasurementRow(sample: measurement)
        }
    }
}

private struct EventRow: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: BabyTrackSpacing.small.rawValue) {
            Text(event.kind.rawValue.capitalized)
                .font(BabyTrackFont.heading(22))
            Text(event.start, style: .time)
                .font(BabyTrackFont.body(15))
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(BabyTrackFont.body(15))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizedStringKey(event.kind.rawValue))
    }
}

private struct MeasurementRow: View {
    let sample: MeasurementSample

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sample.type.rawValue.capitalized)
                    .font(BabyTrackFont.heading(20))
                Text(sample.date, style: .date)
                    .font(BabyTrackFont.body(15))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.2f %@", sample.value, sample.unit))
                .font(BabyTrackFont.heading(18))
        }
        .accessibilityElement(children: .combine)
    }
}
