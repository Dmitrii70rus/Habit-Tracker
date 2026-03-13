import SwiftUI
import SwiftData
import StoreKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Habit.createdAt, order: .forward)]) private var habits: [Habit]
    @StateObject private var viewModel = HabitListViewModel()
    @StateObject private var reminderManager = ReminderManager()
    @StateObject private var purchaseManager = PurchaseManager()

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isShowingPaywall = false

    private let calendar = Calendar.current
    private let freeHabitLimit = 3

    private var dateRange: [Date] {
        (-7...7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: .now) else { return nil }
            return calendar.startOfDay(for: date)
        }
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

    private var thisWeekSummary: (completed: Int, scheduled: Int) {
        HabitAnalyticsCalculator.weeklySummary(for: habits, calendar: calendar)
    }

    private var weeklyCompletionRatio: Double {
        guard thisWeekSummary.scheduled > 0 else { return 0 }
        return Double(thisWeekSummary.completed) / Double(thisWeekSummary.scheduled)
    }

    private var weeklyMotivationText: String {
        if thisWeekSummary.scheduled == 0 {
            return L10n.analyticsWeekNone
        }

        if weeklyCompletionRatio >= 0.8 {
            return L10n.analyticsGreat
        }

        if weeklyCompletionRatio >= 0.5 {
            return L10n.analyticsConsistent
        }

        return L10n.analyticsAlmost
    }


    private var todaySnapshot: SharedHabitSnapshot {
        SharedHabitSnapshotBuilder.build(from: habits, referenceDate: .now, calendar: calendar)
    }

    private var selectedDateTitle: String {
        if calendar.isDateInToday(selectedDate) { return L10n.today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: .now), calendar.isDate(selectedDate, inSameDayAs: yesterday) { return L10n.yesterday }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now), calendar.isDate(selectedDate, inSameDayAs: tomorrow) { return L10n.tomorrow }
        return selectedDate.formatted(.dateTime.weekday(.wide).month().day())
    }

    private var premiumDisplayPrice: String {
        purchaseManager.premiumProduct?.displayPrice ?? "$4.99"
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    EmptyHabitStateView { handleAddHabitTap() }
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

                        Section {
                            WeeklySummaryCardView(
                                completed: thisWeekSummary.completed,
                                scheduled: thisWeekSummary.scheduled
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)

                            Text(weeklyMotivationText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                                .listRowBackground(Color.clear)
                        }

                        Section {
                            OverallStreakSummaryView(
                                currentStreak: todaySnapshot.overallCurrentStreak,
                                bestStreak: todaySnapshot.overallBestStreak
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            DailyReminderSummaryView(
                                plannedCount: todaySnapshot.plannedHabits,
                                completedCount: todaySnapshot.completedHabits,
                                remainingCount: todaySnapshot.remainingHabits
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }

                        if visibleHabits.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    L10n.emptyNoHabitsForDateTitle,
                                    systemImage: "calendar.badge.exclamationmark",
                                    description: Text(L10n.emptyNoHabitsForDateMessage)
                                )
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            Section {
                                ForEach(visibleHabits) { habit in
                                    NavigationLink {
                                        HabitDetailView(habit: habit, viewModel: viewModel, initialSelectedDate: selectedDate)
                                    } label: {
                                        HabitRowView(
                                            habit: habit,
                                            selectedDate: selectedDate,
                                            isActionEnabled: !isFutureSelection || habit.recurrenceType == .none
                                        ) {
                                            if isFutureSelection {
                                                guard habit.recurrenceType == .none else { return }
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
                                        Button(role: .destructive) { viewModel.requestDeleteHabit(habit) } label: {
                                            Label(L10n.delete, systemImage: "trash")
                                        }

                                        Button { viewModel.openEditHabitSheet(for: habit) } label: {
                                            Label(L10n.editHabit, systemImage: "pencil")
                                        }
                                        .tint(.blue)
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
            .navigationTitle(L10n.appName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { handleAddHabitTap() } label: {
                        Label(L10n.addHabit, systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            AddHabitView(
                title: L10n.addHabitTitle,
                saveButtonTitle: L10n.addHabitSave,
                habitTitle: $viewModel.draftHabitTitle,
                selectedStartOption: $viewModel.selectedStartOption,
                startDate: $viewModel.draftStartDate,
                recurrenceType: $viewModel.draftRecurrenceType,
                customWeekdays: $viewModel.draftCustomWeekdays,
                reminderEnabled: $viewModel.draftReminderEnabled,
                reminderTime: $viewModel.draftReminderTime,
                selectedDateLabel: selectedDate.formatted(.dateTime.weekday(.wide).month().day()),
                isPlanOptionVisible: isFutureSelection,
                isSaveEnabled: viewModel.isDraftTitleValid,
                onReminderToggle: { enabled in
                    guard enabled else { return }
                    Task {
                        _ = await reminderManager.requestPermissionIfNeeded()
                    }
                },
                onSave: { handleSaveNewHabit() },
                onCancel: { viewModel.closeAddHabitSheet() }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            AddHabitView(
                title: L10n.editHabitTitle,
                saveButtonTitle: L10n.editHabitSave,
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
                onReminderToggle: { enabled in
                    guard enabled else { return }
                    Task {
                        _ = await reminderManager.requestPermissionIfNeeded()
                    }
                },
                onSave: { viewModel.saveEditedHabit(in: modelContext) },
                onCancel: { viewModel.closeEditHabitSheet() }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(
                displayPrice: premiumDisplayPrice,
                isProcessing: purchaseManager.isProcessingPurchase,
                isLoadingProduct: purchaseManager.isLoadingProducts,
                isPurchaseAvailable: purchaseManager.isProductReady,
                productLoadMessage: purchaseManager.productLoadMessage,
                onPurchase: {
                    Task {
                        await purchaseManager.purchasePremium()
                        if purchaseManager.isPremiumUnlocked {
                            isShowingPaywall = false
                        }
                    }
                },
                onRestore: {
                    Task {
                        await purchaseManager.restorePurchases()
                        if purchaseManager.isPremiumUnlocked {
                            isShowingPaywall = false
                        }
                    }
                },
                onRetryLoad: {
                    Task {
                        await purchaseManager.loadProducts()
                    }
                }
            )
            .presentationDetents([.large])
            .task {
                await purchaseManager.loadProducts()
            }
        }
        .confirmationDialog(
            L10n.alertDeleteHabitTitle,
            isPresented: Binding(
                get: { viewModel.habitPendingDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.cancelDeleteHabitRequest()
                    }
                }
            ),
            presenting: viewModel.habitPendingDelete
        ) { _ in
            Button(L10n.alertDeleteHabitButton, role: .destructive) {
                viewModel.confirmDeleteHabit(in: modelContext)
            }
            Button(L10n.cancel, role: .cancel) {
                viewModel.cancelDeleteHabitRequest()
            }
        } message: { _ in
            Text(L10n.alertDeleteHabitMessage)
        }
        .task {
            await purchaseManager.prepare()
        }
        .onAppear {
            viewModel.refreshStreaksIfNeeded(for: habits, in: modelContext)
            persistSharedSnapshot()
            Task {
                await reminderManager.scheduleRollingReminders(for: habits)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .habitDataDidChange)) { _ in
            persistSharedSnapshot()
            Task {
                await reminderManager.scheduleRollingReminders(for: habits)
            }
        }
        .alert(L10n.alertGenericErrorTitle, isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button(L10n.ok, role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert(L10n.alertReminderPermissionTitle, isPresented: Binding(get: { reminderManager.permissionDeniedMessage != nil }, set: { if !$0 { reminderManager.clearMessage() } })) {
            Button(L10n.ok, role: .cancel) { reminderManager.clearMessage() }
        } message: {
            Text(reminderManager.permissionDeniedMessage ?? "")
        }
        .alert(L10n.alertPurchaseTitle, isPresented: Binding(get: { purchaseManager.errorMessage != nil }, set: { if !$0 { purchaseManager.clearError() } })) {
            Button(L10n.ok, role: .cancel) { purchaseManager.clearError() }
        } message: {
            Text(purchaseManager.errorMessage ?? "")
        }
    }

    private func persistSharedSnapshot() {
        SharedHabitSnapshotBuilder.save(todaySnapshot)
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
#endif
    }

    private func handleAddHabitTap() {
        if canCreateHabit() {
            viewModel.openAddHabitSheet(for: selectedDate)
        } else {
            purchaseManager.clearProductLoadMessage()
            isShowingPaywall = true
            Task { await purchaseManager.loadProducts() }
        }
    }

    private func handleSaveNewHabit() {
        if canCreateHabit() {
            viewModel.saveNewHabit(in: modelContext)
        } else {
            viewModel.closeAddHabitSheet()
            purchaseManager.clearProductLoadMessage()
            isShowingPaywall = true
            Task { await purchaseManager.loadProducts() }
        }
    }

    private func canCreateHabit() -> Bool {
        purchaseManager.isPremiumUnlocked || habits.count < freeHabitLimit
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
