import Foundation

enum L10n {
    static let appName = String(localized: "app.name")
    static let addHabit = String(localized: "action.add_habit")
    static let editHabit = String(localized: "action.edit")
    static let delete = String(localized: "action.delete")
    static let cancel = String(localized: "action.cancel")
    static let ok = String(localized: "action.ok")

    static let alertDeleteHabitTitle = String(localized: "alert.delete_habit.title")
    static let alertDeleteHabitButton = String(localized: "alert.delete_habit.confirm")
    static let alertDeleteHabitMessage = String(localized: "alert.delete_habit.message")

    static let alertGenericErrorTitle = String(localized: "alert.error.title")
    static let alertReminderPermissionTitle = String(localized: "alert.reminder_permission.title")
    static let alertPurchaseTitle = String(localized: "alert.purchase.title")

    static let addHabitTitle = String(localized: "sheet.add_habit.title")
    static let addHabitSave = String(localized: "sheet.add_habit.save")
    static let editHabitTitle = String(localized: "sheet.edit_habit.title")
    static let editHabitSave = String(localized: "sheet.edit_habit.save")

    static let emptyNoHabitsForDateTitle = String(localized: "empty.no_habits_for_date.title")
    static let emptyNoHabitsForDateMessage = String(localized: "empty.no_habits_for_date.message")

    static let paywallTitle = String(localized: "paywall.title")
    static let paywallSubtitle = String(localized: "paywall.subtitle")
    static let paywallLoadingOptions = String(localized: "paywall.loading_options")
    static let paywallUnavailableTitle = String(localized: "paywall.unavailable.title")
    static let paywallUnavailableMessage = String(localized: "paywall.unavailable.message")
    static let paywallTryAgain = String(localized: "paywall.try_again")
    static let paywallLoadingPurchase = String(localized: "paywall.loading_purchase")
    static let paywallUnavailableCta = String(localized: "paywall.unavailable_cta")
    static let paywallRestore = String(localized: "paywall.restore")
    static let paywallClose = String(localized: "paywall.close")

    static let paywallBenefitUnlimited = String(localized: "paywall.benefit.unlimited")
    static let paywallBenefitReminders = String(localized: "paywall.benefit.reminders")
    static let paywallBenefitStats = String(localized: "paywall.benefit.stats")
    static let paywallBenefitUpdates = String(localized: "paywall.benefit.updates")

    static let emptyHabitsTitle = String(localized: "empty.habits.title")
    static let emptyHabitsMessage = String(localized: "empty.habits.message")
    static let emptyHabitsButton = String(localized: "empty.habits.button")

    static let reminderPermissionRequestFailed = String(localized: "reminder.permission_request_failed")
    static let reminderPermissionDenied = String(localized: "reminder.permission_denied")
    static let reminderBodyToday = String(localized: "reminder.body.today")
    static func reminderScheduleFailed(_ title: String) -> String {
        String(format: String(localized: "reminder.schedule_failed"), title)
    }

    static let purchaseUnavailable = String(localized: "purchase.unavailable")
    static let purchaseVerifyFailed = String(localized: "purchase.verify_failed")
    static let purchasePending = String(localized: "purchase.pending")
    static let purchaseFailed = String(localized: "purchase.failed")
    static let purchaseFailedConnection = String(localized: "purchase.failed.connection")
    static let purchaseRestoreSuccess = String(localized: "purchase.restore.success")
    static let purchaseRestoreNone = String(localized: "purchase.restore.none")
    static let purchaseRestoreFailed = String(localized: "purchase.restore.failed")
    static let purchaseProductUnavailable = String(localized: "purchase.product.unavailable")

    static let summaryThisWeek = String(localized: "summary.this_week")
    static let summaryOverallStreak = String(localized: "summary.overall_streak")
    static let summaryDailyReminder = String(localized: "summary.daily_reminder")
    static let summaryPlanned = String(localized: "summary.planned")
    static let summaryDone = String(localized: "summary.done")
    static let summaryRemaining = String(localized: "summary.remaining")

    static func paywallUnlockCta(_ price: String) -> String {
        String(format: String(localized: "paywall.cta.unlock"), price)
    }

    static func habitsCompleted(_ completed: Int, _ total: Int) -> String {
        String(format: String(localized: "summary.progress.completed"), completed, total)
    }

    static func habitsCompletedWeek(_ completed: Int, _ scheduled: Int) -> String {
        String(format: String(localized: "summary.week.completed"), completed, scheduled)
    }

    static func streakCurrent(_ days: Int) -> String {
        String(format: String(localized: "summary.streak.current"), days)
    }

    static func streakBest(_ days: Int) -> String {
        String(format: String(localized: "summary.streak.best"), days)
    }

    static func progressPlanned(_ planned: Int) -> String {
        String(format: String(localized: "summary.progress.planned"), planned)
    }

    static let motivationFutureNone = String(localized: "summary.motivation.future_none")
    static let motivationFuturePlanned = String(localized: "summary.motivation.future_planned")
    static let motivationPerfectDay = String(localized: "summary.motivation.perfect")
    static let motivationKeepGoing = String(localized: "summary.motivation.keep_going")
}
