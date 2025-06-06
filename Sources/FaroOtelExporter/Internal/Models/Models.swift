import Foundation
import OpenTelemetryProtocolExporterCommon

/// Represents the complete payload sent to Faro collector
struct FaroPayload: Encodable {
    let meta: FaroMeta
    let traces: Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest?
    let logs: [FaroLog]?
    let events: [FaroEvent]?
    let measurements: [FaroMeasurement]?
    let exceptions: [FaroException]?

    init(
        meta: FaroMeta,
        traces: Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest? = nil,
        logs: [FaroLog]? = nil,
        events: [FaroEvent]? = nil,
        measurements: [FaroMeasurement]? = nil,
        exceptions: [FaroException]? = nil
    ) {
        self.meta = meta
        self.traces = traces
        self.logs = logs
        self.events = events
        self.measurements = measurements
        self.exceptions = exceptions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(meta, forKey: .meta)

        if let traces {
            // Convert protobuf to JSON object and inject it directly
            let jsonData = try traces.jsonUTF8Data()
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                // Create a nested container for traces and encode each key-value pair
                var tracesContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .traces)
                try encodeJSONObject(jsonObject, into: &tracesContainer)
            }
        }

        if let logs {
            try container.encode(logs, forKey: .logs)
        }

        if let events {
            try container.encode(events, forKey: .events)
        }

        if let measurements {
            try container.encode(measurements, forKey: .measurements)
        }

        if let exceptions {
            try container.encode(exceptions, forKey: .exceptions)
        }
    }

    // Helper for basic value types
    private func encodeJSONValue(_ value: Any, forKey key: DynamicCodingKey, into container: inout KeyedEncodingContainer<DynamicCodingKey>) throws {
        if let stringValue = value as? String {
            try container.encode(stringValue, forKey: key)
        } else if let intValue = value as? Int {
            try container.encode(intValue, forKey: key)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue, forKey: key)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue, forKey: key)
        } else if value is NSNull {
            try container.encodeNil(forKey: key)
        }
        // Note: Arrays and Dictionaries are handled separately before calling this helper
    }

    // Helper for trace/span ID encoding
    private func encodeTraceSpanID(_ value: Any, forKey key: DynamicCodingKey, into container: inout KeyedEncodingContainer<DynamicCodingKey>) throws -> Bool {
        // Check various capitalization and formats
        guard key.stringValue.lowercased() == "traceid" || key.stringValue.lowercased() == "spanid" || key.stringValue.lowercased() == "parentspanid" else {
            return false // Not a trace/span ID key
        }

        // Handle different possible value types
        if let data = value as? Data {
            let hexString = data.map { String(format: "%02hhx", $0) }.joined()
            try container.encode(hexString, forKey: key)
            return true
        } else if let base64String = value as? String {
            if let data = Data(base64Encoded: base64String) {
                let hexString = data.map { String(format: "%02hhx", $0) }.joined()
                try container.encode(hexString, forKey: key)
                return true
            }
        } else if let valueDict = value as? [String: Any], let stringValue = valueDict["stringValue"] as? String {
            try container.encode(stringValue, forKey: key)
            return true
        } else if let stringValue = value as? String { // If it's already a string (potentially hex)
            try container.encode(stringValue, forKey: key)
            return true
        }
        return false // Couldn't encode as trace/span ID
    }

    // Helper for span kind encoding
    private func encodeSpanKind(_ value: Any, forKey key: DynamicCodingKey, into container: inout KeyedEncodingContainer<DynamicCodingKey>) throws -> Bool {
        guard key.stringValue == "kind" else {
            return false // Not the span kind key
        }

        if let kindString = value as? String {
            let kindValue = switch kindString {
            case "SPAN_KIND_INTERNAL": 1
            case "SPAN_KIND_SERVER": 2
            case "SPAN_KIND_CLIENT": 3
            case "SPAN_KIND_PRODUCER": 4
            case "SPAN_KIND_CONSUMER": 5
            default: 0
            }
            try container.encode(kindValue, forKey: key)
            return true
        } else if let kindInt = value as? Int {
            try container.encode(kindInt, forKey: key)
            return true
        }
        return false // Couldn't encode as span kind
    }

    // Helper method to encode JSON objects with proper nesting
    private func encodeJSONObject(_ jsonObject: [String: Any], into container: inout KeyedEncodingContainer<DynamicCodingKey>) throws {
        for (key, value) in jsonObject {
            let codingKey = DynamicCodingKey(key: key)

            // Try special handlers first
            if try encodeTraceSpanID(value, forKey: codingKey, into: &container) { continue }
            if try encodeSpanKind(value, forKey: codingKey, into: &container) { continue }

            // If not a special key, handle standard types
            if let arrayValue = value as? [Any] {
                // Create a nested array container
                var arrayContainer = container.nestedUnkeyedContainer(forKey: codingKey)
                try encodeJSONArray(arrayValue, into: &arrayContainer)
            } else if let dictValue = value as? [String: Any] {
                // Create a nested keyed container
                var nestedDictContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: codingKey)
                try encodeJSONObject(dictValue, into: &nestedDictContainer)
            } else {
                // Handle basic types using the helper
                try encodeJSONValue(value, forKey: codingKey, into: &container)
            }
        }
    }

    // Helper method to encode JSON arrays with proper nesting
    private func encodeJSONArray(_ array: [Any], into container: inout UnkeyedEncodingContainer) throws {
        for value in array {
            if let stringValue = value as? String {
                try container.encode(stringValue)
            } else if let intValue = value as? Int {
                try container.encode(intValue)
            } else if let doubleValue = value as? Double {
                try container.encode(doubleValue)
            } else if let boolValue = value as? Bool {
                try container.encode(boolValue)
            } else if let arrayValue = value as? [Any] {
                // Create a nested array container
                var nestedArrayContainer = container.nestedUnkeyedContainer()
                try encodeJSONArray(arrayValue, into: &nestedArrayContainer)
            } else if let dictValue = value as? [String: Any] {
                var dictContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self)
                try encodeJSONObject(dictValue, into: &dictContainer)
            } else if value is NSNull {
                try container.encodeNil()
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case meta
        case traces
        case logs
        case events
        case measurements
        case exceptions
    }
}

/// Holds metadata about an app event
struct FaroMeta: Encodable {
    let sdk: FaroSdkInfo
    let app: FaroAppInfo
    let session: FaroSession
    let user: FaroUser?
    let view: FaroView
}

/// Holds metadata about a view
struct FaroView: Encodable {
    let name: String
}

/// Holds metadata about the user related to an app event
struct FaroUser: Encodable {
    let id: String?
    let username: String?
    let email: String?
    let attributes: [String: String]?

    init(id: String, username: String, email: String, attributes: [String: String]?) {
        self.id = id
        self.username = username
        self.email = email
        self.attributes = attributes
    }
}

/// Holds metadata about the browser session the event originates from
struct FaroSession: Encodable {
    let id: String
    let attributes: [String: String]
}

/// Holds metadata about the app agent that produced the event
struct FaroSdkInfo: Encodable {
    let name: String
    let version: String
    let integrations: [FaroIntegration]
}

/// Holds metadata about a plugin/integration on the app agent that collected and sent the event
struct FaroIntegration: Encodable {
    let name: String
    let version: String
}

/// Holds metadata about the application event originates from
struct FaroAppInfo: Encodable {
    let name: String?
    let namespace: String?
    let version: String?
    let environment: String?
    let bundleId: String?
    let release: String?
}

/// Holds trace id and span id associated to an entity (log, exception, measurement...)
struct FaroTraceContext: Encodable, Equatable {
    let traceId: String?
    let spanId: String?

    enum CodingKeys: String, CodingKey {
        case traceId = "trace_id"
        case spanId = "span_id"
    }

    private init(traceId: String?, spanId: String?) {
        self.traceId = traceId
        self.spanId = spanId
    }

    static func create(traceId: String?, spanId: String?) -> FaroTraceContext? {
        guard traceId?.isEmpty == false || spanId?.isEmpty == false else {
            return nil
        }
        return FaroTraceContext(traceId: traceId, spanId: spanId)
    }
}

/// Holds RUM event data
struct FaroEvent: Encodable {
    let name: String
    let domain: String
    let attributes: [String: String]
    let timestamp: String
    let trace: FaroTraceContext?
    let dateTimestamp: Date

    init(
        name: String,
        attributes: [String: String] = [:],
        timestamp: String,
        dateTimestamp: Date,
        trace: FaroTraceContext?
    ) {
        self.name = name
        domain = "swift"
        self.attributes = attributes
        self.timestamp = timestamp
        self.dateTimestamp = dateTimestamp
        self.trace = trace
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case domain
        case attributes
        case timestamp
        case trace
        // dateTimestamp is intentionally omitted from CodingKeys to exclude it from encoding
    }
}

/// Holds the data for user provided measurements
struct FaroMeasurement: Encodable {
    let type: String
    let values: [String: Double]
    let timestamp: String
    let trace: FaroTraceContext?
}

/// Represents a single stacktrace frame
struct FaroStacktraceFrame: Encodable {
    let colno: Int
    let lineno: Int
    let filename: String
    let function: String
    let module: String
}

/// Is a collection of Frames
struct FaroStacktrace: Encodable {
    let frames: [FaroStacktraceFrame]
}

/// Holds all the data regarding an exception
struct FaroException: Encodable {
    let type: String
    let value: String
    let timestamp: String
    let stacktrace: FaroStacktrace?
    let context: [String: String]?
    let trace: FaroTraceContext?
}

/// Log level enum for incoming app logs
enum FaroLogLevel: String, Encodable {
    case trace
    case debug
    case info
    case warning
    case error
}

/// Controls the data that come into a Log message
struct FaroLog: Encodable, Equatable {
    let timestamp: String
    let level: FaroLogLevel
    let message: String
    let context: [String: String]?
    let trace: FaroTraceContext?
    let dateTimestamp: Date

    init(timestamp: String, dateTimestamp: Date, level: FaroLogLevel, message: String, context: [String: String]?, trace: FaroTraceContext?) {
        self.timestamp = timestamp
        self.dateTimestamp = dateTimestamp
        self.level = level
        self.message = message
        self.context = context
        self.trace = trace
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case level
        case message
        case context
        case trace
        // dateTimestamp is intentionally omitted from CodingKeys to exclude it from encoding
    }
}

/// Error types used throughout the exporter
enum FaroExporterError: Error, Equatable {
    case invalidCollectorUrl
    case missingApiKey
    case payloadTooLarge
    case networkError(Error)
    case serializationError(Error)

    static func == (lhs: FaroExporterError, rhs: FaroExporterError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCollectorUrl, .invalidCollectorUrl),
             (.missingApiKey, .missingApiKey),
             (.payloadTooLarge, .payloadTooLarge):
            true
        case let (.networkError(lhsError), .networkError(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        case let (.serializationError(lhsError), .serializationError(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(key: String) {
        stringValue = key
        intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
