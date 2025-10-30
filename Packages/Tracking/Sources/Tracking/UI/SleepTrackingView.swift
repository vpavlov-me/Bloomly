import DesignSystem
import SwiftUI

/// Sleep tracking view with prominent timer
public struct SleepTrackingView: View {
    @StateObject private var viewModel: SleepTrackingViewModel
    @Environment(\.dismiss)
    private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case notes
    }

    public init(viewModel: SleepTrackingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Totals section
                    totalsSection

                    // Timer section (prominent)
                    timerSection

                    // Quality selection
                    if case .completed = viewModel.state {
                        qualitySection
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
            .navigationTitle("Sleep")
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

                Text(String(format: "%.1f h", viewModel.todayTotalHours))
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

                Text(String(format: "%.1f h", viewModel.weekTotalHours))
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
        VStack(spacing: 24) {
            // Large timer display
            VStack(spacing: 12) {
                if case .completed(let duration) = viewModel.state {
                    Text("Sleep Duration")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(formatDuration(duration))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.purple)
                } else {
                    Text(viewModel.formattedElapsedTime)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(viewModel.isActive ? .purple : .primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)

            // Timer controls
            if viewModel.state == .idle {
                Button {
                    hapticFeedback(.medium)
                    viewModel.startSleep()
                } label: {
                    Label("Start Sleep", systemImage: "moon.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            } else if viewModel.isActive {
                Button {
                    hapticFeedback(.medium)
                    viewModel.stopSleep()
                } label: {
                    Label("Wake Up", systemImage: "sun.max.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
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

    private var qualitySection: some View {
        VStack(spacing: 16) {
            Text("Sleep Quality")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(SleepQuality.allCases) { quality in
                    Button {
                        hapticFeedback(.light)
                        viewModel.selectedQuality = quality
                    } label: {
                        VStack(spacing: 8) {
                            Text(quality.symbol)
                                .font(.system(size: 36))

                            Text(quality.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.selectedQuality == quality
                                ? Color.purple.opacity(0.2)
                                : Color(.tertiarySystemGroupedBackground)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        Group {
            if case .completed = viewModel.state {
                Button {
                    Task {
                        hapticFeedback(.medium)
                        await viewModel.saveSleep()
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Sleep Session")
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

            if case .completed(let duration) = viewModel.state {
                Text(formatDuration(duration))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#if DEBUG
import AppSupport

#Preview("Idle") {
    SleepTrackingView(
        viewModel: SleepTrackingViewModel(
            repository: InMemoryEventsRepository(),
            analytics: MockAnalytics()
        )
    )
}

#Preview("Active") {
    let vm = SleepTrackingViewModel(
        repository: InMemoryEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.startSleep()
    return SleepTrackingView(viewModel: vm)
}

#Preview("Completed") {
    let vm = SleepTrackingViewModel(
        repository: InMemoryEventsRepository(),
        analytics: MockAnalytics()
    )
    vm.startSleep()
    vm.stopSleep()
    return SleepTrackingView(viewModel: vm)
}
#endif
