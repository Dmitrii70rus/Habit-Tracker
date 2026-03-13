import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let displayPrice: String
    let isProcessing: Bool
    let isLoadingProduct: Bool
    let isPurchaseAvailable: Bool
    let productLoadMessage: String?
    let onPurchase: () -> Void
    let onRestore: () -> Void
    let onRetryLoad: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Unlock Unlimited Habits")
                    .font(.title2.weight(.bold))

                Text("Free version allows up to 3 habits. Upgrade to track unlimited habits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    benefitRow("Unlimited habits")
                    benefitRow("Reminders")
                    benefitRow("Statistics")
                    benefitRow("Future features")
                }
                .padding(.vertical, 4)

                if isLoadingProduct {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading premium price…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if let productLoadMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(productLoadMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Try Again", action: onRetryLoad)
                            .font(.footnote.weight(.semibold))
                    }
                }

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
                .disabled(isProcessing || isLoadingProduct || !isPurchaseAvailable)

                Button("Restore Purchase", action: onRestore)
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)

                Button("Not now") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.footnote)
                .frame(maxWidth: .infinity)
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
    PaywallView(
        displayPrice: "$4.99",
        isProcessing: false,
        isLoadingProduct: false,
        isPurchaseAvailable: true,
        productLoadMessage: nil,
        onPurchase: {},
        onRestore: {},
        onRetryLoad: {}
    )
}
