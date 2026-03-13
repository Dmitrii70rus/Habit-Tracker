import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let primaryProductID = "habittracker.premium.unlock"
    static let fallbackProductID = "habittracker.premium"

    @Published var isPremiumUnlocked = false
    @Published var premiumProduct: Product?
    @Published var errorMessage: String?
    @Published var isProcessingPurchase = false
    @Published var isLoadingProducts = false
    @Published var productLoadMessage: String?

    private let userDefaults = UserDefaults.standard
    private let premiumKey = "habittracker.premium.unlocked"
    private var updatesTask: Task<Void, Never>?

    var isProductReady: Bool {
        premiumProduct != nil
    }

    private var supportedProductIDs: [String] {
        [Self.primaryProductID, Self.fallbackProductID]
    }

    init() {
        isPremiumUnlocked = userDefaults.bool(forKey: premiumKey)
        updatesTask = observeTransactionUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        await loadProducts()
        await refreshPurchasedState()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        productLoadMessage = nil
        premiumProduct = nil

        defer {
            isLoadingProducts = false
        }

        do {
            let products = try await Product.products(for: supportedProductIDs)
            premiumProduct = products.first { $0.id == Self.primaryProductID } ?? products.first

            if premiumProduct == nil {
                productLoadMessage = "Premium temporarily unavailable."
#if DEBUG
                print("[StoreKit] No products returned for IDs: \(supportedProductIDs.joined(separator: ", "))")
#endif
            }
        } catch {
            productLoadMessage = "Premium temporarily unavailable."
#if DEBUG
            print("[StoreKit] Product load failed for IDs: \(supportedProductIDs.joined(separator: ", ")). Error: \(error)")
#endif
        }
    }

    func purchasePremium() async {
        if premiumProduct == nil {
            await loadProducts()
        }

        guard let product = premiumProduct else {
            errorMessage = "Premium product is not available right now. Please try again later."
            return
        }

        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await unlockPremium()
                    await transaction.finish()
                case .unverified:
                    errorMessage = "We couldn't verify this purchase."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                errorMessage = "Purchase failed. Please try again."
            }
        } catch {
            errorMessage = "Purchase failed. Please check your connection and try again."
        }
    }

    func restorePurchases() async {
        isProcessingPurchase = true
        defer { isProcessingPurchase = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedState()

            if isPremiumUnlocked {
                errorMessage = "Purchases restored successfully."
            } else {
                errorMessage = "No previous purchase was found for this Apple ID."
            }
        } catch {
            errorMessage = "Couldn't restore purchases right now."
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func clearProductLoadMessage() {
        productLoadMessage = nil
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await update in Transaction.updates {
                switch update {
                case .verified(let transaction):
                    if supportedProductIDs.contains(transaction.productID) {
                        await unlockPremium()
                    }
                    await transaction.finish()
                case .unverified:
                    break
                }
            }
        }
    }

    private func refreshPurchasedState() async {
        var isUnlocked = false

        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               supportedProductIDs.contains(transaction.productID) {
                isUnlocked = true
                break
            }
        }

        if isUnlocked {
            await unlockPremium()
        } else {
            isPremiumUnlocked = userDefaults.bool(forKey: premiumKey)
        }
    }

    private func unlockPremium() async {
        isPremiumUnlocked = true
        userDefaults.set(true, forKey: premiumKey)
    }
}
