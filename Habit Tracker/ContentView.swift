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

    private var visibleHabits: [Habit] {
        habits.filter { $0.isActive(on: selectedDate) }
    }

    private var isFutureSelection: Bool {
        calendar.compare(selectedDate, to: calendar.startOfDay(for: .now), toGranularity: .day) == .orderedDescending
    }

    private var completedCountForSelectedDate: Int {
        visibleHabits.filter { $0.isCompleted(on: selectedDate) }.count
    }

    private var plannedCountForSelectedDate: Int {
        visibleHabits.filter { $0.isPlanned(on: selectedDate) }.count
    }

    private var progressRatio: Double {
        guard !visibleHabits.isEmpty else { return 0 }
        let current = isFutureSelection ? plannedCountForSelectedDate : completedCountForSelectedDate
        return Double(current) / Double(visibleHabits.count)
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
                                totalCount: visibleHabits.count,
                                progressRatio: progressRatio,
                                isFutureDate: isFutureSelection
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }

                        if visibleHabits.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    "No Habits for This Date",
                                    systemImage: "calendar.badge.exclamationmark",
                                    description: Text("Habits will appear on or after their start date.")
                                )
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            Section {
                                ForEach(visibleHabits) { habit in
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
