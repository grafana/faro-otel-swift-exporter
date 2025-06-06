import Foundation
import OpenTelemetryProtocolExporterCommon
import OpenTelemetrySdk

final class FaroManager {
    private let appInfo: FaroAppInfo
    private let transport: FaroTransportable
    private var sessionManager: FaroSessionManaging
    private let dateProvider: DateProviding
    private let telemetryDataQueue = DispatchQueue(label: "com.opentelemetry.exporter.faro.telemetryDataQueue")
    private let flushQueue = DispatchQueue(label: "com.opentelemetry.exporter.faro.flushQueue")

    private let config: FaroManagerConfig
    private var flushWorkItem: DispatchWorkItem?

    private var pendingLogs: [FaroLog] = []
    private var pendingEvents: [FaroEvent] = []
    private var pendingSpans: [SpanData] = []

    private var currentUser: FaroUser?

    init(
        appInfo: FaroAppInfo,
        transport: FaroTransportable,
        sessionManager: FaroSessionManaging,
        dateProvider: DateProviding = DateProvider(),
        config: FaroManagerConfig = FaroManagerConfig(flushInterval: 2.0)
    ) {
        self.appInfo = appInfo
        self.transport = transport
        self.sessionManager = sessionManager
        self.dateProvider = dateProvider
        self.config = config

        sendSessionStartEvent()
        listenForSessionChanges()
    }

    func pushEvents(_ events: [FaroEvent]) {
        telemetryDataQueue.sync {
            pendingEvents.append(contentsOf: events)
        }
        scheduleFlush()
    }

    func pushLogs(_ logs: [FaroLog]) {
        telemetryDataQueue.sync {
            pendingLogs.append(contentsOf: logs)
        }
        scheduleFlush()
    }

    func pushSpans(_ spans: [SpanData]) {
        telemetryDataQueue.sync {
            pendingSpans.append(contentsOf: spans)
        }
        scheduleFlush()
    }

    func setUser(_ user: FaroUser?) {
        telemetryDataQueue.sync {
            self.currentUser = user
        }
    }

    private func sendSessionStartEvent() {
        let sessionStartEvent = FaroEvent.create(name: "session_start")
        pushEvents([sessionStartEvent])
    }

    private func scheduleFlush() {
        if flushWorkItem == nil {
            let workItem = DispatchWorkItem { [weak self] in
                self?.flushPendingData()
            }
            flushWorkItem = workItem
            flushQueue.asyncAfter(deadline: .now() + config.flushInterval, execute: workItem)
        }
    }

    private func flushPendingData() {
        var sendingLogs: [FaroLog] = []
        var sendingEvents: [FaroEvent] = []
        var sendingSpans: [SpanData] = []
        var sendingUser: FaroUser?

        telemetryDataQueue.sync {
            sendingLogs = pendingLogs
            sendingEvents = pendingEvents
            sendingSpans = pendingSpans
            sendingUser = currentUser
            pendingLogs = []
            pendingEvents = []
            pendingSpans = []

            flushWorkItem?.cancel()
            flushWorkItem = nil
        }

        if !sendingLogs.isEmpty || !sendingEvents.isEmpty || !sendingSpans.isEmpty {
            let payload = getPayload(logs: sendingLogs, events: sendingEvents, spans: sendingSpans, user: sendingUser)
            transport.send(payload) { [weak self] result in
                switch result {
                case .success:
                    // Data sent successfully
                    break
                case .failure:
                    self?.telemetryDataQueue.sync {
                        // Simply add failed items back to pending queues
                        self?.pendingLogs.append(contentsOf: sendingLogs)
                        self?.pendingEvents.append(contentsOf: sendingEvents)
                        self?.pendingSpans.append(contentsOf: sendingSpans)
                        // No explicit retry scheduling - next natural data addition will trigger it
                    }
                }
            }
        }
    }

    private func findLatestTimestamp(logs: [FaroLog], events: [FaroEvent], spans: [SpanData]) -> Date? {
        let logDates = logs.compactMap(\.dateTimestamp)
        let eventDates = events.compactMap(\.dateTimestamp)
        let spanEndTimes = spans.map(\.endTime)
        let allTimestamps = logDates + eventDates + spanEndTimes
        return allTimestamps.max()
    }

    private func getPayload(logs: [FaroLog], events: [FaroEvent], spans: [SpanData] = [], user: FaroUser?) -> FaroPayload {
        if let latestTimestamp = findLatestTimestamp(logs: logs, events: events, spans: spans) {
            sessionManager.updateLastActivity(date: latestTimestamp)
        }

        let session = sessionManager.getSession()

        let traces = spans.isEmpty ? nil : Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with {
            $0.resourceSpans = FaroSpanAdapter.toProtoResourceSpans(spanDataList: spans, sessionId: session.id)
        }

        return FaroPayload(
            meta: FaroMeta(
                sdk: FaroSdkInfo(name: "opentelemetry-swift-faro-exporter", version: "1.3.5", integrations: []),
                app: appInfo,
                session: session,
                user: user,
                view: FaroView(name: "default")
            ),
            traces: traces,
            logs: logs,
            events: events
        )
    }

    private func listenForSessionChanges() {
        sessionManager.onSessionIdChanged = { [weak self] _, _ in
            self?.sendSessionStartEvent()
        }
    }
}

struct FaroManagerConfig {
    let flushInterval: TimeInterval
}
