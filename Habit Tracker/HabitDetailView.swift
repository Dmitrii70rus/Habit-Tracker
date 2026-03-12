import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    @ObservedObject var viewModel: HabitListViewModel

    private let calendar = Calendar.current

    private var recentDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: .now) }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(habit.title)
                        .font(.title2.weight(.semibold))

                    Label(habit.isCompleted(on: .now) ? "Completed today" : "Not completed today", systemImage: habit.isCompleted(on: .now) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(habit.isCompleted(on: .now) ? .green : .secondary)
                        .font(.subheadline)

                    HStack(spacing: 18) {
                        Label("Current streak: \(dayText(habit.currentStreak))", systemImage: "flame")
                        Label("Best streak: \(dayText(habit.bestStreak))", systemImage: "trophy")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Recent History") {
                if habit.completionDates.isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Complete this habit to start building a streak.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    HabitHistoryStripView(
                        recentDays: recentDays,
                        habit: habit,
                        onToggle: { day in
                            let newValue = !habit.isCompleted(on: day)
                            viewModel.setCompletion(for: habit, on: day, isCompleted: newValue, in: modelContext)
                        }
                    )
                    .padding(.vertical, 4)
                }
            } footer: {
                Text("Tap a day to toggle completion for the last 7 days.")
            }
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    viewModel.openEditHabitSheet(for: habit)
                }

                Button(role: .destructive) {
                    viewModel.requestDeleteHabit(habit)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            AddHabitView(
                title: "Edit Habit",
                saveButtonTitle: "Update",
                habitTitle: $viewModel.draftHabitTitle,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onSave: { viewModel.saveEditedHabit(in: modelContext) },
                onCancel: { viewModel.closeEditHabitSheet() }
            )
            .presentationDetents([.fraction(0.3)])
        }
        .confirmationDialog(
            "Delete habit?",
            isPresented: Binding(
                get: { viewModel.habitPendingDelete?.id == habit.id },
                set: { presented in
                    if !presented {
                        viewModel.cancelDeleteHabitRequest()
                    }
                }
            )
        ) {
            Button("Delete Habit", role: .destructive) {
                viewModel.confirmDeleteHabit(in: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeleteHabitRequest()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func dayText(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }
}

private struct HabitHistoryStripView: View {
    let recentDays: [Date]
    let habit: Habit
    let onToggle: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 10) {
            ForEach(recentDays, id: \.self) { day in
                HistoryDayCellView(
                    date: day,
                    isCompleted: habit.isCompleted(on: day),
                    isToday: calendar.isDateInToday(day),
                    onTap: { onToggle(day) }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HistoryDayCellView: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    let onTap: () -> Void

    private var weekday: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(weekday)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .secondary)

                Text(dayNumber)
                    .font(.caption)
                    .foregroundStyle(isToday ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isToday ? Color(.tertiarySystemFill) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(title: "Read"), viewModel: HabitListViewModel())
            .modelContainer(for: Habit.self, inMemory: true)
    }
}
