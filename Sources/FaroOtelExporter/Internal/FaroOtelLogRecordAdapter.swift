import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

// MARK: - Telemetry Input Structure

/// Structure to hold both logs and events generated from OTel records
struct FaroTelemetryInput {
    let logs: [FaroLog]
    let events: [FaroEvent]
    let user: FaroUser?
}

// MARK: - OTel Record Adapter

/// Adapter to convert OpenTelemetry log records to Faro logs and events
class FaroOtelLogRecordAdapter {
    /// Static date provider for timestamp handling
    static var dateProvider: DateProviding = DateProvider()

    /// Convert an array of OpenTelemetry log records to Faro logs and events
    /// - Parameter logRecords: The OTel log records to convert
    /// - Returns: A FaroTelemetryInput object containing arrays of FaroLog and FaroEvent
    static func adaptRecords(logRecords: [ReadableLogRecord]) -> FaroTelemetryInput {
        var faroLogs = [FaroLog]()
        var faroEvents = [FaroEvent]()
        var currentUser: FaroUser?
        for logRecord in logRecords {
            if let body = logRecord.body, body.description == FaroOtelConstants.ChangeUser.otelBody {
                // Intercept and create a FaroEvent using the helper
                let faroEvent = toFaroEvent(logRecord: logRecord)
                faroEvents.append(faroEvent)
                currentUser = toFaroUser(logRecord: logRecord)
            } else {
                // Convert to FaroLog as before
                let faroLog = toFaroLog(logRecord: logRecord)
                faroLogs.append(faroLog)
            }
        }

        return FaroTelemetryInput(logs: faroLogs, events: faroEvents, user: currentUser)
    }

    /// Extracts FaroUser information from a log record if relevant attributes are present.
    /// - Parameter logRecord: The OTel log record to inspect.
    /// - Returns: A FaroUser object if user_id, username, or user_email is found, otherwise nil.
    private static func toFaroUser(logRecord: ReadableLogRecord) -> FaroUser? {
        let userId = logRecord.attributes[FaroOtelConstants.ChangeUser.AttributeKeys.userId]?.description ?? ""
        let userName = logRecord.attributes[FaroOtelConstants.ChangeUser.AttributeKeys.username]?.description ?? ""
        let userEmail = logRecord.attributes[FaroOtelConstants.ChangeUser.AttributeKeys.userEmail]?.description ?? ""

        // Return nil only if all specific fields are empty
        if userId.isEmpty, userName.isEmpty, userEmail.isEmpty {
            return nil
        }

        return FaroUser(
            id: userId,
            username: userName,
            email: userEmail,
            attributes: nil
        )
    }

    /// Convert a single "otel_change_user" log record to a Faro event (private helper)
    private static func toFaroEvent(logRecord: ReadableLogRecord) -> FaroEvent {
        let dateTimestamp = logRecord.timestamp
        let isoTimestamp = dateProvider.iso8601String(from: dateTimestamp)

        // Add trace context if available
        let traceContext: FaroTraceContext?
        if let spanContext = logRecord.spanContext {
            let traceId = spanContext.traceId.hexString
            let spanId = spanContext.spanId.hexString
            traceContext = FaroTraceContext.create(traceId: traceId, spanId: spanId)
        } else {
            traceContext = nil
        }

        return FaroEvent(
            name: FaroConstants.Events.userUpdated,
            attributes: [:],
            timestamp: isoTimestamp,
            dateTimestamp: dateTimestamp,
            trace: traceContext
        )
    }

    /// Convert a single OpenTelemetry log record to a Faro log (private helper)
    private static func toFaroLog(logRecord: ReadableLogRecord) -> FaroLog {
        // Convert timestamp to ISO8601 string (required by Faro)
        let dateTimestamp = logRecord.timestamp
        let timestamp = dateProvider.iso8601String(from: dateTimestamp)

        // Convert severity to Faro log level
        let level = convertSeverityToLogLevel(severity: logRecord.severity)

        // Get message from body attribute or fallback to empty string
        let message: String = if let body = logRecord.body {
            body.description
        } else {
            ""
        }

        // Convert attributes to Faro context
        var context = [String: String]()
        for (key, value) in logRecord.attributes {
            context[key] = value.description
        }

        // Add trace context if available
        let traceContext: FaroTraceContext?
        if let spanContext = logRecord.spanContext {
            let traceId = spanContext.traceId.hexString
            let spanId = spanContext.spanId.hexString
            traceContext = FaroTraceContext.create(traceId: traceId, spanId: spanId)
        } else {
            traceContext = nil
        }

        return FaroLog(
            timestamp: timestamp,
            dateTimestamp: dateTimestamp,
            level: level,
            message: message,
            context: context.isEmpty ? nil : context,
            trace: traceContext
        )
    }

    /// Convert OTel severity to Faro log level
    private static func convertSeverityToLogLevel(severity: Severity?) -> FaroLogLevel {
        guard let severity else {
            return .info // Default to info level if no severity provided
        }

        switch severity {
        case .trace, .trace2, .trace3, .trace4:
            return .trace
        case .debug, .debug2, .debug3, .debug4:
            return .debug
        case .info, .info2, .info3, .info4:
            return .info
        case .warn, .warn2, .warn3, .warn4:
            return .warning
        case .error, .error2, .error3, .error4:
            return .error
        case .fatal, .fatal2, .fatal3, .fatal4:
            return .error // Faro doesn't have a fatal level, using error as closest match
        }
    }
}
