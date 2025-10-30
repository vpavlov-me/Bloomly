import DesignSystem
import SwiftUI

/// Pumping tracking view with timer and volume inputs
public struct PumpingTrackingView: View {
    @StateObject private var viewModel: PumpingTrackingViewModel
    @Environment(\.dismiss)
    private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case left, right, notes
    }

    public init(viewModel: PumpingTrackingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Totals section
                    totalsSection

                    // Timer section
                    timerSection

                    // Volume inputs
                    if viewModel.state != .idle {
                        volumeSection
                    }

                    // Notes
                    if case .completed = viewModel.state {
                        notesSection
                    }

                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Pumping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.isActive {
                            viewModel.cancelSession()
                        }
                        dismiss()
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
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

    private var totalsSection: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(viewModel.todayTotal) ml")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(spacing: 8) {
                Text("This Week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(viewModel.weekTotal) ml")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var timerSection: some View {
        VStack(spacing: 16) {
            // Timer display
            Text(viewModel.formattedElapsedTime)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(viewModel.isActive ? .green : .primary)

            // Timer controls
            if viewModel.state == .idle {
                Button {
                    hapticFeedback(.medium)
                    viewModel.startPumping()
                } label: {
                    Label("Start Pumping", systemImage: "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            } else if viewModel.isActive {
                Button {
                    hapticFeedback(.medium)
                    viewModel.stopPumping()
                } label: {
                    Label("Stop Pumping", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var volumeSection: some View {
        VStack(spacing: 20) {
            // Left breast
            VStack(spacing: 12) {
                HStack {
                    Text("Left Breast")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.leftBreastVolume) ml")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }

                // Presets
                HStack(spacing: 8) {
                    ForEach(PumpingTrackingViewModel.volumePresets, id: \.self) { preset in
                        Button {
                            hapticFeedback(.light)
                            viewModel.applyLeftPreset(preset)
                        } label: {
                            Text("\(preset)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.leftBreastVolume == preset
                                        ? Color.blue.opacity(0.2)
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Custom input
                TextField("Custom (ml)", value: $viewModel.leftBreastVolume, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .left)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Right breast
            VStack(spacing: 12) {
                HStack {
                    Text("Right Breast")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.rightBreastVolume) ml")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                }

                // Presets
                HStack(spacing: 8) {
                    ForEach(PumpingTrackingViewModel.volumePresets, id: \.self) { preset in
                        Button {
                            hapticFeedback(.light)
                            viewModel.applyRightPreset(preset)
                        } label: {
                            Text("\(preset)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.rightBreastVolume == preset
                                        ? Color.pink.opacity(0.2)
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Custom input
                TextField("Custom (ml)", value: $viewModel.rightBreastVolume, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .right)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Total volume
            HStack {
                Text("Total Volume")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.totalVolume) ml")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
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
                .focused($focusedField, equals: .notes)
        }
    }

    private var actionButtons: some View {
        Group {
            if case .completed = viewModel.state {
                Button {
                    Task {
                        hapticFeedback(.medium)
                        await viewModel.savePumping()
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Pumping Session")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.totalVolume > 0 ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading || viewModel.totalVolume == 0)
            }
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Saved!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(viewModel.totalVolume) ml")
                .font(.headline)
                .foregroundStyle(.secondary)
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

#Preview("Idle") {
    PumpingTrackingView(
        viewModel: PumpingTrackingViewModel(
            repository: InMemoryEventsRepository(),
            analytics: MockAnalytics()
        )
    )
}

#Preview("Active") {
    let vm = PumpingTrackingViewModel(
        repository: InMemoryEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.startPumping()
    return PumpingTrackingView(viewModel: vm)
}
#endif
