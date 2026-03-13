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
                Text(L10n.paywallTitle)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(L10n.paywallSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(L10n.paywallBenefitUnlimited)
                    featureRow(L10n.paywallBenefitReminders)
                    featureRow(L10n.paywallBenefitStats)
                    featureRow(L10n.paywallBenefitUpdates)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                if isLoadingProduct {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(L10n.paywallLoadingOptions)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if hasProductIssue {
                    VStack(spacing: 6) {
                        Text(L10n.paywallUnavailableTitle)
                            .font(.footnote.weight(.semibold))
                            .multilineTextAlignment(.center)
                        Text(L10n.paywallUnavailableMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button(L10n.paywallTryAgain, action: onRetryLoad)
                        .buttonStyle(.bordered)
                }

                if isLoadingProduct {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text(L10n.paywallLoadingPurchase)
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
                            Text(L10n.paywallUnlockCta(displayPrice))
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
                            Text(L10n.paywallUnavailableCta)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }

                Button(L10n.paywallRestore, action: onRestore)
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)

                Button(L10n.paywallClose) {
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
