import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onMarkDone: () -> Void

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
            }

            Spacer(minLength: 8)

            Button(action: onMarkDone) {
                Image(systemName: habit.isCompleted(on: .now) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(habit.isCompleted(on: .now) ? .green : .secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(habit.isCompleted(on: .now) ? "Completed today" : "Mark as done")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
    HabitRowView(habit: Habit(title: "Read", colorName: "purple"), onMarkDone: {})
        .padding()
}
