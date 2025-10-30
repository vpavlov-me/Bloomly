import DesignSystem
import SwiftUI

/// Feeding tracking view supporting breast, bottle, and solid food
public struct FeedingTrackingView: View {
    @StateObject private var viewModel: FeedingTrackingViewModel
    @Environment(\.dismiss)
    private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case solidDescription
        case solidAmount
        case notes
    }

    public init(viewModel: FeedingTrackingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Type selector
                    typeSelector

                    // Content based on selected type
                    switch viewModel.selectedType {
                    case .breast:
                        breastFeedingSection
                    case .bottle:
                        bottleFeedingSection
                    case .solid:
                        solidFeedingSection
                    }

                    // Notes (common for all types)
                    notesSection

                    // Save button
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetForm()
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

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 12) {
            ForEach(FeedingType.allCases) { type in
                Button {
                    hapticFeedback(.light)
                    viewModel.selectType(type)
                } label: {
                    VStack(spacing: 8) {
                        Text(type.symbol)
                            .font(.system(size: 36))

                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        viewModel.selectedType == type
                            ? Color.accentColor.opacity(0.2)
                            : Color(.tertiarySystemGroupedBackground)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Breast Feeding

    private var breastFeedingSection: some View {
        VStack(spacing: 16) {
            // Durations summary
            durationsSummary

            // Timer display
            timerDisplay

            // Side selector
            if viewModel.breastState == .idle {
                sideSelector
            }

            // Control buttons
            breastControlButtons
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var durationsSummary: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.formattedLeftDuration)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 8) {
                Text("Right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.formattedRightDuration)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.pink)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 8) {
                Text("Total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.formatDuration(viewModel.totalBreastDuration))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 12) {
            if viewModel.isBreastActive {
                Text("Current Side: \(viewModel.currentSide.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.formattedElapsedTime)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    viewModel.currentSide == .left
                        ? .blue
                        : (viewModel.currentSide == .right ? .pink : .primary)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var sideSelector: some View {
        HStack(spacing: 12) {
            ForEach(BreastSide.allCases) { side in
                Button {
                    hapticFeedback(.light)
                    viewModel.currentSide = side
                } label: {
                    VStack(spacing: 8) {
                        Text(side.symbol)
                            .font(.system(size: 36, weight: .bold))

                        Text(side.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        viewModel.currentSide == side
                            ? (side == .left ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                            : Color(.tertiarySystemGroupedBackground)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var breastControlButtons: some View {
        VStack(spacing: 12) {
            if viewModel.breastState == .idle {
                Button {
                    hapticFeedback(.medium)
                    viewModel.startBreastFeeding()
                } label: {
                    Label("Start Feeding", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            } else if viewModel.isBreastActive {
                HStack(spacing: 12) {
                    Button {
                        hapticFeedback(.medium)
                        viewModel.switchBreastSide()
                    } label: {
                        Label("Switch Side", systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    Button {
                        hapticFeedback(.medium)
                        viewModel.pauseBreastFeeding()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }

                Button {
                    hapticFeedback(.medium)
                    viewModel.stopBreastFeeding()
                } label: {
                    Label("Stop Feeding", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            } else if viewModel.isBreastPaused {
                HStack(spacing: 12) {
                    Button {
                        hapticFeedback(.medium)
                        viewModel.resumeBreastFeeding()
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    Button {
                        hapticFeedback(.medium)
                        viewModel.stopBreastFeeding()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Bottle Feeding

    private var bottleFeedingSection: some View {
        VStack(spacing: 16) {
            Text("Volume")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Volume display
            HStack {
                Button {
                    hapticFeedback(.light)
                    viewModel.adjustBottleVolume(by: -10)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
                .disabled(viewModel.bottleVolume == 0)

                Spacer()

                VStack(spacing: 4) {
                    Text("\(viewModel.bottleVolume)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text("ml")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    hapticFeedback(.light)
                    viewModel.adjustBottleVolume(by: 10)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 16)

            // Volume presets
            VStack(spacing: 8) {
                Text("Quick Select")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.bottleVolumePresets, id: \.self) { preset in
                        Button {
                            hapticFeedback(.light)
                            viewModel.setBottleVolume(preset)
                        } label: {
                            Text("\(preset) ml")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    viewModel.bottleVolume == preset
                                        ? Color.accentColor.opacity(0.2)
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Solid Feeding

    private var solidFeedingSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text("Food Description")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("What did baby eat?", text: $viewModel.solidDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .solidDescription)
            }

            VStack(spacing: 12) {
                Text("Amount (optional)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("e.g., 1 jar, 3 spoons", text: $viewModel.solidAmount)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .solidAmount)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Notes

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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                hapticFeedback(.medium)
                await viewModel.saveFeeding()
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Save Feeding")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSave ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSave || viewModel.isLoading)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Saved!")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.selectedType.rawValue)
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

#Preview("Breast - Idle") {
    FeedingTrackingView(
        viewModel: FeedingTrackingViewModel(
            repository: InMemoryEventsRepository(),
            analytics: MockAnalytics()
        )
    )
}

#Preview("Breast - Active") {
    let vm = FeedingTrackingViewModel(
        repository: InMemoryEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.startBreastFeeding()
    return FeedingTrackingView(viewModel: vm)
}

#Preview("Bottle") {
    let vm = FeedingTrackingViewModel(
        repository: InMemoryEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.selectType(.bottle)
    vm.setBottleVolume(120)
    return FeedingTrackingView(viewModel: vm)
}

#Preview("Solid") {
    let vm = FeedingTrackingViewModel(
        repository: InMemoryEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.selectType(.solid)
    return FeedingTrackingView(viewModel: vm)
}
#endif
