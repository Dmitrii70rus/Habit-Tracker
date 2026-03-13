import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    @ObservedObject var viewModel: HabitListViewModel

    @State private var selectedDate: Date
    let initialSelectedDate: Date?

    private let calendar = Calendar.current

    private var dateRange: [Date] {
        (-7...7).compactMap { calendar.date(byAdding: .day, value: $0, to: .now) }
    }

    private var isFutureSelection: Bool {
        calendar.compare(selectedDate, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
    }

    private var isNotActiveSelection: Bool {
        !habit.isActive(on: selectedDate)
    }

    private var selectedStatus: Habit.DayStatus {
        habit.dayStatus(on: selectedDate)
    }

    private var analytics: HabitAnalyticsSnapshot {
        HabitAnalyticsCalculator.snapshot(for: habit, calendar: calendar)
    }

    private var recurrenceDescription: String {
        switch habit.recurrenceType {
        case .none:
            return "One-time"
        case .daily:
            return "Every day"
        case .weekdays:
            return "Weekdays"
        case .weekends:
            return "Weekends"
        case .custom:
            let symbols = calendar.shortWeekdaySymbols
            let labels = habit.normalizedSelectedWeekdays.compactMap { weekday in
                symbols[safe: weekday - 1]
            }
            return labels.isEmpty ? "Custom weekdays" : labels.joined(separator: " ")
        }
    }

    init(habit: Habit, viewModel: HabitListViewModel, initialSelectedDate: Date? = nil) {
        self.habit = habit
        self.viewModel = viewModel
        self.initialSelectedDate = initialSelectedDate
        _selectedDate = State(initialValue: Calendar.current.startOfDay(for: initialSelectedDate ?? .now))
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

                    Text("Starts: \(habit.effectiveStartDate().formatted(.dateTime.weekday(.wide).month().day()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Repeats: \(recurrenceDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if habit.isReminderEnabled, let reminderTime = habit.reminderTime {
                        Text("Reminder: \(reminderTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                DateStripView(
                    dates: dateRange,
                    selectedDate: $selectedDate,
                    habit: habit
                )
                .padding(.vertical, 4)
            } header: {
                Text("Choose Date")
            } footer: {
                Text("Review the last 7 days, today, and the next 7 days.")
            }

            Section {
                HabitDayStatusCard(
                    selectedDate: selectedDate,
                    status: selectedStatus,
                    habitStartDate: habit.effectiveStartDate()
                )

                if isNotActiveSelection {
                    Text("This habit starts on \(habit.effectiveStartDate().formatted(.dateTime.month().day())).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if isFutureSelection {
                    if habit.recurrenceType == .none {
                        Button {
                            let newState = !habit.isPlanned(on: selectedDate)
                            viewModel.setPlanned(for: habit, on: selectedDate, isPlanned: newState, in: modelContext)
                        } label: {
                            Label(habit.isPlanned(on: selectedDate) ? "Remove Plan" : "Mark as Planned", systemImage: habit.isPlanned(on: selectedDate) ? "calendar.badge.minus" : "calendar.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Planned automatically from recurrence.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        let newState = !habit.isCompleted(on: selectedDate)
                        viewModel.setCompletion(for: habit, on: selectedDate, isCompleted: newState, in: modelContext)
                    } label: {
                        Label(habit.isCompleted(on: selectedDate) ? "Unmark Complete" : "Mark as Complete", systemImage: habit.isCompleted(on: selectedDate) ? "checkmark.circle" : "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } header: {
                Text("Selected Day")
            } footer: {
                if isNotActiveSelection {
                    Text("Actions are disabled before the habit start date.")
                } else {
                    Text(isFutureSelection ? "Future planned state comes from the recurrence rule." : "Past and current dates can be marked complete or not complete.")
                }
            }

            Section("Statistics") {
                HabitStatisticsView(analytics: analytics)

                Text(analytics.motivationalMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                WeeklyProgressView(dates: analytics.weeklyDates, states: analytics.weeklyStates)
            } header: {
                Text("Weekly Progress")
            } footer: {
                Text("✓ completed • ✗ missed • — not scheduled")
            }

            Section {
                HabitHeatmapView(states: analytics.heatmapStates)
            } header: {
                Text("Last 9 Weeks")
            } footer: {
                Text("Gray: not scheduled • Blue: planned/not completed • Green: completed")
            }

            if habit.completionDates.isEmpty && !habit.hasAnyPlannedDates {
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
                selectedStartOption: .constant(.startToday),
                startDate: $viewModel.draftStartDate,
                recurrenceType: $viewModel.draftRecurrenceType,
                customWeekdays: $viewModel.draftCustomWeekdays,
                reminderEnabled: $viewModel.draftReminderEnabled,
                reminderTime: $viewModel.draftReminderTime,
                selectedDateLabel: selectedDate.formatted(.dateTime.weekday(.wide).month().day()),
                isPlanOptionVisible: false,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onReminderToggle: { _ in },
                onSave: { viewModel.saveEditedHabit(in: modelContext) },
                onCancel: { viewModel.closeEditHabitSheet() }
            )
            .presentationDetents([.large])
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
        case .notActive: return "slash.circle"
        case .completed: return "checkmark.circle.fill"
        case .planned: return "calendar"
        case .missed: return "xmark.circle"
        case .none: return "circle"
        }
    }

    private var statusColor: Color {
        switch status {
        case .notActive: return .gray
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
    let habitStartDate: Date

    private var title: String {
        switch status {
        case .notActive: return "Not active yet"
        case .completed: return "Completed"
        case .planned: return "Planned"
        case .missed: return "Not completed"
        case .none: return "No plan"
        }
    }

    private var subtitle: String {
        switch status {
        case .notActive: return "This habit starts on \(habitStartDate.formatted(.dateTime.month().day()))."
        case .completed: return "Great job — this day counts toward your streak."
        case .planned: return "Planned day from recurrence."
        case .missed: return "You can still review and update this day."
        case .none: return "No status set for this day yet."
        }
    }

    private var icon: String {
        switch status {
        case .notActive: return "hourglass"
        case .completed: return "checkmark.seal.fill"
        case .planned: return "calendar.badge.plus"
        case .missed: return "exclamationmark.circle"
        case .none: return "circle.dashed"
        }
    }

    private var color: Color {
        switch status {
        case .notActive: return .gray
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


private struct HabitStatisticsView: View {
    let analytics: HabitAnalyticsSnapshot

    private var completionPercentText: String {
        "\(Int(analytics.completionRate * 100))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatisticRow(label: "Current streak", value: "\(analytics.currentStreak) days")
            StatisticRow(label: "Best streak", value: "\(analytics.bestStreak) days")
            StatisticRow(label: "Completion rate", value: completionPercentText)
            StatisticRow(label: "Total completions", value: "\(analytics.totalCompletions)")
            StatisticRow(label: "Scheduled days", value: "\(analytics.scheduledDays)")
        }
    }
}

private struct StatisticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

private struct WeeklyProgressView: View {
    let dates: [Date]
    let states: [HabitScheduleDayState]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(zip(dates.indices, dates)), id: \.0) { index, date in
                VStack(spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(symbol(for: states[index]))
                        .font(.headline)
                        .foregroundStyle(color(for: states[index]))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private func symbol(for state: HabitScheduleDayState) -> String {
        switch state {
        case .completed:
            return "✓"
        case .missed:
            return "✗"
        case .notScheduled:
            return "—"
        case .planned:
            return "•"
        }
    }

    private func color(for state: HabitScheduleDayState) -> Color {
        switch state {
        case .completed:
            return .green
        case .missed:
            return .orange
        case .notScheduled:
            return .secondary
        case .planned:
            return .blue
        }
    }
}

private struct HabitHeatmapView: View {
    let states: [HabitScheduleDayState]

    private let columns = Array(repeating: GridItem(.fixed(10), spacing: 4), count: 9)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(for: state))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }

    private func color(for state: HabitScheduleDayState) -> Color {
        switch state {
        case .notScheduled:
            return Color(.systemGray5)
        case .planned:
            return Color.blue.opacity(0.35)
        case .completed:
            return Color.green.opacity(0.8)
        case .missed:
            return Color.orange.opacity(0.55)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(title: "Read", recurrenceType: .daily), viewModel: HabitListViewModel(), initialSelectedDate: .now)
            .modelContainer(for: Habit.self, inMemory: true)
    }
}
