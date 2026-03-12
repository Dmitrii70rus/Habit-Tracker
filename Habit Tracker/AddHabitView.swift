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
    let selectedDateLabel: String
    let isPlanOptionVisible: Bool
    let isSaveEnabled: Bool
    let onSave: () -> Void
    let onCancel: () -> Void


    private var visibleOptions: [StartOption] {
        isPlanOptionVisible ? StartOption.allCases : [.startToday]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Give your habit a clear and short name.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("e.g. Drink Water", text: $habitTitle)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if isPlanOptionVisible {
                    Picker("Start", selection: $selectedStartOption) {
                        ForEach(visibleOptions) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Selected date: \(selectedDateLabel)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
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
}

#Preview {
    AddHabitView(
        title: "New Habit",
        saveButtonTitle: "Save",
        habitTitle: .constant(""),
        selectedStartOption: .constant(.startToday),
        selectedDateLabel: "Tomorrow",
        isPlanOptionVisible: true,
        isSaveEnabled: false,
        onSave: {},
        onCancel: {}
    )
}
