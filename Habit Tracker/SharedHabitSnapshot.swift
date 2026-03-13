import Foundation

enum SharedHabitConfig {
    static let appGroupID = "group.ST.HabitTracker"
    static let todaySnapshotKey = "habittracker.shared.todaySnapshot"
}

struct SharedHabitSnapshot: Codable {
    struct HabitItem: Codable {
        let title: String
        let isCompleted: Bool
        let isPlanned: Bool
        let reminderEnabled: Bool
    }

    let generatedAt: Date
    let todayLabel: String
    let totalActiveHabits: Int
    let completedHabits: Int
    let plannedHabits: Int
    let remainingHabits: Int
    let overallCurrentStreak: Int
    let overallBestStreak: Int
    let habits: [HabitItem]

    static let empty = SharedHabitSnapshot(
        generatedAt: .now,
        todayLabel: Date.now.formatted(.dateTime.weekday(.wide).month().day()),
        totalActiveHabits: 0,
        completedHabits: 0,
        plannedHabits: 0,
        remainingHabits: 0,
        overallCurrentStreak: 0,
        overallBestStreak: 0,
        habits: []
    )
}

enum SharedHabitSnapshotBuilder {
    static func build(from habits: [Habit], referenceDate: Date = .now, calendar: Calendar = .current) -> SharedHabitSnapshot {
        let today = calendar.startOfDay(for: referenceDate)
        let activeHabits = habits.filter { $0.isActive(on: today, calendar: calendar) }

        let completed = activeHabits.filter { $0.isCompleted(on: today, calendar: calendar) }
        let planned = activeHabits.filter { $0.isPlanned(on: today, calendar: calendar) }
        let remaining = max(0, activeHabits.count - completed.count)

        let overallCurrentStreak = activeHabits.map(\.currentStreak).max() ?? 0
        let overallBestStreak = activeHabits.map(\.bestStreak).max() ?? 0

        let items = activeHabits.prefix(5).map { habit in
            SharedHabitSnapshot.HabitItem(
                title: habit.title,
                isCompleted: habit.isCompleted(on: today, calendar: calendar),
                isPlanned: habit.isPlanned(on: today, calendar: calendar),
                reminderEnabled: habit.isReminderEnabled
            )
        }

        return SharedHabitSnapshot(
            generatedAt: .now,
            todayLabel: today.formatted(.dateTime.weekday(.wide).month().day()),
            totalActiveHabits: activeHabits.count,
            completedHabits: completed.count,
            plannedHabits: planned.count,
            remainingHabits: remaining,
            overallCurrentStreak: overallCurrentStreak,
            overallBestStreak: overallBestStreak,
            habits: items
        )
    }

    static func save(_ snapshot: SharedHabitSnapshot) {
        guard let defaults = UserDefaults(suiteName: SharedHabitConfig.appGroupID),
              let encoded = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(encoded, forKey: SharedHabitConfig.todaySnapshotKey)
    }

    static func load() -> SharedHabitSnapshot {
        guard let defaults = UserDefaults(suiteName: SharedHabitConfig.appGroupID),
              let data = defaults.data(forKey: SharedHabitConfig.todaySnapshotKey),
              let snapshot = try? JSONDecoder().decode(SharedHabitSnapshot.self, from: data) else {
            return .empty
        }

        return snapshot
    }
}
