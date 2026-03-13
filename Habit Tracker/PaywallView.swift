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

    private var hasProductIssue: Bool {
        productLoadMessage != nil || !isPurchaseAvailable
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Premium")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("The free version supports up to 3 habits. Upgrade to track as many habits as you want.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow("Unlimited habits")
                    featureRow("Smart reminders")
                    featureRow("Habit statistics")
                    featureRow("All future premium updates")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                if isLoadingProduct {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading premium options…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if hasProductIssue {
                    VStack(spacing: 6) {
                        Text("Premium temporarily unavailable.")
                            .font(.footnote.weight(.semibold))
                            .multilineTextAlignment(.center)
                        Text("Check StoreKit test configuration in local testing.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button("Try Again", action: onRetryLoad)
                        .buttonStyle(.bordered)
                }

                if isLoadingProduct {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text("Loading purchase options…")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                } else if isPurchaseAvailable {
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
                } else {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Text("Premium Unavailable")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }

                Button("Try Again", action: onRetryLoad)
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private func featureRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark")
            .font(.subheadline.weight(.medium))
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
