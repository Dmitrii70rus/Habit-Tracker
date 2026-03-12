import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var title: String
    var createdAt: Date
    var iconName: String?
    var colorName: String?
    var completionDates: [Date]
    var currentStreak: Int
    var bestStreak: Int

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        iconName: String? = nil,
        colorName: String? = nil,
        completionDates: [Date] = [],
        currentStreak: Int = 0,
        bestStreak: Int = 0
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.iconName = iconName
        self.colorName = colorName
        self.completionDates = completionDates
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
    }

    var sortedCompletionDates: [Date] {
        completionDates.sorted(by: >)
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    @discardableResult
    func markDoneForToday(calendar: Calendar = .current) -> Bool {
        setCompletion(on: .now, isCompleted: true, calendar: calendar)
    }

    @discardableResult
    func setCompletion(on date: Date, isCompleted: Bool, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let wasCompleted = self.isCompleted(on: day, calendar: calendar)

        guard wasCompleted != isCompleted else {
            return false
        }

        if isCompleted {
            completionDates.append(day)
        } else {
            completionDates.removeAll { calendar.isDate($0, inSameDayAs: day) }
        }

        recalculateStreaks(calendar: calendar)
        return true
    }

    func recalculateStreaks(calendar: Calendar = .current) {
        let uniqueDays = Set(completionDates.map { calendar.startOfDay(for: $0) })
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

        let today = calendar.startOfDay(for: .now)
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
