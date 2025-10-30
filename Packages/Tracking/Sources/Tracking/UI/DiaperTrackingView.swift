import DesignSystem
import SwiftUI

/// Diaper tracking view with quick log buttons
public struct DiaperTrackingView: View {
    @StateObject private var viewModel: DiaperTrackingViewModel
    @Environment(\.dismiss)
    private var dismiss

    public init(viewModel: DiaperTrackingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily counter
                    dailyCounterSection

                    // Quick log buttons
                    quickLogSection

                    // Optional details
                    if viewModel.selectedType != .wet {
                        consistencySection
                    }

                    notesSection

                    // Log button
                    logButton
                }
                .padding()
            }
            .navigationTitle("Diaper Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .overlay {
                if viewModel.showSuccess {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Sections

    private var dailyCounterSection: some View {
        VStack(spacing: 8) {
            Text("Today's Changes")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(viewModel.todayCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var quickLogSection: some View {
        VStack(spacing: 12) {
            Text("What type?")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(DiaperType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedType = type
                        }
                        hapticFeedback()
                    } label: {
                        VStack(spacing: 8) {
                            Text(type.symbol)
                                .font(.system(size: 40))

                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            viewModel.selectedType == type
                                ? Color.accentColor.opacity(0.2)
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.selectedType == type
                                        ? Color.accentColor
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var consistencySection: some View {
        VStack(spacing: 12) {
            Text("Consistency (optional)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(DiaperConsistency.allCases) { cons in
                    Button {
                        withAnimation {
                            viewModel.consistency = (viewModel.consistency == cons) ? nil : cons
                        }
                        hapticFeedback(.light)
                    } label: {
                        Text(cons.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                viewModel.consistency == cons
                                    ? Color.accentColor.opacity(0.2)
                                    : Color(.secondarySystemGroupedBackground)
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        viewModel.consistency == cons
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(spacing: 12) {
            Text("Notes (optional)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Add any notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var logButton: some View {
        Button {
            Task {
                hapticFeedback(.medium)
                await viewModel.logDiaper()
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Log Diaper Change")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Logged!")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helpers

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#if DEBUG
import AppSupport

#Preview {
    DiaperTrackingView(
        viewModel: DiaperTrackingViewModel(
            repository: InMemoryEventsRepository(),
            analytics: MockAnalytics()
        )
    )
}
#endif
