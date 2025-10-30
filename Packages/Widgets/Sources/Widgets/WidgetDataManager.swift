import Foundation
import CoreData

/// Manages data fetching for widgets using shared App Group
@MainActor
public final class WidgetDataManager {
    public static let shared = WidgetDataManager()

    private let appGroupIdentifier = "group.com.vibecoding.bloomly"
    private var persistentContainer: NSPersistentContainer?

    private init() {
        setupCoreData()
    }

    // MARK: - Core Data Setup

    private func setupCoreData() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("⚠️ Failed to get App Group container URL")
            return
        }

        let storeURL = containerURL.appendingPathComponent("bloomly.sqlite")

        let container = NSPersistentContainer(name: "BloomlyModel")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("⚠️ Core Data failed to load: \(error.localizedDescription)")
            }
        }

        self.persistentContainer = container
    }

    // MARK: - Data Fetching

    /// Fetch last feed data for small widget
    public func fetchLastFeedData() async -> (timeSince: String, feedType: String) {
        guard let context = persistentContainer?.viewContext else {
            return ("--", "No Data")
        }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "kind == %@", "feeding")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            if let lastFeed = results.first,
               let date = lastFeed.value(forKey: "date") as? Date {
                let timeSince = formatTimeSince(date)
                let feedType = (lastFeed.value(forKey: "metadata") as? [String: Any])?["feedingType"] as? String ?? "Feed"
                return (timeSince, feedType)
            }
        } catch {
            print("⚠️ Failed to fetch last feed: \(error)")
        }

        return ("--", "No Data")
    }

    /// Fetch summary data for medium widget
    public func fetchSummaryData() async -> (lastFeed: String, lastSleep: String, lastDiaper: String) {
        guard let context = persistentContainer?.viewContext else {
            return ("--", "--", "--")
        }

        let feedTime = await fetchLastEventTime(context: context, kind: "feeding")
        let sleepTime = await fetchLastEventTime(context: context, kind: "sleep")
        let diaperTime = await fetchLastEventTime(context: context, kind: "diaper")

        return (feedTime, sleepTime, diaperTime)
    }

    /// Fetch timeline data for large widget
    public func fetchTimelineData() async -> (
        totalFeeds: Int,
        totalDiapers: Int,
        totalSleepHours: Double,
        recentEvents: [RecentEvent]
    ) {
        guard let context = persistentContainer?.viewContext else {
            return (0, 0, 0.0, [])
        }

        // Get today's date range
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Fetch all today's events
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let events = try context.fetch(fetchRequest)

            // Count by type
            let feedCount = events.filter { ($0.value(forKey: "kind") as? String) == "feeding" }.count
            let diaperCount = events.filter { ($0.value(forKey: "kind") as? String) == "diaper" }.count

            // Calculate total sleep hours
            let sleepEvents = events.filter { ($0.value(forKey: "kind") as? String) == "sleep" }
            var totalSleepMinutes: Double = 0
            for event in sleepEvents {
                if let duration = event.value(forKey: "duration") as? Double {
                    totalSleepMinutes += duration
                }
            }
            let totalSleepHours = totalSleepMinutes / 60.0

            // Get recent 5 events
            let recentEvents = events.prefix(5).compactMap { event -> RecentEvent? in
                guard let date = event.value(forKey: "date") as? Date,
                      let kind = event.value(forKey: "kind") as? String else {
                    return nil
                }

                let icon: String
                let description: String

                switch kind {
                case "feeding":
                    icon = "drop.fill"
                    description = "Feed"
                case "sleep":
                    icon = "moon.fill"
                    let duration = event.value(forKey: "duration") as? Double ?? 0
                    description = "Sleep (\(formatDuration(duration)))"
                case "diaper":
                    icon = "humidity.fill"
                    description = "Diaper"
                default:
                    icon = "circle.fill"
                    description = kind.capitalized
                }

                return RecentEvent(
                    icon: icon,
                    time: formatTimeSince(date),
                    description: description
                )
            }

            return (feedCount, diaperCount, totalSleepHours, Array(recentEvents))
        } catch {
            print("⚠️ Failed to fetch timeline data: \(error)")
            return (0, 0, 0.0, [])
        }
    }

    // MARK: - Helper Methods

    private func fetchLastEventTime(context: NSManagedObjectContext, kind: String) async -> String {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "kind == %@", kind)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            if let lastEvent = results.first,
               let date = lastEvent.value(forKey: "date") as? Date {
                return formatTimeSince(date)
            }
        } catch {
            print("⚠️ Failed to fetch last \(kind): \(error)")
        }

        return "--"
    }

    private func formatTimeSince(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Just now"
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}
