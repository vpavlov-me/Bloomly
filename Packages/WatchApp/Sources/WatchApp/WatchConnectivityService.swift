import Foundation
import WatchConnectivity
import Tracking
import Measurements

#if os(iOS)
/// iOS-side Watch Connectivity service for syncing data with Apple Watch
@MainActor
public final class WatchConnectivityService: NSObject, ObservableObject {
    public static let shared = WatchConnectivityService()

    @Published public private(set) var isReachable = false
    @Published public private(set) var isPaired = false
    @Published public private(set) var isWatchAppInstalled = false

    private let session: WCSession?

    public override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }
        super.init()

        session?.delegate = self
        session?.activate()
    }

    // MARK: - Public Methods

    /// Send recent events to the watch
    public func sendRecentEvents(_ events: [EventDTO]) {
        guard let session = session, session.isReachable else { return }

        let eventsData = events.map { event in
            [
                "id": event.id.uuidString,
                "kind": event.kind.rawValue,
                "start": event.start.timeIntervalSince1970,
                "end": event.end?.timeIntervalSince1970 as Any,
                "duration": event.duration,
                "notes": event.notes as Any
            ] as [String: Any]
        }

        let message: [String: Any] = ["recentEvents": eventsData]

        session.sendMessage(message, replyHandler: nil) { error in
            debugPrint("Failed to send events to watch: \(error)")
        }
    }

    /// Send application context with latest stats
    public func updateApplicationContext(stats: [String: Any]) {
        guard let session = session else { return }

        do {
            try session.updateApplicationContext(stats)
        } catch {
            debugPrint("Failed to update application context: \(error)")
        }
    }

    /// Transfer user info for background delivery
    public func transferUserInfo(_ userInfo: [String: Any]) {
        session?.transferUserInfo(userInfo)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = false
        }
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = false
        }
        // Reactivate the session for quick switch to new watch
        session.activate()
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle messages from watch (e.g., new event logged on watch)
        if let eventData = message["newEvent"] as? [String: Any],
           let kindString = eventData["kind"] as? String,
           let kind = EventKind(rawValue: kindString),
           let startTimestamp = eventData["start"] as? TimeInterval {

            let start = Date(timeIntervalSince1970: startTimestamp)
            let end = (eventData["end"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }

            // Post notification to inform app about new event from watch
            NotificationCenter.default.post(
                name: NSNotification.Name("watchEventReceived"),
                object: nil,
                userInfo: [
                    "kind": kind,
                    "start": start,
                    "end": end as Any,
                    "notes": eventData["notes"] as Any
                ]
            )
        }
    }
}

#elseif os(watchOS)

/// watchOS-side Watch Connectivity service for syncing with iPhone
@MainActor
public final class WatchConnectivityService: NSObject, ObservableObject {
    public static let shared = WatchConnectivityService()

    @Published public private(set) var isReachable = false
    @Published public private(set) var receivedEvents: [EventDTO] = []

    private let session: WCSession?

    public override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }
        super.init()

        session?.delegate = self
        session?.activate()
    }

    // MARK: - Public Methods

    /// Send newly created event to iPhone
    public func sendEvent(_ event: EventDTO) {
        guard let session = session, session.isReachable else { return }

        let eventData: [String: Any] = [
            "newEvent": [
                "kind": event.kind.rawValue,
                "start": event.start.timeIntervalSince1970,
                "end": event.end?.timeIntervalSince1970 as Any,
                "notes": event.notes as Any
            ]
        ]

        session.sendMessage(eventData, replyHandler: nil) { error in
            debugPrint("Failed to send event to iPhone: \(error)")
        }
    }

    /// Request recent events from iPhone
    public func requestRecentEvents() {
        guard let session = session, session.isReachable else { return }

        let message = ["requestRecentEvents": true]
        session.sendMessage(message, replyHandler: { [weak self] reply in
            Task { @MainActor [weak self] in
                self?.handleRecentEventsReply(reply)
            }
        }) { error in
            debugPrint("Failed to request events: \(error)")
        }
    }

    private func handleRecentEventsReply(_ reply: [String: Any]) {
        guard let eventsData = reply["recentEvents"] as? [[String: Any]] else { return }

        let events = eventsData.compactMap { eventDict -> EventDTO? in
            guard let idString = eventDict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let kindString = eventDict["kind"] as? String,
                  let kind = EventKind(rawValue: kindString),
                  let startTimestamp = eventDict["start"] as? TimeInterval else {
                return nil
            }

            let start = Date(timeIntervalSince1970: startTimestamp)
            let end = (eventDict["end"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
            let notes = eventDict["notes"] as? String

            return EventDTO(
                id: id,
                kind: kind,
                start: start,
                end: end,
                notes: notes,
                createdAt: start,
                updatedAt: start
            )
        }

        self.receivedEvents = events
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable

            // Request recent events when session activates
            if session.isReachable {
                self.requestRecentEvents()
            }
        }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable

            if session.isReachable {
                self.requestRecentEvents()
            }
        }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        // Handle requests from iPhone
        if message["requestRecentEvents"] != nil {
            // Watch typically receives events from iPhone, not the other way
            // But we can still support this if needed
            replyHandler(["recentEvents": []])
        }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle incoming events from iPhone
        if let eventsData = message["recentEvents"] as? [[String: Any]] {
            Task { @MainActor in
                handleRecentEventsReply(["recentEvents": eventsData])
            }
        }
    }

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Handle application context updates
        Task { @MainActor in
            // Process stats or other context data
            if let eventsData = applicationContext["recentEvents"] as? [[String: Any]] {
                handleRecentEventsReply(["recentEvents": eventsData])
            }
        }
    }
}

#endif
