import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published var isShowingAddSheet = false
    @Published var isShowingEditSheet = false
    @Published var draftHabitTitle = ""
    @Published var selectedStartOption: AddHabitView.StartOption = .startToday
    @Published var selectedDateForNewHabit = Calendar.current.startOfDay(for: .now)
    @Published var draftStartDate = Calendar.current.startOfDay(for: .now)
    @Published var draftRecurrenceType: HabitRecurrence = .none
    @Published var draftCustomWeekdays: Set<Int> = []
    @Published var draftReminderEnabled = false
    @Published var draftReminderTime = Date()
    @Published var editingHabit: Habit?
    @Published var habitPendingDelete: Habit?
    @Published var errorMessage: String?

    var isDraftTitleValid: Bool {
        !draftHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func openAddHabitSheet(for selectedDate: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        draftHabitTitle = ""
        selectedDateForNewHabit = normalizedDate
        selectedStartOption = isFutureDate(normalizedDate) ? .planForSelectedDate : .startToday
        draftStartDate = isFutureDate(normalizedDate) ? normalizedDate : Calendar.current.startOfDay(for: .now)
        draftRecurrenceType = .none
        draftCustomWeekdays = []
        draftReminderEnabled = false
        draftReminderTime = defaultReminderTime()
        editingHabit = nil
        errorMessage = nil
        isShowingAddSheet = true
    }

    func closeAddHabitSheet() {
        isShowingAddSheet = false
    }

    func openEditHabitSheet(for habit: Habit) {
        draftHabitTitle = habit.title
        selectedDateForNewHabit = Calendar.current.startOfDay(for: .now)
        selectedStartOption = .startToday
        draftStartDate = habit.effectiveStartDate()
        draftRecurrenceType = habit.recurrenceType
        draftCustomWeekdays = Set(habit.normalizedSelectedWeekdays)
        draftReminderEnabled = habit.isReminderEnabled
        draftReminderTime = habit.reminderTime ?? defaultReminderTime()
        editingHabit = habit
        errorMessage = nil
        isShowingEditSheet = true
    }

    func closeEditHabitSheet() {
        isShowingEditSheet = false
        editingHabit = nil
    }

    func saveNewHabit(in context: ModelContext) {
        let trimmedTitle = draftHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = L10n.formHabitNameEmpty
            return
        }

        let normalizedStartDate = resolvedStartDateForNewHabit()
        let recurrence = resolvedRecurrenceType()
        let customDays = recurrence == .custom ? Array(draftCustomWeekdays).sorted() : []

        let accentOptions = ["mint", "blue", "purple", "orange", "pink", "teal"]
        let accent = accentOptions[Int.random(in: 0..<accentOptions.count)]
        let habit = Habit(
            title: trimmedTitle,
            startDate: normalizedStartDate,
            recurrenceType: recurrence,
            selectedWeekdays: customDays,
            reminderEnabled: draftReminderEnabled,
            reminderTime: draftReminderEnabled ? draftReminderTime : nil,
            colorName: accent
        )

        context.insert(habit)

        persistChanges(in: context, errorText: L10n.errorSaveHabit) {
            self.closeAddHabitSheet()
        }
    }

    func saveEditedHabit(in context: ModelContext) {
        guard let editingHabit else {
            return
        }

        let trimmedTitle = draftHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = L10n.formHabitNameEmpty
            return
        }

        let recurrence = resolvedRecurrenceType()

        editingHabit.title = trimmedTitle
        editingHabit.startDate = Calendar.current.startOfDay(for: draftStartDate)
        editingHabit.recurrenceType = recurrence
        editingHabit.selectedWeekdays = recurrence == .custom ? Array(draftCustomWeekdays).sorted() : []
        editingHabit.reminderEnabled = draftReminderEnabled
        editingHabit.reminderTime = draftReminderEnabled ? draftReminderTime : nil
        persistChanges(in: context, errorText: L10n.errorSaveChanges) {
            self.closeEditHabitSheet()
        }
    }

    func refreshStreaksIfNeeded(for habits: [Habit], in context: ModelContext) {
        var needsSave = false

        for habit in habits {
            let oldCurrent = habit.currentStreak
            let oldBest = habit.bestStreak
            habit.recalculateStreaks()

            if oldCurrent != habit.currentStreak || oldBest != habit.bestStreak {
                needsSave = true
            }
        }

        if needsSave {
            persistChanges(in: context, errorText: L10n.errorRefreshStreaks)
        }
    }

    func markHabitDone(_ habit: Habit, in context: ModelContext) {
        let didCompleteToday = habit.markDoneForToday()

        guard didCompleteToday else {
            return
        }

        persistChanges(in: context, errorText: L10n.errorUpdateCompletion)
    }

    func setCompletion(for habit: Habit, on day: Date, isCompleted: Bool, in context: ModelContext) {
        let changed = habit.setCompletion(on: day, isCompleted: isCompleted)
        guard changed else { return }
        persistChanges(in: context, errorText: L10n.errorUpdateHistory)
    }

    func setPlanned(for habit: Habit, on day: Date, isPlanned: Bool, in context: ModelContext) {
        let changed = habit.setPlanned(on: day, isPlanned: isPlanned)
        guard changed else { return }
        persistChanges(in: context, errorText: L10n.errorUpdatePlan)
    }

    func requestDeleteHabit(_ habit: Habit) {
        DispatchQueue.main.async {
            self.habitPendingDelete = habit
        }
    }

    func confirmDeleteHabit(in context: ModelContext) {
        guard let habitPendingDelete else {
            return
        }

        context.delete(habitPendingDelete)
        DispatchQueue.main.async {
            self.habitPendingDelete = nil
        }

        persistChanges(in: context, errorText: L10n.errorDeleteHabit)
    }

    func cancelDeleteHabitRequest() {
        DispatchQueue.main.async {
            self.habitPendingDelete = nil
        }
    }

    private func resolvedStartDateForNewHabit() -> Date {
        let today = Calendar.current.startOfDay(for: .now)

        if selectedStartOption == .planForSelectedDate,
           isFutureDate(selectedDateForNewHabit) {
            return selectedDateForNewHabit
        }

        return Calendar.current.startOfDay(for: max(draftStartDate, today))
    }

    private func resolvedRecurrenceType() -> HabitRecurrence {
        if draftRecurrenceType == .custom, draftCustomWeekdays.isEmpty {
            return .none
        }

        return draftRecurrenceType
    }

    private func isFutureDate(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Calendar.current.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
    }

    private func defaultReminderTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: calendar.date(from: components) ?? now) ?? now
    }

    private func persistChanges(in context: ModelContext, errorText: String, completion: (() -> Void)? = nil) {
        do {
            try context.save()
            NotificationCenter.default.post(name: .habitDataDidChange, object: nil)
            completion?()
        } catch {
            errorMessage = errorText
        }
    }
}
