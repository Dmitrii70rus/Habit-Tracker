import Foundation
import SwiftData

enum HabitRecurrence: String, Codable, CaseIterable, Identifiable {
    case none
    case daily
    case weekdays
    case weekends
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return L10n.recurrenceOneTime
        case .daily:
            return L10n.recurrenceEveryDay
        case .weekdays:
            return L10n.recurrenceWeekdays
        case .weekends:
            return L10n.recurrenceWeekends
        case .custom:
            return L10n.recurrenceCustomWeekdays
        }
    }
}

@Model
final class Habit {
    enum DayStatus {
        case notActive
        case completed
        case planned
        case missed
        case none
    }

    var id: UUID
    var title: String
    var createdAt: Date
    var startDate: Date?
    var recurrenceRawValue: String?
    var selectedWeekdays: [Int]?
    var reminderEnabled: Bool?
    var reminderTime: Date?
    var iconName: String?
    var colorName: String?
    var completionDates: [Date]
    var plannedDates: [Date]?
    var currentStreak: Int
    var bestStreak: Int

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        startDate: Date? = nil,
        recurrenceType: HabitRecurrence = .none,
        selectedWeekdays: [Int] = [],
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        iconName: String? = nil,
        colorName: String? = nil,
        completionDates: [Date] = [],
        plannedDates: [Date] = [],
        currentStreak: Int = 0,
        bestStreak: Int = 0
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.startDate = startDate
        self.recurrenceRawValue = recurrenceType.rawValue
        self.selectedWeekdays = selectedWeekdays
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.iconName = iconName
        self.colorName = colorName
        self.completionDates = completionDates
        self.plannedDates = plannedDates
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
    }

    var recurrenceType: HabitRecurrence {
        get { HabitRecurrence(rawValue: recurrenceRawValue ?? "") ?? .none }
        set { recurrenceRawValue = newValue.rawValue }
    }

    var normalizedSelectedWeekdays: [Int] {
        Array(Set(selectedWeekdays ?? [])).sorted()
    }

    var isReminderEnabled: Bool {
        reminderEnabled ?? false
    }

    var hasAnyPlannedDates: Bool {
        !(plannedDates ?? []).isEmpty
    }

    func effectiveStartDate(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: startDate ?? createdAt)
    }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: date) >= effectiveStartDate(calendar: calendar)
    }

    func recurrenceMatches(on date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)

        guard isActive(on: day, calendar: calendar) else {
            return false
        }

        let weekday = calendar.component(.weekday, from: day)

        switch recurrenceType {
        case .none:
            return calendar.isDate(day, inSameDayAs: effectiveStartDate(calendar: calendar))
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(weekday)
        case .weekends:
            return weekday == 1 || weekday == 7
        case .custom:
            return normalizedSelectedWeekdays.contains(weekday)
        }
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    func isPlanned(on date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)

        if recurrenceMatches(on: day, calendar: calendar) {
            return true
        }

        return (plannedDates ?? []).contains { calendar.isDate($0, inSameDayAs: day) }
    }

    @discardableResult
    func markDoneForToday(calendar: Calendar = .current) -> Bool {
        setCompletion(on: .now, isCompleted: true, calendar: calendar)
    }

    func dayStatus(on date: Date, calendar: Calendar = .current) -> DayStatus {
        let day = calendar.startOfDay(for: date)

        guard isActive(on: day, calendar: calendar) else {
            return .notActive
        }

        if isCompleted(on: day, calendar: calendar) {
            return .completed
        }

        let isFutureDay = calendar.compare(day, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
        if isFutureDay {
            return isPlanned(on: day, calendar: calendar) ? .planned : .none
        }

        return recurrenceMatches(on: day, calendar: calendar) ? .missed : .none
    }

    @discardableResult
    func setCompletion(on date: Date, isCompleted: Bool, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)

        guard isActive(on: day, calendar: calendar) else {
            return false
        }

        let wasCompleted = self.isCompleted(on: day, calendar: calendar)
        guard wasCompleted != isCompleted else {
            return false
        }

        if isCompleted {
            completionDates.append(day)
            plannedDates?.removeAll { calendar.isDate($0, inSameDayAs: day) }
        } else {
            completionDates.removeAll { calendar.isDate($0, inSameDayAs: day) }
        }

        recalculateStreaks(calendar: calendar)
        return true
    }

    @discardableResult
    func setPlanned(on date: Date, isPlanned: Bool, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)

        guard isActive(on: day, calendar: calendar),
              calendar.compare(day, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending else {
            return false
        }

        let wasPlannedManually = (plannedDates ?? []).contains { calendar.isDate($0, inSameDayAs: day) }

        guard wasPlannedManually != isPlanned else {
            return false
        }

        var updatedPlans = plannedDates ?? []
        if isPlanned {
            updatedPlans.append(day)
        } else {
            updatedPlans.removeAll { calendar.isDate($0, inSameDayAs: day) }
        }

        plannedDates = updatedPlans
        return true
    }

    func recalculateStreaks(calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: .now)
        let activeFrom = effectiveStartDate(calendar: calendar)

        let uniqueDays = Set(completionDates.map { calendar.startOfDay(for: $0) })
            .filter { $0 <= today && $0 >= activeFrom }
        let orderedDays = uniqueDays.sorted(by: >)

        guard let latestDay = orderedDays.first else {
            currentStreak = 0
            bestStreak = 0
            return
        }

        var runningBest = 1
        var runningCurrent = 1

        for index in 1..<orderedDays.count {
            let newerDay = orderedDays[index - 1]
            let olderDay = orderedDays[index]

            if let expectedOlder = calendar.date(byAdding: .day, value: -1, to: newerDay),
               calendar.isDate(olderDay, inSameDayAs: expectedOlder) {
                runningCurrent += 1
            } else {
                runningCurrent = 1
            }

            runningBest = max(runningBest, runningCurrent)
        }

        if calendar.isDate(latestDay, inSameDayAs: today) {
            currentStreak = 1
            var cursor = latestDay

            while let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor),
                  uniqueDays.contains(previousDay) {
                currentStreak += 1
                cursor = previousDay
            }
        } else {
            currentStreak = 0
        }

        bestStreak = runningBest
    }
}
