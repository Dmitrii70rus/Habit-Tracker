import SwiftUI

struct MainDateStripView: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let habits: [Habit]

    private let calendar = Calendar.current
    @State private var hasScrolledInitially = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dates, id: \.self) { date in
                        let activeHabitsForDate = habits.filter { $0.isActive(on: date) }
                        MainDateCellView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasCompleted: activeHabitsForDate.contains(where: { $0.isCompleted(on: date) }),
                            hasPlanned: activeHabitsForDate.contains(where: { $0.isPlanned(on: date) }),
                            isFuture: calendar.compare(date, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending,
                            isToday: calendar.isDateInToday(date),
                            onTap: {
                                selectedDate = calendar.startOfDay(for: date)
                            }
                        )
                        .id(calendar.startOfDay(for: date))
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear {
                guard !hasScrolledInitially else { return }
                hasScrolledInitially = true
                scrollToSelected(proxy: proxy, animated: false)
            }
            .onChange(of: selectedDate) { _, _ in
                scrollToSelected(proxy: proxy, animated: true)
            }
        }
    }

    private func scrollToSelected(proxy: ScrollViewProxy, animated: Bool) {
        let action = {
            proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.22)) { action() }
        } else {
            action()
        }
    }
}

private struct MainDateCellView: View {
    let date: Date
    let isSelected: Bool
    let hasCompleted: Bool
    let hasPlanned: Bool
    let isFuture: Bool
    let isToday: Bool
    let onTap: () -> Void

    private var weekday: String { date.formatted(.dateTime.weekday(.narrow)) }
    private var dayNumber: String { date.formatted(.dateTime.day()) }

    private var iconName: String {
        if isFuture { return hasPlanned ? "calendar.badge.checkmark" : "calendar" }
        return hasCompleted ? "checkmark.circle.fill" : "circle"
    }

    private var iconColor: Color {
        if isFuture { return hasPlanned ? .blue : .secondary }
        return hasCompleted ? .green : .secondary
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(weekday)
                    .font(.caption2)
                    .foregroundStyle(isToday ? Color.accentColor : .secondary)

                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(iconColor)

                Text(dayNumber)
                    .font(.caption.weight(isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(.primary)
            }
            .frame(width: 48)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.35) : .clear), lineWidth: isSelected ? 1.3 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ProgressSummaryCardView: View {
    let selectedDateTitle: String
    let completedCount: Int
    let plannedCount: Int
    let totalCount: Int
    let progressRatio: Double
    let isFutureDate: Bool

    private var percentageText: String { "\(Int(progressRatio * 100))%" }
    private var titleText: String { isFutureDate ? L10n.progressPlanned(plannedCount) : L10n.habitsCompleted(completedCount, totalCount) }

    private var motivationalText: String {
        if isFutureDate {
            return plannedCount == 0 ? L10n.motivationFutureNone : L10n.motivationFuturePlanned
        }

        return completedCount == totalCount ? L10n.motivationPerfectDay : L10n.motivationKeepGoing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDateTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(titleText)
                .font(.title3.weight(.semibold))

            ProgressView(value: progressRatio)
                .tint(isFutureDate ? .blue : .green)

            Text("\(percentageText) • \(motivationalText)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct EmptyHabitStateView: View {
    let onAddHabit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            Text(L10n.emptyHabitsTitle)
                .font(.title3.weight(.semibold))

            Text(L10n.emptyHabitsMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddHabit) {
                Label(L10n.emptyHabitsButton, systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct WeeklySummaryCardView: View {
    let completed: Int
    let scheduled: Int

    private var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return Double(completed) / Double(scheduled)
    }

    private var percentText: String {
        "\(Int(ratio * 100))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.summaryThisWeek)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(L10n.habitsCompletedWeek(completed, scheduled))
                .font(.headline)

            ProgressView(value: ratio)
                .tint(.green)

            Text(percentText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct OverallStreakSummaryView: View {
    let currentStreak: Int
    let bestStreak: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.summaryOverallStreak)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(L10n.streakCurrent(currentStreak))
                    .font(.headline)
                Text(L10n.streakBest(bestStreak))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct DailyReminderSummaryView: View {
    let plannedCount: Int
    let completedCount: Int
    let remainingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.summaryDailyReminder)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                summaryPill(title: L10n.summaryPlanned, value: plannedCount, color: .blue)
                summaryPill(title: L10n.summaryDone, value: completedCount, color: .green)
                summaryPill(title: L10n.summaryRemaining, value: remainingCount, color: .orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func summaryPill(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
