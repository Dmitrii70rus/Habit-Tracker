import SwiftUI

struct AddHabitView: View {
    let title: String
    let saveButtonTitle: String
    @Binding var habitTitle: String
    let isSaveEnabled: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isTitleFieldFocused: Bool

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
                    .focused($isTitleFieldFocused)
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTitleFieldFocused = true
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
        isSaveEnabled: false,
        onSave: {},
        onCancel: {}
    )
}
