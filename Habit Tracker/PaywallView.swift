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

    private var unavailableMessage: String {
        "Premium is currently unavailable."
    }

    private var unavailableDetail: String {
        if let productLoadMessage, !productLoadMessage.isEmpty {
            return "Try again in a moment. Check StoreKit test configuration in local testing."
        }

        return "Try again in a moment."
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Unlock Unlimited Habits")
                        .font(.title2.weight(.bold))

                    Text("The free version supports up to 3 habits. Upgrade to track as many habits as you want.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    benefitRow("Unlimited habits")
                    benefitRow("Smart reminders")
                    benefitRow("Habit statistics")
                    benefitRow("All future premium updates")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                if isLoadingProduct {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Loading premium price…")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else if let productLoadMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(unavailableMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(unavailableDetail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Spacer()

                VStack(spacing: 12) {
                    if isLoadingProduct {
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Preparing purchase options…")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
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
                                Label("Premium Unavailable", systemImage: "exclamationmark.triangle")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        .disabled(true)

                        Button("Try Again", action: onRetryLoad)
                            .buttonStyle(.bordered)
                    }

                    Button("Restore Purchase", action: onRestore)
                        .buttonStyle(.bordered)
                        .disabled(isProcessing)

                    Button("Not now") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
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
            .font(.subheadline.weight(.medium))
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
