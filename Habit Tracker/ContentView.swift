import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Habit.createdAt, order: .forward)]) private var habits: [Habit]
    @StateObject private var viewModel = HabitListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "checklist",
                        description: Text("Create your first habit to start building consistency.")
                    )
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitRowView(habit: habit) {
                                viewModel.markHabitDone(habit, in: modelContext)
                            }
                        }
                        .onDelete { offsets in
                            viewModel.deleteHabits(at: offsets, from: habits, in: modelContext)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Habit Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.openAddHabitSheet()
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            AddHabitView(
                viewModel: viewModel,
                onSave: { viewModel.saveHabit(in: modelContext) },
                onCancel: { viewModel.closeAddHabitSheet() }
            )
            .presentationDetents([.medium])
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { show in
                if !show {
                    viewModel.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
