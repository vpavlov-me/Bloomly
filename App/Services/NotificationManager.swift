import Foundation
import UserNotifications
import Tracking
import Content

/// Manages local notifications for reminders (feeding, sleep, diaper changes)
@MainActor
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published public var isNotificationEnabled: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()
    private var quietHoursStart: DateComponents = DateComponents(hour: 21, minute: 0)
    private var quietHoursEnd: DateComponents = DateComponents(hour: 8, minute: 0)

    public override init() {
        super.init()
        notificationCenter.delegate = self
        checkNotificationStatus()
    }

    // MARK: - Public Methods

    /// Request user permission for notifications
    public func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isNotificationEnabled = granted
            }
            return granted
        } catch {
            return false
        }
    }

    /// Check if notifications are currently enabled
    public func checkNotificationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Schedule a reminder notification for a specific event type
    /// - Parameters:
    ///   - eventKind: The type of event to be reminded about
    ///   - interval: Time interval in seconds until the reminder
    ///   - quietHoursEnabled: Whether to respect quiet hours
    public func scheduleReminder(
        for eventKind: EventKind,
        in interval: TimeInterval,
        quietHoursEnabled: Bool = true
    ) async {
        guard isNotificationEnabled else { return }

        // Check if current time is within quiet hours
        if quietHoursEnabled && isInQuietHours() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: getReminderTitle(for: eventKind))
        content.body = String(localized: getReminderMessage(for: eventKind))
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

        // Add custom data for deep linking
        content.userInfo = [
            "eventKind": eventKind.rawValue,
            "type": "reminder"
        ]

        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder_\(eventKind.rawValue)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            debugPrint("Failed to schedule notification: \(error)")
        }
    }

    /// Schedule a recurring reminder
    /// - Parameters:
    ///   - eventKind: The type of event to be reminded about
    ///   - interval: Time interval in seconds between reminders
    ///   - quietHoursEnabled: Whether to respect quiet hours
    public func scheduleRecurringReminder(
        for eventKind: EventKind,
        every interval: TimeInterval,
        quietHoursEnabled: Bool = true
    ) async {
        guard isNotificationEnabled else { return }

        if quietHoursEnabled && isInQuietHours() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: getReminderTitle(for: eventKind))
        content.body = String(localized: getReminderMessage(for: eventKind))
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

        content.userInfo = [
            "eventKind": eventKind.rawValue,
            "type": "recurring_reminder"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(
            identifier: "recurring_reminder_\(eventKind.rawValue)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            debugPrint("Failed to schedule recurring reminder: \(error)")
        }
    }

    /// Cancel a reminder
    /// - Parameter eventKind: The event kind to cancel reminders for
    public func cancelReminder(for eventKind: EventKind) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["recurring_reminder_\(eventKind.rawValue)"]
        )
    }

    /// Cancel all reminders
    public func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Set quiet hours
    /// - Parameters:
    ///   - startHour: Hour when quiet hours begin (0-23)
    ///   - startMinute: Minute when quiet hours begin (0-59)
    ///   - endHour: Hour when quiet hours end (0-23)
    ///   - endMinute: Minute when quiet hours end (0-59)
    public func setQuietHours(
        from startHour: Int,
        startMinute: Int = 0,
        to endHour: Int,
        endMinute: Int = 0
    ) {
        self.quietHoursStart = DateComponents(hour: startHour, minute: startMinute)
        self.quietHoursEnd = DateComponents(hour: endHour, minute: endMinute)
    }

    /// Check if current time is within quiet hours
    private func isInQuietHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)

        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute,
              let startHour = quietHoursStart.hour,
              let startMinute = quietHoursStart.minute,
              let endHour = quietHoursEnd.hour,
              let endMinute = quietHoursEnd.minute else {
            return false
        }

        let currentTotalMinutes = currentHour * 60 + currentMinute
        let startTotalMinutes = startHour * 60 + startMinute
        let endTotalMinutes = endHour * 60 + endMinute

        // Handle case where quiet hours span midnight
        if startTotalMinutes > endTotalMinutes {
            return currentTotalMinutes >= startTotalMinutes || currentTotalMinutes < endTotalMinutes
        } else {
            return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Always show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let eventKindString = userInfo["eventKind"] as? String,
           let eventKind = EventKind(rawValue: eventKindString) {
            // Post notification for deep linking
            NotificationCenter.default.post(
                name: NSNotification.Name("notificationTapped"),
                object: nil,
                userInfo: ["eventKind": eventKind]
            )
        }

        completionHandler()
    }

    // MARK: - Private Helpers

    private func getReminderTitle(for eventKind: EventKind) -> LocalizedStringKey {
        switch eventKind {
        case .feed:
            return AppCopy.Notifications.feedReminder
        case .sleep:
            return AppCopy.Notifications.sleepReminder
        case .diaper:
            return AppCopy.Notifications.diaperReminder
        }
    }

    private func getReminderMessage(for eventKind: EventKind) -> LocalizedStringKey {
        switch eventKind {
        case .feed:
            return AppCopy.Notifications.feedBody
        case .sleep:
            return AppCopy.Notifications.sleepBody
        case .diaper:
            return AppCopy.Notifications.diaperBody
        }
    }
}
