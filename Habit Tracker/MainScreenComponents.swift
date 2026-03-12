import SwiftUI

struct MainDateStripView: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let habits: [Habit]

    private let calendar = Calendar.current

    var body: some View {
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
                        onTap: {
                            selectedDate = calendar.startOfDay(for: date)
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct MainDateCellView: View {
    let date: Date
    let isSelected: Bool
    let hasCompleted: Bool
    let hasPlanned: Bool
    let isFuture: Bool
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
                    .foregroundStyle(.secondary)

                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(iconColor)

                Text(dayNumber)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(width: 46)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 1)
                }
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
    private var titleText: String { isFutureDate ? "\(plannedCount) planned" : "\(completedCount) of \(totalCount) completed" }

    private var motivationalText: String {
        if isFutureDate {
            return plannedCount == 0 ? "Plan one small win ahead." : "Nice planning. Stay consistent."
        }

        return completedCount == totalCount ? "Great job. Keep your streak alive." : "Small steps every day."
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

            Text("No Habits Yet")
                .font(.title3.weight(.semibold))

            Text("Create your first habit to start building consistency.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddHabit) {
                Label("Create Your First Habit", systemImage: "plus")
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
            Text("This week")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(completed) / \(scheduled) habits completed")
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
