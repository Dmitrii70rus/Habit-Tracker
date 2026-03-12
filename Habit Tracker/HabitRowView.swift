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
                    Text("Current streak: \(dayText(for: habit.currentStreak))")
                    Text("Best streak: \(dayText(for: habit.bestStreak))")
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
                return habit.isPlanned(on: selectedDate) ? "Planned for this day" : "No plan for this day"
            }
            return habit.isPlanned(on: selectedDate) ? "Planned by recurrence" : "Not scheduled"
        }

        return habit.isCompleted(on: selectedDate) ? "Completed" : "Not completed"
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
            return "Planned automatically by recurrence"
        }

        if isFutureDate {
            return habit.isPlanned(on: selectedDate) ? "Remove planned day" : "Mark as planned"
        }

        return habit.isCompleted(on: selectedDate) ? "Unmark complete" : "Mark as complete"
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
        value == 1 ? "1 day" : "\(value) days"
    }
}

#Preview {
    HabitRowView(habit: Habit(title: "Read", recurrenceType: .daily, colorName: "purple"), selectedDate: .now, isActionEnabled: true, onToggleForDate: {})
        .padding()
}
