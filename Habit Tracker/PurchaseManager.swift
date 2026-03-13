import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "habittracker.premium.unlock"

    @Published var isPremiumUnlocked = false
    @Published var premiumProduct: Product?
    @Published var errorMessage: String?
    @Published var isProcessingPurchase = false

    private let userDefaults = UserDefaults.standard
    private let premiumKey = "habittracker.premium.unlocked"
    private var updatesTask: Task<Void, Never>?

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
        do {
            let products = try await Product.products(for: [Self.productID])
            premiumProduct = products.first
        } catch {
            errorMessage = "Couldn't load purchase options right now."
        }
    }

    func purchasePremium() async {
        guard let product = premiumProduct else {
            errorMessage = "Purchase product is not available right now."
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

            if !isPremiumUnlocked {
                errorMessage = "No previous purchase was found."
            }
        } catch {
            errorMessage = "Couldn't restore purchases right now."
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await update in Transaction.updates {
                switch update {
                case .verified(let transaction):
                    if transaction.productID == Self.productID {
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
               transaction.productID == Self.productID {
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
