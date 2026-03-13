import Foundation

enum HabitScheduleDayState {
    case completed
    case missed
    case notScheduled
    case planned
}

struct HabitAnalyticsSnapshot {
    let currentStreak: Int
    let bestStreak: Int
    let completionRate: Double
    let totalCompletions: Int
    let scheduledDays: Int
    let completedDays: Int
    let weeklyStates: [HabitScheduleDayState]
    let weeklyDates: [Date]
    let heatmapStates: [HabitScheduleDayState]
    let heatmapDates: [Date]

    var motivationalMessage: String {
        if completionRate >= 0.85 {
            return "Great job — keep the streak alive!"
        }

        if completionRate >= 0.6 {
            return "You're building consistency."
        }

        return "Almost there — one more habit today!"
    }
}

struct HabitAnalyticsCalculator {
    static func snapshot(for habit: Habit, referenceDate: Date = .now, heatmapDays: Int = 63, calendar: Calendar = .current) -> HabitAnalyticsSnapshot {
        let today = calendar.startOfDay(for: referenceDate)
        let startDate = habit.effectiveStartDate(calendar: calendar)
        let scheduleRange = makeDateRange(from: startDate, to: today, calendar: calendar)

        let scheduledDays = scheduleRange.filter { habit.recurrenceMatches(on: $0, calendar: calendar) }.count
        let completedDays = scheduleRange.filter { habit.isCompleted(on: $0, calendar: calendar) }.count
        let completionRate = scheduledDays == 0 ? 0 : Double(completedDays) / Double(scheduledDays)

        let weekDates = weekDates(for: today, calendar: calendar)
        let weekStates = weekDates.map { date in
            state(for: habit, on: date, referenceDate: today, calendar: calendar)
        }

        let heatmapDates = trailingDates(until: today, days: heatmapDays, calendar: calendar)
        let heatmapStates = heatmapDates.map { date in
            heatmapState(for: habit, on: date, calendar: calendar)
        }

        return HabitAnalyticsSnapshot(
            currentStreak: habit.currentStreak,
            bestStreak: habit.bestStreak,
            completionRate: completionRate,
            totalCompletions: habit.completionDates.count,
            scheduledDays: scheduledDays,
            completedDays: completedDays,
            weeklyStates: weekStates,
            weeklyDates: weekDates,
            heatmapStates: heatmapStates,
            heatmapDates: heatmapDates
        )
    }

    static func weeklySummary(for habits: [Habit], referenceDate: Date = .now, calendar: Calendar = .current) -> (completed: Int, scheduled: Int) {
        let today = calendar.startOfDay(for: referenceDate)
        let weekDates = weekDates(for: today, calendar: calendar)

        var completed = 0
        var scheduled = 0

        for habit in habits {
            for date in weekDates where date <= today {
                if habit.recurrenceMatches(on: date, calendar: calendar) {
                    scheduled += 1
                    if habit.isCompleted(on: date, calendar: calendar) {
                        completed += 1
                    }
                }
            }
        }

        return (completed, scheduled)
    }

    private static func state(for habit: Habit, on day: Date, referenceDate: Date, calendar: Calendar) -> HabitScheduleDayState {
        guard habit.recurrenceMatches(on: day, calendar: calendar) else {
            return .notScheduled
        }

        if habit.isCompleted(on: day, calendar: calendar) {
            return .completed
        }

        if day <= referenceDate {
            return .missed
        }

        return .planned
    }

    private static func heatmapState(for habit: Habit, on day: Date, calendar: Calendar) -> HabitScheduleDayState {
        if habit.isCompleted(on: day, calendar: calendar) {
            return .completed
        }

        if habit.recurrenceMatches(on: day, calendar: calendar) {
            return .planned
        }

        return .notScheduled
    }

    private static func weekDates(for date: Date, calendar: Calendar) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let start = calendar.startOfDay(for: weekInterval.start)

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    private static func makeDateRange(from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        let normalizedStart = calendar.startOfDay(for: start)
        let normalizedEnd = calendar.startOfDay(for: end)
        guard normalizedStart <= normalizedEnd else { return [] }

        let dayCount = calendar.dateComponents([.day], from: normalizedStart, to: normalizedEnd).day ?? 0
        return (0...dayCount).compactMap {
            calendar.date(byAdding: .day, value: $0, to: normalizedStart)
        }
    }

    private static func trailingDates(until end: Date, days: Int, calendar: Calendar) -> [Date] {
        let normalizedEnd = calendar.startOfDay(for: end)
        guard days > 0 else { return [] }

        return (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: -(days - 1 - offset), to: normalizedEnd)
        }
    }
}
