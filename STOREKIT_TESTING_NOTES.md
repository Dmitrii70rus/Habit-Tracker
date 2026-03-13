# StoreKit Testing Notes

## Product
- **Product ID:** `habittracker.premium.unlock`
- **Type:** Non-consumable (lifetime unlock)

## Xcode testing setup
1. Open shared scheme **Habit Tracker**.
2. Verify `StoreKit.storekit` is attached to the Run action.
3. Run the app on Simulator and open the premium paywall.
4. If products are still unavailable, re-select the shared scheme and restart the run session.

> The repo includes `Habit Tracker/StoreKit.storekit` and a shared scheme that references it.

## Expected behavior
- Paywall shows a loading state while products are loading.
- Purchase button is disabled until product info is available.
- Restore Purchase checks current entitlements and unlocks premium if previously bought.
