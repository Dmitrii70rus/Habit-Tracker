import Foundation
import UserNotifications

@MainActor
final class ReminderManager: ObservableObject {
    @Published var permissionDeniedMessage: String?

    private let calendar = Calendar.current
    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "habit-reminder-"

    func requestPermissionIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                permissionDeniedMessage = "Couldn't request notification permission."
                return false
            }
        case .denied:
            permissionDeniedMessage = "Notifications are disabled for Habit Tracker. You can enable them in Settings."
            return false
        @unknown default:
            return false
        }
    }

    func scheduleRollingReminders(for habits: [Habit], daysAhead: Int = 10) async {
        await removeExistingHabitNotifications()

        let allowed = await requestPermissionIfNeeded()
        guard allowed else { return }

        let today = calendar.startOfDay(for: .now)

        for habit in habits where habit.isReminderEnabled {
            guard let reminderTime = habit.reminderTime else { continue }

            for dayOffset in 0..<daysAhead {
                guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let normalizedTargetDay = calendar.startOfDay(for: targetDay)

                guard habit.isActive(on: normalizedTargetDay), habit.isPlanned(on: normalizedTargetDay) else {
                    continue
                }

                await scheduleReminder(for: habit, on: normalizedTargetDay, reminderTime: reminderTime)
            }
        }
    }

    func clearMessage() {
        permissionDeniedMessage = nil
    }

    private func scheduleReminder(for habit: Habit, on day: Date, reminderTime: Date) async {
        var dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        dayComponents.hour = timeComponents.hour
        dayComponents.minute = timeComponents.minute

        guard let fireDate = calendar.date(from: dayComponents), fireDate > .now else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = habit.title
        content.body = "Time for your habit today."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: false)
        let dayID = day.formatted(.dateTime.year().month().day())
        let identifier = "\(notificationPrefix)\(habit.id.uuidString)-\(dayID)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            permissionDeniedMessage = "Couldn't schedule reminders for \(habit.title)."
        }
    }

    private func removeExistingHabitNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(notificationPrefix) }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}


extension Notification.Name {
    static let habitDataDidChange = Notification.Name("habitDataDidChange")
}
