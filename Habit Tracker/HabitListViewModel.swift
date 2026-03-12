import Foundation
import Combine
import SwiftData

@MainActor
final class HabitListViewModel: ObservableObject {
    @Published var isShowingAddSheet = false
    @Published var newHabitTitle = ""
    @Published var errorMessage: String?

    func openAddHabitSheet() {
        newHabitTitle = ""
        errorMessage = nil
        isShowingAddSheet = true
    }

    func closeAddHabitSheet() {
        isShowingAddSheet = false
    }

    func saveHabit(in context: ModelContext) {
        let trimmedTitle = newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Habit name can't be empty."
            return
        }

        let habit = Habit(title: trimmedTitle)
        context.insert(habit)

        do {
            try context.save()
            closeAddHabitSheet()
        } catch {
            errorMessage = "Couldn't save your habit. Please try again."
        }
    }

    func markHabitDone(_ habit: Habit, in context: ModelContext) {
        let didCompleteToday = habit.markDoneForToday()

        guard didCompleteToday else {
            return
        }

        do {
            try context.save()
        } catch {
            errorMessage = "Couldn't update completion. Please try again."
        }
    }

    func deleteHabits(at offsets: IndexSet, from habits: [Habit], in context: ModelContext) {
        for index in offsets {
            context.delete(habits[index])
        }

        do {
            try context.save()
        } catch {
            errorMessage = "Couldn't delete habit. Please try again."
        }
    }
}
