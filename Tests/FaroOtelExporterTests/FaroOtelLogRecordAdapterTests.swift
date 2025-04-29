@testable import FaroOtelExporter
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import XCTest

final class FaroOtelLogRecordAdapterTests: XCTestCase {
    var mockDateProvider: MockDateProvider!

    // Test date: February 13, 2009 23:31:30 UTC
    let testDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            year: 2009,
            month: 2,
            day: 13,
            hour: 23,
            minute: 31,
            second: 30
        ))!
    }()

    let testISOString = "2009-02-13T23:31:30.000Z"

    override func setUp() {
        super.setUp()
        mockDateProvider = MockDateProvider(initialDate: testDate)
        FaroOtelLogRecordAdapter.dateProvider = mockDateProvider
    }

    override func tearDown() {
        FaroOtelLogRecordAdapter.dateProvider = DateProvider()
        super.tearDown()
    }

    func testBasicLogConversion() {
        // Given
        let logRecord = ReadableLogRecord(
            resource: Resource(),
            instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
            timestamp: testDate,
            body: AttributeValue.string("Test message"),
            attributes: [:]
        )

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: [logRecord])

        // Then
        XCTAssertEqual(result.logs.count, 1)
        XCTAssertEqual(result.events.count, 0)
        XCTAssertNil(result.user)

        let faroLog = result.logs[0]
        XCTAssertEqual(faroLog.timestamp, testISOString)
        XCTAssertEqual(faroLog.dateTimestamp, testDate)
        XCTAssertEqual(faroLog.message, "Test message")
        XCTAssertEqual(faroLog.level, FaroLogLevel.info) // Default level
        XCTAssertNil(faroLog.context)
        XCTAssertNil(faroLog.trace)
    }

    func testSeverityMapping() {
        let testCases: [(Severity, FaroLogLevel)] = [
            (.trace, FaroLogLevel.trace),
            (.debug, FaroLogLevel.debug),
            (.info, FaroLogLevel.info),
            (.warn, FaroLogLevel.warning),
            (.error, FaroLogLevel.error),
            (.fatal, FaroLogLevel.error), // Fatal maps to error in Faro
        ]

        for (severity, expectedLevel) in testCases {
            let logRecord = ReadableLogRecord(
                resource: Resource(),
                instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
                timestamp: testDate,
                severity: severity,
                body: AttributeValue.string("Test message"),
                attributes: [:]
            )

            let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: [logRecord])
            XCTAssertEqual(result.logs[0].level, expectedLevel, "Failed for severity \(severity)")
        }
    }

    func testAttributesConversion() {
        // Given
        let attributes: [String: AttributeValue] = [
            "string": .string("value"),
            "int": .int(42),
            "double": .double(3.14),
            "bool": .bool(true),
        ]

        let logRecord = ReadableLogRecord(
            resource: Resource(),
            instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
            timestamp: testDate,
            body: AttributeValue.string("Test message"),
            attributes: attributes
        )

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: [logRecord])

        // Then
        XCTAssertEqual(result.logs.count, 1)
        let faroLog = result.logs[0]
        XCTAssertNotNil(faroLog.context)
        XCTAssertEqual(faroLog.context?["string"], "value")
        XCTAssertEqual(faroLog.context?["int"], "42")
        XCTAssertEqual(faroLog.context?["double"], "3.14")
        XCTAssertEqual(faroLog.context?["bool"], "true")
    }

    func testTraceContextConversion() {
        // Given
        let traceId = TraceId(fromBytes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        let spanId = SpanId(fromBytes: [1, 2, 3, 4, 5, 6, 7, 8])
        let spanContext = SpanContext.create(
            traceId: traceId,
            spanId: spanId,
            traceFlags: TraceFlags(),
            traceState: TraceState()
        )

        let logRecord = ReadableLogRecord(
            resource: Resource(),
            instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
            timestamp: testDate,
            spanContext: spanContext,
            body: AttributeValue.string("Test message"),
            attributes: [:]
        )

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: [logRecord])

        // Then
        XCTAssertEqual(result.logs.count, 1)
        let faroLog = result.logs[0]
        XCTAssertNotNil(faroLog.trace)
        XCTAssertEqual(faroLog.trace?.traceId, traceId.hexString)
        XCTAssertEqual(faroLog.trace?.spanId, spanId.hexString)
    }

    func testMultipleLogConversion() {
        // Given
        let logRecords = [
            ReadableLogRecord(
                resource: Resource(),
                instrumentationScopeInfo: InstrumentationScopeInfo(name: "test1"),
                timestamp: testDate,
                severity: .info,
                body: AttributeValue.string("Message 1"),
                attributes: [:]
            ),
            ReadableLogRecord(
                resource: Resource(),
                instrumentationScopeInfo: InstrumentationScopeInfo(name: "test2"),
                timestamp: testDate,
                severity: .error,
                body: AttributeValue.string("Message 2"),
                attributes: [:]
            ),
        ]

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: logRecords)

        // Then
        XCTAssertEqual(result.logs.count, 2)
        XCTAssertEqual(result.logs[0].message, "Message 1")
        XCTAssertEqual(result.logs[0].level, FaroLogLevel.info)
        XCTAssertEqual(result.logs[1].message, "Message 2")
        XCTAssertEqual(result.logs[1].level, FaroLogLevel.error)
    }

    func testEmptyBody() {
        // Given
        let logRecord = ReadableLogRecord(
            resource: Resource(),
            instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
            timestamp: testDate,
            body: nil,
            attributes: [:]
        )

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: [logRecord])

        // Then
        XCTAssertEqual(result.logs.count, 1)
        XCTAssertEqual(result.logs[0].message, "")
    }

    func testChangeUserLogCreatesEvent() {
        // Given
        let logRecord = ReadableLogRecord(
            resource: Resource(),
            instrumentationScopeInfo: InstrumentationScopeInfo(name: "test"),
            timestamp: testDate,
            body: AttributeValue.string("otel_change_user"),
            attributes: [
                "username": AttributeValue.string("testuser"),
                "user_id": AttributeValue.string("12345"),
                "user_email": AttributeValue.string("user@example.com"),
            ]
        )

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: [logRecord])

        // Then
        XCTAssertEqual(result.logs.count, 0, "Should not create logs for change_user")
        XCTAssertEqual(result.events.count, 1, "Should create a Faro event for change_user")
        XCTAssertNotNil(result.user, "Should extract user information")

        let event = result.events[0]
        XCTAssertEqual(event.name, "faro_internal_user_updated")
        XCTAssertEqual(event.dateTimestamp, testDate)
        XCTAssertEqual(event.timestamp, testISOString)
        XCTAssertEqual(event.attributes.count, 0)

        let user = result.user!
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.id, "12345")
        XCTAssertEqual(user.email, "user@example.com")
        XCTAssertNil(user.attributes, "There should not be any provided attributes")
    }

    func testMixedLogRecords() {
        // Given
        let logRecords = [
            ReadableLogRecord(
                resource: Resource(),
                instrumentationScopeInfo: InstrumentationScopeInfo(name: "test1"),
                timestamp: testDate,
                body: AttributeValue.string("Regular log"),
                attributes: [:]
            ),
            ReadableLogRecord(
                resource: Resource(),
                instrumentationScopeInfo: InstrumentationScopeInfo(name: "test2"),
                timestamp: testDate,
                body: AttributeValue.string("otel_change_user"),
                attributes: [
                    "username": AttributeValue.string("testuser"),
                ]
            ),
            ReadableLogRecord(
                resource: Resource(),
                instrumentationScopeInfo: InstrumentationScopeInfo(name: "test3"),
                timestamp: testDate,
                body: AttributeValue.string("Another log"),
                attributes: [:]
            ),
        ]

        // When
        let result = FaroOtelLogRecordAdapter.adaptRecords(logRecords: logRecords)

        // Then
        XCTAssertEqual(result.logs.count, 2, "Should have 2 regular logs")
        XCTAssertEqual(result.events.count, 1, "Should have 1 event")
        XCTAssertNotNil(result.user, "Should extract user information")

        XCTAssertEqual(result.logs[0].message, "Regular log")
        XCTAssertEqual(result.logs[1].message, "Another log")
        XCTAssertEqual(result.events[0].name, "faro_internal_user_updated")
    }
}
