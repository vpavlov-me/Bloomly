import AppSupport
import Content
import SwiftUI
import Tracking
import WatchKit

/// Quick action view with large, prominent buttons for common tracking actions
public struct QuickActionsView: View {
    @Environment(\.eventsRepository) private var eventsRepository
    @Environment(\.analytics) private var analytics
    @StateObject private var connectivity = WatchConnectivityService.shared

    @State private var isLoggingSleep = false
    @State private var isLoggingFeed = false
    @State private var showDiaperOptions = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Sleep - Prominent action
                sleepButton

                // Feeding - Repeat last feed
                feedButton

                // Diaper - Quick options
                diaperButton

                // Pumping (if needed)
                pumpingButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .navigationTitle("Quick Log")
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .confirmationDialog("Diaper Change", isPresented: $showDiaperOptions) {
            Button("💧 Wet") { Task { await logDiaper(type: "wet") } }
            Button("💩 Dirty") { Task { await logDiaper(type: "dirty") } }
            Button("💧💩 Both") { Task { await logDiaper(type: "both") } }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Sleep Button

    private var sleepButton: some View {
        Button {
            Task { await toggleSleep() }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 40))
                Text("Sleep")
                    .font(.headline)
                if isLoggingSleep {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.blue.opacity(0.2))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feed Button

    private var feedButton: some View {
        Button {
            Task { await logFeed() }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "bottle.fill")
                    .font(.system(size: 36))
                Text("Feed")
                    .font(.headline)
                Text("Repeat Last")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if isLoggingFeed {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.pink.opacity(0.2))
            .foregroundStyle(.pink)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Diaper Button

    private var diaperButton: some View {
        Button {
            provideTapticFeedback()
            showDiaperOptions = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                Text("Diaper")
                    .font(.headline)
                Text("Tap for Options")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.yellow.opacity(0.2))
            .foregroundStyle(.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pumping Button

    private var pumpingButton: some View {
        Button {
            Task { await logPumping() }
        } label: {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text("Pumping")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.cyan.opacity(0.2))
            .foregroundStyle(.cyan)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func toggleSleep() async {
        isLoggingSleep = true
        defer { isLoggingSleep = false }

        provideTapticFeedback(.start)
        analytics.track(.init(type: .watchQuickActionUsed, metadata: ["action": "sleep"]))

        do {
            // Check if there's an active sleep session
            let recentSleep = try? await eventsRepository.lastEvent(for: .sleep)

            if let activeSleep = recentSleep, activeSleep.end == nil {
                // Stop active sleep
                var updated = activeSleep
                updated.end = Date()
                _ = try await eventsRepository.update(updated)

                // Send to iPhone
                connectivity.sendEvent(updated)

                let duration = updated.duration ?? 0
                let hours = Int(duration / 3600)
                let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

                provideSuccessFeedback()
                successMessage = "Sleep logged: \(hours)h \(minutes)m"
                showSuccess = true
            } else {
                // Start new sleep
                let dto = EventDTO(kind: .sleep, start: Date())
                let created = try await eventsRepository.create(dto)

                // Send to iPhone
                connectivity.sendEvent(created)

                provideSuccessFeedback()
                successMessage = "Sleep started"
                showSuccess = true
            }
        } catch {
            provideErrorFeedback()
            errorMessage = error.localizedDescription
        }
    }

    private func logFeed() async {
        isLoggingFeed = true
        defer { isLoggingFeed = false }

        provideTapticFeedback()
        analytics.track(.init(type: .watchQuickActionUsed, metadata: ["action": "feed"]))

        do {
            // Get last feeding to repeat duration
            let lastFeed = try? await eventsRepository.lastEvent(for: .feeding)
            let duration = lastFeed?.duration ?? 900 // Default 15 min

            let start = Date()
            let end = start.addingTimeInterval(duration)
            let dto = EventDTO(kind: .feeding, start: start, end: end)
            let created = try await eventsRepository.create(dto)

            // Send to iPhone
            connectivity.sendEvent(created)

            provideSuccessFeedback()
            let minutes = Int(duration / 60)
            successMessage = "Feed logged: \(minutes) min"
            showSuccess = true
        } catch {
            provideErrorFeedback()
            errorMessage = error.localizedDescription
        }
    }

    private func logDiaper(type: String) async {
        provideTapticFeedback()
        analytics.track(.init(type: .watchQuickActionUsed, metadata: ["action": "diaper", "type": type]))

        do {
            let notes = type.capitalized
            let dto = EventDTO(kind: .diaper, start: Date(), notes: notes)
            let created = try await eventsRepository.create(dto)

            // Send to iPhone
            connectivity.sendEvent(created)

            provideSuccessFeedback()
            successMessage = "\(notes) diaper logged"
            showSuccess = true
        } catch {
            provideErrorFeedback()
            errorMessage = error.localizedDescription
        }
    }

    private func logPumping() async {
        provideTapticFeedback()
        analytics.track(.init(type: .watchQuickActionUsed, metadata: ["action": "pumping"]))

        do {
            let dto = EventDTO(kind: .pumping, start: Date(), end: Date().addingTimeInterval(600))
            let created = try await eventsRepository.create(dto)

            // Send to iPhone
            connectivity.sendEvent(created)

            provideSuccessFeedback()
            successMessage = "Pumping logged"
            showSuccess = true
        } catch {
            provideErrorFeedback()
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Haptic Feedback

    private func provideTapticFeedback(_ type: WKHapticType = .click) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(type)
        #endif
    }

    private func provideSuccessFeedback() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    private func provideErrorFeedback() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.failure)
        #endif
    }
}

#if DEBUG
struct QuickActionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickActionsView()
                .environment(\.eventsRepository, PreviewEventsRepository())
        }
    }

    private struct PreviewEventsRepository: EventsRepository {
        func create(_ dto: EventDTO) async throws -> EventDTO { dto }
        func update(_ dto: EventDTO) async throws -> EventDTO { dto }
        func delete(id: UUID) async throws {}
        func events(in interval: DateInterval?, kind: EventKind?) async throws -> [EventDTO] {
            [EventDTO(kind: .sleep, start: Date(), end: nil)]
        }
        func lastEvent(for kind: EventKind) async throws -> EventDTO? {
            EventDTO(kind: kind, start: Date().addingTimeInterval(-900), end: Date())
        }
        func stats(for day: Date) async throws -> EventDayStats {
            .init(date: Date(), totalEvents: 5, totalDuration: 3600)
        }
    }
}
#endif
