import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Habit.createdAt, order: .forward)]) private var habits: [Habit]
    @StateObject private var viewModel = HabitListViewModel()
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    private var dateRange: [Date] {
        (-7...7).compactMap { calendar.date(byAdding: .day, value: $0, to: .now) }
    }

    private var isFutureSelection: Bool {
        calendar.compare(selectedDate, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
    }

    private var completedCountForSelectedDate: Int {
        habits.filter { $0.isCompleted(on: selectedDate) }.count
    }

    private var plannedCountForSelectedDate: Int {
        habits.filter { $0.isPlanned(on: selectedDate) }.count
    }

    private var progressRatio: Double {
        guard !habits.isEmpty else { return 0 }
        let current = isFutureSelection ? plannedCountForSelectedDate : completedCountForSelectedDate
        return Double(current) / Double(habits.count)
    }

    private var selectedDateTitle: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: .now), calendar.isDate(selectedDate, inSameDayAs: yesterday) { return "Yesterday" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now), calendar.isDate(selectedDate, inSameDayAs: tomorrow) { return "Tomorrow" }
        return selectedDate.formatted(.dateTime.weekday(.wide).month().day())
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    EmptyHabitStateView { viewModel.openAddHabitSheet(for: selectedDate) }
                } else {
                    List {
                        Section {
                            MainDateStripView(dates: dateRange, selectedDate: $selectedDate, habits: habits)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }

                        Section {
                            ProgressSummaryCardView(
                                selectedDateTitle: selectedDateTitle,
                                completedCount: completedCountForSelectedDate,
                                plannedCount: plannedCountForSelectedDate,
                                totalCount: habits.count,
                                progressRatio: progressRatio,
                                isFutureDate: isFutureSelection
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            ForEach(habits) { habit in
                                NavigationLink {
                                    HabitDetailView(habit: habit, viewModel: viewModel, initialSelectedDate: selectedDate)
                                } label: {
                                    HabitRowView(habit: habit, selectedDate: selectedDate) {
                                        if isFutureSelection {
                                            viewModel.setPlanned(for: habit, on: selectedDate, isPlanned: !habit.isPlanned(on: selectedDate), in: modelContext)
                                        } else {
                                            viewModel.setCompletion(for: habit, on: selectedDate, isCompleted: !habit.isCompleted(on: selectedDate), in: modelContext)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) { viewModel.requestDeleteHabit(habit) } label: { Label("Delete", systemImage: "trash") }
                                    Button { viewModel.openEditHabitSheet(for: habit) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Habit Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { viewModel.openAddHabitSheet(for: selectedDate) } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            ),
            presenting: viewModel.habitPendingDelete
        ) { _ in
            Button("Delete Habit", role: .destructive) {
                viewModel.confirmDeleteHabit(in: modelContext)
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

    private var weekday: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    private var iconName: String {
        if isFuture {
            return hasPlanned ? "calendar.badge.checkmark" : "calendar"
        }
        return hasCompleted ? "checkmark.circle.fill" : "circle"
    }

    private var iconColor: Color {
        if isFuture {
            return hasPlanned ? .blue : .secondary
        }
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
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            AddHabitView(
                title: "Add Habit",
                saveButtonTitle: "Save",
                habitTitle: $viewModel.draftHabitTitle,
                selectedStartOption: $viewModel.selectedStartOption,
                selectedDateLabel: selectedDate.formatted(.dateTime.weekday(.wide).month().day()),
                isPlanOptionVisible: isFutureSelection,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onSave: { viewModel.saveNewHabit(in: modelContext) },
                onCancel: { viewModel.closeAddHabitSheet() }
            )
            .presentationDetents([.fraction(0.42)])
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            AddHabitView(
                title: "Edit Habit",
                saveButtonTitle: "Update",
                habitTitle: $viewModel.draftHabitTitle,
                selectedStartOption: .constant(.startToday),
                selectedDateLabel: selectedDate.formatted(.dateTime.weekday(.wide).month().day()),
                isPlanOptionVisible: false,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onSave: { viewModel.saveEditedHabit(in: modelContext) },
                onCancel: { viewModel.closeEditHabitSheet() }
            )
            .presentationDetents([.fraction(0.3)])
        }
        .confirmationDialog(
            "Delete habit?",
            isPresented: Binding(
                get: { viewModel.habitPendingDelete != nil },
                set: { if !$0 { viewModel.cancelDeleteHabitRequest() } }
            ),
            presenting: viewModel.habitPendingDelete
        ) { _ in
            Button("Delete Habit", role: .destructive) { viewModel.confirmDeleteHabit(in: modelContext) }
            Button("Cancel", role: .cancel) { viewModel.cancelDeleteHabitRequest() }
        } message: { _ in
            Text("This action cannot be undone.")
        }
        .onAppear {
            viewModel.refreshStreaksIfNeeded(for: habits, in: modelContext)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .buttonStyle(.plain)
    }
}

private struct ProgressSummaryCardView: View {
    let selectedDateTitle: String
    let completedCount: Int
    let plannedCount: Int
    let totalCount: Int
    let progressRatio: Double
    let isFutureDate: Bool

    private var percentageText: String {
        "\(Int(progressRatio * 100))%"
    }

    private var titleText: String {
        isFutureDate ? "\(plannedCount) planned" : "\(completedCount) of \(totalCount) completed"
    }
}

private struct MainDateStripView: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let habits: [Habit]

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    MainDateCellView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasCompleted: habits.contains(where: { $0.isCompleted(on: date) }),
                        hasPlanned: habits.contains(where: { $0.isPlanned(on: date) }),
                        isFuture: calendar.compare(date, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending,
                        onTap: {
                            selectedDate = calendar.startOfDay(for: date)
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }

        return completedCount == totalCount ? "Great job. Keep your streak alive." : "Small steps every day."
    }
}

private struct ProgressSummaryCardView: View {
    let completedCount: Int
    let totalCount: Int
    let progressRatio: Double

    private var percentageText: String {
        "\(Int(progressRatio * 100))%"
    }

    private var motivationalText: String {
        completedCount == totalCount ? "Great job. Keep your streak alive." : "Small steps every day."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(completedCount) of \(totalCount) completed")
                .font(.title3.weight(.semibold))

            ProgressView(value: progressRatio)
                .tint(.green)

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
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            AddHabitView(
                title: "Add Habit",
                saveButtonTitle: "Save",
                habitTitle: $viewModel.draftHabitTitle,
                selectedStartOption: $viewModel.selectedStartOption,
                selectedDateLabel: selectedDate.formatted(.dateTime.weekday(.wide).month().day()),
                isPlanOptionVisible: isFutureSelection,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onSave: { viewModel.saveNewHabit(in: modelContext) },
                onCancel: { viewModel.closeAddHabitSheet() }
            )
            .presentationDetents([.fraction(0.42)])
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            AddHabitView(
                title: "Edit Habit",
                saveButtonTitle: "Update",
                habitTitle: $viewModel.draftHabitTitle,
                selectedStartOption: .constant(.startToday),
                selectedDateLabel: selectedDate.formatted(.dateTime.weekday(.wide).month().day()),
                isPlanOptionVisible: false,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onSave: { viewModel.saveEditedHabit(in: modelContext) },
                onCancel: { viewModel.closeEditHabitSheet() }
            )
            .presentationDetents([.fraction(0.3)])
        }
        .confirmationDialog(
            "Delete habit?",
            isPresented: Binding(get: { viewModel.habitPendingDelete != nil }, set: { if !$0 { viewModel.cancelDeleteHabitRequest() } }),
            presenting: viewModel.habitPendingDelete
        ) { _ in
            Button("Delete Habit", role: .destructive) { viewModel.confirmDeleteHabit(in: modelContext) }
            Button("Cancel", role: .cancel) { viewModel.cancelDeleteHabitRequest() }
        } message: { _ in
            Text("This action cannot be undone.")
        }
        .onAppear { viewModel.refreshStreaksIfNeeded(for: habits, in: modelContext) }
        .alert("Something went wrong", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
