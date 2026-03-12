import SwiftUI

struct AddHabitView: View {
    @ObservedObject var viewModel: HabitListViewModel
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("e.g. Drink Water", text: $viewModel.newHabitTitle)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
    }
}

#Preview {
    AddHabitView(
        viewModel: HabitListViewModel(),
        onSave: {},
        onCancel: {}
    )
}
