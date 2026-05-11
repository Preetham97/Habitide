import Foundation
import UserNotifications

enum NotificationManager {
    static let identifier = "habitide.daily-reminder"
    private static let enabledKey = "habitide.reminderEnabled"
    private static let hourKey = "habitide.reminderHour"
    private static let minuteKey = "habitide.reminderMinute"

    // MARK: - Preferences

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: enabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var reminderTime: DateComponents {
        get {
            let h = UserDefaults.standard.object(forKey: hourKey) as? Int ?? 22
            let m = UserDefaults.standard.object(forKey: minuteKey) as? Int ?? 0
            return DateComponents(hour: h, minute: m)
        }
        set {
            UserDefaults.standard.set(newValue.hour ?? 22, forKey: hourKey)
            UserDefaults.standard.set(newValue.minute ?? 0, forKey: minuteKey)
        }
    }

    // MARK: - Authorization

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard isEnabled else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "How did today go?"
        content.body = "Tap to log your routine."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: reminderTime,
            repeats: true
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
