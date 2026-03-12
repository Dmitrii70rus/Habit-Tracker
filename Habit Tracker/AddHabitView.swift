import SwiftUI

struct AddHabitView: View {
    enum StartOption: String, CaseIterable, Identifiable {
        case startToday
        case planForSelectedDate

        var id: String { rawValue }

        var title: String {
            switch self {
            case .startToday: return "Start Today"
            case .planForSelectedDate: return "Plan for Selected Date"
            }
        }
    }

    let title: String
    let saveButtonTitle: String
    @Binding var habitTitle: String
    @Binding var selectedStartOption: StartOption
    @Binding var startDate: Date
    @Binding var recurrenceType: HabitRecurrence
    @Binding var customWeekdays: Set<Int>
    @Binding var reminderEnabled: Bool
    @Binding var reminderTime: Date
    let selectedDateLabel: String
    let isPlanOptionVisible: Bool
    let isSaveEnabled: Bool
    let onReminderToggle: (Bool) -> Void
    let onSave: () -> Void
    let onCancel: () -> Void

    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private var visibleOptions: [StartOption] {
        isPlanOptionVisible ? StartOption.allCases : [.startToday]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("e.g. Drink Water", text: $habitTitle)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                }

                if isPlanOptionVisible {
                    Section("Quick Start") {
                        Picker("Start", selection: $selectedStartOption) {
                            ForEach(visibleOptions) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Selected date: \(selectedDateLabel)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Recurrence") {
                    Picker("Repeats", selection: $recurrenceType) {
                        ForEach(HabitRecurrence.allCases) { recurrence in
                            Text(recurrence.title).tag(recurrence)
                        }
                    }

                    if recurrenceType == .custom {
                        WeekdayPickerView(selectedWeekdays: $customWeekdays, symbols: weekdaySymbols)
                    }
                }

                Section("Reminders") {
                    Toggle("Enable reminder", isOn: reminderToggleBinding)

                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle, action: onSave)
                        .disabled(!isSaveEnabled)
                }
            }
        }
    }

    private var reminderToggleBinding: Binding<Bool> {
        Binding(
            get: { reminderEnabled },
            set: { newValue in
                reminderEnabled = newValue
                onReminderToggle(newValue)
            }
        )
    }
}

private struct WeekdayPickerView: View {
    @Binding var selectedWeekdays: Set<Int>
    let symbols: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom days")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                    let weekday = index + 1
                    Button {
                        if selectedWeekdays.contains(weekday) {
                            selectedWeekdays.remove(weekday)
                        } else {
                            selectedWeekdays.insert(weekday)
                        }
                    } label: {
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedWeekdays.contains(weekday) ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    AddHabitView(
        title: "New Habit",
        saveButtonTitle: "Save",
        habitTitle: .constant(""),
        selectedStartOption: .constant(.startToday),
        startDate: .constant(.now),
        recurrenceType: .constant(.daily),
        customWeekdays: .constant([2, 4, 6]),
        reminderEnabled: .constant(true),
        reminderTime: .constant(.now),
        selectedDateLabel: "Tomorrow",
        isPlanOptionVisible: true,
        isSaveEnabled: false,
        onReminderToggle: { _ in },
        onSave: {},
        onCancel: {}
    )
}
