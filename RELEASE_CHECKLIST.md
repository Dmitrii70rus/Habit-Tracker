# Release Checklist

## 1) Assets & Branding
- [ ] Confirm final app icon is manually imported in all required sizes
- [ ] Verify launch visuals and accent color in Light/Dark mode

## 2) StoreKit & Premium
- [ ] Verify App Store Connect product IDs match app constants
- [ ] Verify local StoreKit configuration works in Simulator
- [ ] Verify purchase flow, cancellation flow, and restore flow
- [ ] Verify premium unlock persists across relaunch

## 3) Widgets & Shared Data
- [ ] Verify widget extension builds in Release
- [ ] Verify App Group identifier is configured for app + widget targets
- [ ] Verify widget timeline refresh after habit updates

## 4) Reminders
- [ ] Verify notification permission prompt behavior
- [ ] Verify denied-permission messaging is clear
- [ ] Verify reminders fire for planned active habits

## 5) QA (Simulator + Device)
- [ ] Fresh install flow (no data)
- [ ] Habit create/edit/delete flow
- [ ] Start date and recurrence correctness
- [ ] Planned vs completed state behavior by date
- [ ] Streak and analytics correctness
- [ ] Paywall loading/unavailable/available states
- [ ] Localization smoke test (Base English)

## 6) Screenshot Capture Checklist
- [ ] Main screen with populated habits
- [ ] Empty state screen
- [ ] Habit detail screen with progress
- [ ] Paywall screen (available product)
- [ ] Reminder-enabled habit example

## 7) TestFlight
- [ ] Increment build number
- [ ] Archive + upload to App Store Connect
- [ ] Add release notes
- [ ] Verify external/internal tester groups

## 8) App Store Submission
- [ ] Paste final metadata and keywords
- [ ] Upload final screenshots
- [ ] Set age rating and privacy details
- [ ] Confirm in-app purchase is attached to submission
- [ ] Submit for review
