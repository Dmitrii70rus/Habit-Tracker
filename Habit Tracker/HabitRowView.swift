import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onMarkDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)

                HStack(spacing: 10) {
                    Label("Current: \(habit.currentStreak)", systemImage: "flame")
                    Label("Best: \(habit.bestStreak)", systemImage: "trophy")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onMarkDone) {
                Image(systemName: habit.isCompleted(on: .now) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(habit.isCompleted(on: .now) ? .green : .secondary)
                    .accessibilityLabel(habit.isCompleted(on: .now) ? "Completed today" : "Mark as done")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    HabitRowView(habit: Habit(title: "Read"), onMarkDone: {})
}
