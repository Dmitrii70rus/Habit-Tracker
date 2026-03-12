import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published var isShowingAddSheet = false
    @Published var isShowingEditSheet = false
    @Published var draftHabitTitle = ""
    @Published var editingHabit: Habit?
    @Published var habitPendingDelete: Habit?
    @Published var errorMessage: String?

    var isDraftTitleValid: Bool {
        !draftHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func openAddHabitSheet() {
        draftHabitTitle = ""
        editingHabit = nil
        errorMessage = nil
        isShowingAddSheet = true
    }

    func closeAddHabitSheet() {
        isShowingAddSheet = false
    }

    func openEditHabitSheet(for habit: Habit) {
        draftHabitTitle = habit.title
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
            errorMessage = "Habit name can't be empty."
            return
        }

        let accentOptions = ["mint", "blue", "purple", "orange", "pink", "teal"]
        let accent = accentOptions[Int.random(in: 0..<accentOptions.count)]
        let habit = Habit(title: trimmedTitle, colorName: accent)
        context.insert(habit)

        persistChanges(in: context, errorText: "Couldn't save your habit. Please try again.") {
            self.closeAddHabitSheet()
        }
    }

    func saveEditedHabit(in context: ModelContext) {
        guard let editingHabit else {
            return
        }

        let trimmedTitle = draftHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Habit name can't be empty."
            return
        }

        editingHabit.title = trimmedTitle
        persistChanges(in: context, errorText: "Couldn't save your changes. Please try again.") {
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
            persistChanges(in: context, errorText: "Couldn't refresh streaks. Please try again.")
        }
    }

    func markHabitDone(_ habit: Habit, in context: ModelContext) {
        let didCompleteToday = habit.markDoneForToday()

        guard didCompleteToday else {
            return
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            persistChanges(in: context, errorText: "Couldn't update completion. Please try again.")
        }
    }

    func setCompletion(for habit: Habit, on day: Date, isCompleted: Bool, in context: ModelContext) {
        let changed = habit.setCompletion(on: day, isCompleted: isCompleted)
        guard changed else { return }
        persistChanges(in: context, errorText: "Couldn't update history. Please try again.")
    }

    func requestDeleteHabit(_ habit: Habit) {
        habitPendingDelete = habit
    }

    func confirmDeleteHabit(in context: ModelContext) {
        guard let habitPendingDelete else {
            return
        }

        context.delete(habitPendingDelete)
        self.habitPendingDelete = nil

        persistChanges(in: context, errorText: "Couldn't delete habit. Please try again.")
    }

    func cancelDeleteHabitRequest() {
        habitPendingDelete = nil
    }

    private func persistChanges(in context: ModelContext, errorText: String, completion: (() -> Void)? = nil) {
        do {
            try context.save()
            completion?()
        } catch {
            errorMessage = errorText
        }
    }
}
