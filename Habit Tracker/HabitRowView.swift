import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let selectedDate: Date
    let isActionEnabled: Bool
    let onToggleForDate: () -> Void

    private let calendar = Calendar.current

    private var isFutureDate: Bool {
        calendar.compare(selectedDate, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(accentColor.gradient)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.headline)

                HStack(spacing: 12) {
                    Text(L10n.streakCurrent(habit.currentStreak))
                    Text(L10n.streakBest(habit.bestStreak))
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }

            Spacer(minLength: 8)

            Button(action: onToggleForDate) {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!isActionEnabled)
            .accessibilityLabel(actionLabel)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var statusText: String {
        if isFutureDate {
            if habit.recurrenceType == .none {
                return habit.isPlanned(on: selectedDate) ? L10n.rowPlannedForDay : L10n.rowNoPlanForDay
            }
            return habit.isPlanned(on: selectedDate) ? L10n.rowPlannedByRecurrence : L10n.rowNotScheduled
        }

        return habit.isCompleted(on: selectedDate) ? L10n.statusCompleted : L10n.statusNotCompleted
    }

    private var statusIcon: String {
        if isFutureDate {
            if habit.recurrenceType == .none {
                return habit.isPlanned(on: selectedDate) ? "calendar.badge.checkmark" : "calendar.badge.plus"
            }
            return habit.isPlanned(on: selectedDate) ? "calendar.badge.checkmark" : "calendar.badge.exclamationmark"
        }

        return habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle"
    }

    private var statusColor: Color {
        if isFutureDate {
            if habit.recurrenceType == .none {
                return habit.isPlanned(on: selectedDate) ? .blue : .secondary
            }
            return habit.isPlanned(on: selectedDate) ? .blue : .orange
        }

        return habit.isCompleted(on: selectedDate) ? .green : .secondary
    }

    private var actionLabel: String {
        if !isActionEnabled {
            return L10n.rowPlannedAutomatically
        }

        if isFutureDate {
            return habit.isPlanned(on: selectedDate) ? L10n.rowRemovePlannedDay : L10n.actionMarkPlanned
        }

        return habit.isCompleted(on: selectedDate) ? L10n.actionUnmarkComplete : L10n.actionMarkComplete
    }

    private var accentColor: Color {
        switch habit.colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "teal": return .teal
        default: return .mint
        }
    }

    private func dayText(for value: Int) -> String {
        L10n.dayCount(value)
    }
}

#Preview {
    HabitRowView(habit: Habit(title: "Read", recurrenceType: .daily, colorName: "purple"), selectedDate: .now, isActionEnabled: true, onToggleForDate: {})
        .padding()
}
