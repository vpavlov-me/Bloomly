import ClockKit
import Foundation
import Tracking

#if os(watchOS)

/// Provides complication data for Apple Watch faces
public final class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Timeline Configuration

    public func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "babytrack_circular",
                displayName: "Last Feed",
                supportedFamilies: [.circularSmall]
            ),
            CLKComplicationDescriptor(
                identifier: "babytrack_rectangular",
                displayName: "Today Stats",
                supportedFamilies: [.graphicRectangular]
            ),
            CLKComplicationDescriptor(
                identifier: "babytrack_corner",
                displayName: "Events Count",
                supportedFamilies: [.graphicCorner]
            )
        ]
        handler(descriptors)
    }

    public func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        // Create entry for current time
        let entry = makeTimelineEntry(for: complication, date: Date())
        handler(entry)
    }

    public func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        // Return future timeline entries (none for now)
        handler(nil)
    }

    // MARK: - Placeholder Templates

    public func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        let template = makeTemplate(for: complication, lastFeedAgo: "2h", eventsCount: 8, sleepHours: "6h")
        handler(template)
    }

    // MARK: - Private Helpers

    private func makeTimelineEntry(for complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry? {
        guard let template = makeTemplate(for: complication, lastFeedAgo: "1h", eventsCount: 5, sleepHours: "4h") else {
            return nil
        }
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }

    private func makeTemplate(
        for complication: CLKComplication,
        lastFeedAgo: String,
        eventsCount: Int,
        sleepHours: String
    ) -> CLKComplicationTemplate? {
        switch complication.family {
        case .circularSmall:
            return makeCircularTemplate(lastFeedAgo: lastFeedAgo)

        case .graphicRectangular:
            return makeRectangularTemplate(eventsCount: eventsCount, sleepHours: sleepHours)

        case .graphicCorner:
            return makeCornerTemplate(eventsCount: eventsCount)

        default:
            return nil
        }
    }

    private func makeCircularTemplate(lastFeedAgo: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "🍼")
        template.line2TextProvider = CLKSimpleTextProvider(text: lastFeedAgo)
        return template
    }

    private func makeRectangularTemplate(eventsCount: Int, sleepHours: String) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "BabyTrack")
        template.body1TextProvider = CLKSimpleTextProvider(text: "\(eventsCount) events today")
        template.body2TextProvider = CLKSimpleTextProvider(text: "Sleep: \(sleepHours)")
        return template
    }

    private func makeCornerTemplate(eventsCount: Int) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerStackText()
        template.outerTextProvider = CLKSimpleTextProvider(text: "\(eventsCount)")
        template.innerTextProvider = CLKSimpleTextProvider(text: "events")
        return template
    }
}

#endif
