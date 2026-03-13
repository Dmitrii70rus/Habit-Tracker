import Foundation

enum L10n {
    static let appName = String(localized: "app.name")
    static let today = String(localized: "time.today")
    static let yesterday = String(localized: "time.yesterday")
    static let tomorrow = String(localized: "time.tomorrow")
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

    static let formHabitSection = String(localized: "form.habit.section")
    static let formHabitPlaceholder = String(localized: "form.habit.placeholder")
    static let formStartDate = String(localized: "form.start_date")
    static let formQuickStart = String(localized: "form.quick_start")
    static let formStart = String(localized: "form.start")
    static let formRecurrenceSection = String(localized: "form.recurrence.section")
    static let formRepeats = String(localized: "form.repeats")
    static let formRemindersSection = String(localized: "form.reminders.section")
    static let formEnableReminder = String(localized: "form.reminders.enable")
    static let formReminderTime = String(localized: "form.reminders.time")
    static let formCustomDays = String(localized: "form.custom_days")

    static let startOptionToday = String(localized: "start_option.today")
    static let startOptionSelectedDate = String(localized: "start_option.selected_date")

    static let emptyNoHabitsForDateTitle = String(localized: "empty.no_habits_for_date.title")
    static let emptyNoHabitsForDateMessage = String(localized: "empty.no_habits_for_date.message")
    static let emptyHabitsTitle = String(localized: "empty.habits.title")
    static let emptyHabitsMessage = String(localized: "empty.habits.message")
    static let emptyHabitsButton = String(localized: "empty.habits.button")
    static let emptyNoHistory = String(localized: "empty.history.title")
    static let emptyNoHistoryMessage = String(localized: "empty.history.message")

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

    static let detailTitle = String(localized: "detail.title")
    static let detailChooseDate = String(localized: "detail.choose_date")
    static let detailChooseDateHint = String(localized: "detail.choose_date.hint")
    static let detailSelectedDay = String(localized: "detail.selected_day")
    static let detailStats = String(localized: "detail.stats")
    static let detailWeeklyProgress = String(localized: "detail.weekly_progress")
    static let detailWeeklyLegend = String(localized: "detail.weekly_legend")
    static let detailHeatmapTitle = String(localized: "detail.heatmap.title")
    static let detailHeatmapLegend = String(localized: "detail.heatmap.legend")
    static let detailPlannedFromRecurrence = String(localized: "detail.planned_from_recurrence")
    static let detailActionsDisabledBeforeStart = String(localized: "detail.actions_before_start")
    static let detailFutureRuleMessage = String(localized: "detail.future_rule_message")
    static let detailPastRuleMessage = String(localized: "detail.past_rule_message")

    static let statusNotActiveYet = String(localized: "status.not_active")
    static let statusCompleted = String(localized: "status.completed")
    static let statusPlanned = String(localized: "status.planned")
    static let statusNotCompleted = String(localized: "status.not_completed")
    static let statusNoPlan = String(localized: "status.no_plan")

    static let actionRemovePlan = String(localized: "action.remove_plan")
    static let actionMarkPlanned = String(localized: "action.mark_planned")
    static let actionUnmarkComplete = String(localized: "action.unmark_complete")
    static let actionMarkComplete = String(localized: "action.mark_complete")

    static let rowPlannedForDay = String(localized: "row.planned_for_day")
    static let rowNoPlanForDay = String(localized: "row.no_plan_for_day")
    static let rowPlannedByRecurrence = String(localized: "row.planned_by_recurrence")
    static let rowNotScheduled = String(localized: "row.not_scheduled")
    static let rowPlannedAutomatically = String(localized: "row.planned_automatically")
    static let rowRemovePlannedDay = String(localized: "row.remove_planned_day")

    static let detailStatusCompletedSubtitle = String(localized: "detail.status.completed_subtitle")
    static let detailStatusPlannedSubtitle = String(localized: "detail.status.planned_subtitle")
    static let detailStatusMissedSubtitle = String(localized: "detail.status.missed_subtitle")
    static let detailStatusNoneSubtitle = String(localized: "detail.status.none_subtitle")

    static let reminderPermissionRequestFailed = String(localized: "reminder.permission_request_failed")
    static let reminderPermissionDenied = String(localized: "reminder.permission_denied")
    static let reminderBodyToday = String(localized: "reminder.body.today")

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
    static let statCurrentStreak = String(localized: "stat.current_streak")
    static let statBestStreak = String(localized: "stat.best_streak")
    static let statCompletionRate = String(localized: "stat.completion_rate")
    static let statTotalCompletions = String(localized: "stat.total_completions")
    static let statScheduledDays = String(localized: "stat.scheduled_days")

    static let motivationFutureNone = String(localized: "summary.motivation.future_none")
    static let motivationFuturePlanned = String(localized: "summary.motivation.future_planned")
    static let motivationPerfectDay = String(localized: "summary.motivation.perfect")
    static let motivationKeepGoing = String(localized: "summary.motivation.keep_going")
    static let analyticsGreat = String(localized: "analytics.motivation.great")
    static let analyticsConsistent = String(localized: "analytics.motivation.consistent")
    static let analyticsAlmost = String(localized: "analytics.motivation.almost")
    static let analyticsWeekNone = String(localized: "analytics.week.none")

    static let recurrenceOneTime = String(localized: "recurrence.one_time")
    static let recurrenceEveryDay = String(localized: "recurrence.daily")
    static let recurrenceWeekdays = String(localized: "recurrence.weekdays")
    static let recurrenceWeekends = String(localized: "recurrence.weekends")
    static let recurrenceCustomWeekdays = String(localized: "recurrence.custom")

    static let formHabitNameEmpty = String(localized: "error.habit_name_empty")
    static let errorSaveHabit = String(localized: "error.save_habit")
    static let errorSaveChanges = String(localized: "error.save_changes")
    static let errorRefreshStreaks = String(localized: "error.refresh_streaks")
    static let errorUpdateCompletion = String(localized: "error.update_completion")
    static let errorUpdateHistory = String(localized: "error.update_history")
    static let errorUpdatePlan = String(localized: "error.update_plan")
    static let errorDeleteHabit = String(localized: "error.delete_habit")

    static func selectedDateLabel(_ date: String) -> String {
        String(format: String(localized: "form.selected_date"), date)
    }

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

    static func reminderScheduleFailed(_ title: String) -> String {
        String(format: String(localized: "reminder.schedule_failed"), title)
    }

    static func detailStartsOn(_ date: String) -> String {
        String(format: String(localized: "detail.starts_on"), date)
    }

    static func detailRepeats(_ value: String) -> String {
        String(format: String(localized: "detail.repeats"), value)
    }

    static func detailReminder(_ time: String) -> String {
        String(format: String(localized: "detail.reminder"), time)
    }

    static func detailHabitStartsOn(_ date: String) -> String {
        String(format: String(localized: "detail.habit_starts_on"), date)
    }

    static func dayCount(_ count: Int) -> String {
        String(format: String(localized: "time.days"), count)
    }

    static func statDays(_ count: Int) -> String {
        String(format: String(localized: "stat.days_value"), count)
    }

    static func widgetDoneSummary(_ completed: Int, _ total: Int) -> String {
        String(format: String(localized: "widget.done_summary"), completed, total)
    }

    static func widgetStreak(_ streak: Int) -> String {
        String(format: String(localized: "widget.streak"), streak)
    }

    static func detailStatusStartsOn(_ date: String) -> String {
        String(format: String(localized: "detail.status.starts_on"), date)
    }
}
