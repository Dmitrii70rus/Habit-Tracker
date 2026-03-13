import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let displayPrice: String
    let isProcessing: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Unlock Unlimited Habits")
                    .font(.title2.weight(.bold))

                Text("Free version allows up to 3 habits. Upgrade to track unlimited habits.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    benefitRow("Unlimited habits")
                    benefitRow("Reminders")
                    benefitRow("Statistics")
                    benefitRow("Future features")
                }
                .padding(.vertical, 4)

                Spacer()

                Button(action: onPurchase) {
                    HStack {
                        Spacer()
                        Text("Unlock Premium (\(displayPrice))")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)

                Button("Restore Purchase", action: onRestore)
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func benefitRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.primary)
    }
}

#Preview {
    PaywallView(displayPrice: "$4.99", isProcessing: false, onPurchase: {}, onRestore: {})
}
