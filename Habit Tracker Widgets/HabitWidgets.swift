#if canImport(WidgetKit) && WIDGET_EXTENSION
import WidgetKit
import SwiftUI

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedHabitSnapshot
}

struct HabitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        completion(HabitWidgetEntry(date: .now, snapshot: SharedHabitSnapshotBuilder.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let snapshot = SharedHabitSnapshotBuilder.load()
        let entry = HabitWidgetEntry(date: .now, snapshot: snapshot)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct HabitSmallWidgetView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "widget.today"))
                .textCase(nil)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(format: String(localized: "widget.done_summary"), entry.snapshot.completedHabits, entry.snapshot.totalActiveHabits))
                .font(.headline)
                .lineLimit(2)

            Text(String(format: String(localized: "widget.streak"), entry.snapshot.overallCurrentStreak))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct HabitMediumWidgetView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.snapshot.todayLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(format: String(localized: "widget.medium.completed"), entry.snapshot.completedHabits, entry.snapshot.totalActiveHabits))
                .font(.headline)

            ForEach(Array(entry.snapshot.habits.prefix(5).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 6) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                    Text(item.title)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}

struct HabitSmallWidget: Widget {
    let kind: String = "HabitSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            HabitSmallWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget.small.name"))
        .description(String(localized: "widget.small.description"))
        .supportedFamilies([.systemSmall])
    }
}

struct HabitMediumWidget: Widget {
    let kind: String = "HabitMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            HabitMediumWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget.medium.name"))
        .description(String(localized: "widget.medium.description"))
        .supportedFamilies([.systemMedium])
    }
}

@main
struct HabitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HabitSmallWidget()
        HabitMediumWidget()
    }
}
#endif
