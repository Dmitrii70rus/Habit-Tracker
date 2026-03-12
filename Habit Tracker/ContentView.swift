import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Habit.createdAt, order: .forward)]) private var habits: [Habit]
    @StateObject private var viewModel = HabitListViewModel()

    private var completedTodayCount: Int {
        habits.filter { $0.isCompleted(on: .now) }.count
    }

    private var progressRatio: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(habits.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    EmptyHabitStateView {
                        viewModel.openAddHabitSheet()
                    }
                } else {
                    List {
                        Section {
                            ProgressSummaryCardView(
                                completedCount: completedTodayCount,
                                totalCount: habits.count,
                                progressRatio: progressRatio
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            ForEach(habits) { habit in
                                NavigationLink {
                                    HabitDetailView(habit: habit, viewModel: viewModel)
                                } label: {
                                    HabitRowView(habit: habit) {
                                        viewModel.markHabitDone(habit, in: modelContext)
                                    }
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.requestDeleteHabit(habit)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.openEditHabitSheet(for: habit)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
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
                title: "Add Habit",
                saveButtonTitle: "Save",
                habitTitle: $viewModel.draftHabitTitle,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onSave: { viewModel.saveNewHabit(in: modelContext) },
                onCancel: { viewModel.closeAddHabitSheet() }
            )
            .presentationDetents([.fraction(0.3)])
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
                get: { viewModel.habitPendingDelete != nil },
                set: { presented in
                    if !presented {
                        viewModel.cancelDeleteHabitRequest()
                    }
                }
            ),
            presenting: viewModel.habitPendingDelete
        ) { _ in
            Button("Delete Habit", role: .destructive) {
                viewModel.confirmDeleteHabit(in: modelContext)
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeleteHabitRequest()
            }
        } message: { _ in
            Text("This action cannot be undone.")
        }
        .onAppear {
            viewModel.refreshStreaksIfNeeded(for: habits, in: modelContext)
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

private struct EmptyHabitStateView: View {
    let onAddHabit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            Text("No Habits Yet")
                .font(.title3.weight(.semibold))

            Text("Create your first habit to start building consistency.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAddHabit) {
                Label("Create Your First Habit", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
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
