import Foundation
import UserNotifications

enum Reminders {
    private static let identifier = "daily-practice"

    /// Schedules a repeating daily notification. Returns false if the user
    /// declined notification permission.
    @discardableResult
    static func schedule(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "C'est l'heure de parler 🇫🇷"
        content.body = messages.randomElement() ?? "Five minutes of speaking practice keeps your streak alive."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        return true
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static let messages = [
        "Five minutes of speaking practice keeps your streak alive.",
        "Your French R misses you. Come practise!",
        "Say a few phrases out loud today — your accent will thank you.",
        "Petit à petit, l'oiseau fait son nid. Time for today's practice!",
    ]
}
