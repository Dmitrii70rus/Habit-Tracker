# StoreKit Testing Notes

## Product
- **Product ID:** `habittracker.premium.unlock`
- **Type:** Non-consumable (lifetime unlock)

## Xcode testing setup
1. Create or open a StoreKit Configuration file in Xcode.
2. Add non-consumable product with ID `habittracker.premium.unlock`.
3. Run the app with that StoreKit configuration attached to the scheme.

## Expected behavior
- Paywall shows a loading state while products are loading.
- Purchase button is disabled until product info is available.
- Restore Purchase checks current entitlements and unlocks premium if previously bought.
