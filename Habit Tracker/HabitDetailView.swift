import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    @ObservedObject var viewModel: HabitListViewModel

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    private var dateRange: [Date] {
        (-7...7).compactMap { calendar.date(byAdding: .day, value: $0, to: .now) }
    }

    private var isFutureSelection: Bool {
        calendar.compare(selectedDate, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
    }

    private var selectedStatus: Habit.DayStatus {
        habit.dayStatus(on: selectedDate)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(habit.title)
                        .font(.title2.weight(.semibold))

                    HStack(spacing: 18) {
                        Label("Current streak: \(dayText(habit.currentStreak))", systemImage: "flame")
                        Label("Best streak: \(dayText(habit.bestStreak))", systemImage: "trophy")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Choose Date") {
                DateStripView(
                    dates: dateRange,
                    selectedDate: $selectedDate,
                    habit: habit
                )
                .padding(.vertical, 4)
            } footer: {
                Text("Review the last 7 days, today, and the next 7 days.")
            }

            Section("Selected Day") {
                HabitDayStatusCard(
                    selectedDate: selectedDate,
                    status: selectedStatus
                )

                if isFutureSelection {
                    Button {
                        let newState = !habit.isPlanned(on: selectedDate)
                        viewModel.setPlanned(for: habit, on: selectedDate, isPlanned: newState, in: modelContext)
                    } label: {
                        Label(habit.isPlanned(on: selectedDate) ? "Remove Plan" : "Mark as Planned", systemImage: habit.isPlanned(on: selectedDate) ? "calendar.badge.minus" : "calendar.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        let newState = !habit.isCompleted(on: selectedDate)
                        viewModel.setCompletion(for: habit, on: selectedDate, isCompleted: newState, in: modelContext)
                    } label: {
                        Label(habit.isCompleted(on: selectedDate) ? "Unmark Complete" : "Mark as Complete", systemImage: habit.isCompleted(on: selectedDate) ? "checkmark.circle" : "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } footer: {
                Text(isFutureSelection ? "Future dates can be planned only. Plans do not increase streaks." : "Past and current dates can be marked complete or not complete.")
            }

            if habit.completionDates.isEmpty && habit.plannedDates.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("No history yet")
                            .font(.headline)
                        Text("Complete this habit to start building a streak.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
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

private struct DateStripView: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let habit: Habit

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    DateCellView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        status: habit.dayStatus(on: date),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        selectedDate = calendar.startOfDay(for: date)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct DateCellView: View {
    let date: Date
    let isSelected: Bool
    let status: Habit.DayStatus
    let isToday: Bool
    let onTap: () -> Void

    private var weekday: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    private var statusIcon: String {
        switch status {
        case .completed: return "checkmark.circle.fill"
        case .planned: return "calendar"
        case .missed: return "xmark.circle"
        case .none: return "circle"
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .planned: return .blue
        case .missed: return .orange
        case .none: return .secondary
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(weekday)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Image(systemName: statusIcon)
                    .font(.headline)
                    .foregroundStyle(statusColor)

                Text(dayNumber)
                    .font(.caption.weight(isToday ? .semibold : .regular))
                    .foregroundStyle(.primary)
            }
            .frame(width: 44)
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

private struct HabitDayStatusCard: View {
    let selectedDate: Date
    let status: Habit.DayStatus

    private var title: String {
        switch status {
        case .completed: return "Completed"
        case .planned: return "Planned"
        case .missed: return "Not completed"
        case .none: return "No plan"
        }
    }

    private var subtitle: String {
        switch status {
        case .completed: return "Great job — this day counts toward your streak."
        case .planned: return "Planned day for future consistency."
        case .missed: return "You can still review and update this day."
        case .none: return "No status set for this day yet."
        }
    }

    private var icon: String {
        switch status {
        case .completed: return "checkmark.seal.fill"
        case .planned: return "calendar.badge.plus"
        case .missed: return "exclamationmark.circle"
        case .none: return "circle.dashed"
        }
    }

    private var color: Color {
        switch status {
        case .completed: return .green
        case .planned: return .blue
        case .missed: return .orange
        case .none: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(title: "Read"), viewModel: HabitListViewModel())
            .modelContainer(for: Habit.self, inMemory: true)
    }
}
