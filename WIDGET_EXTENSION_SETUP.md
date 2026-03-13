# Widget Extension Setup

This repository includes widget source code in `Habit Tracker Widgets/HabitWidgets.swift`.

Because this Codex environment edits source files only, you still need to add a Widget Extension target in Xcode and include this file in that target.

## Steps
1. In Xcode, add a new **Widget Extension** target.
2. Add `Habit Tracker Widgets/HabitWidgets.swift` to the extension target membership.
3. Add `Habit Tracker/SharedHabitSnapshot.swift` to both app and widget targets.
4. Configure the same App Group for app and widget:
   - `group.ST.HabitTracker`
5. Build and add the small/medium widgets on the Home Screen.

The app already writes shared snapshot data and triggers widget timeline reloads.
