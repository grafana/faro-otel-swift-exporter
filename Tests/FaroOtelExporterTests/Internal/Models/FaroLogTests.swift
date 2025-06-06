@testable import FaroOtelExporter
import XCTest

final class FaroLogTests: XCTestCase {
    // MARK: - Test Data

    private let timestamp = "2024-03-20T10:00:00Z"
    private let message = "Test message"
    private let context = ["key": "value"]
    private let trace = FaroTraceContext.create(traceId: "trace123", spanId: "span456")

    // MARK: - Equatable Tests

    func testEquatableEqual() {
        let date = Date()

        // Given
        let log1 = FaroLog(
            timestamp: timestamp,
            dateTimestamp: date,
            level: .info,
            message: message,
            context: context,
            trace: trace
        )

        let log2 = FaroLog(
            timestamp: timestamp,
            dateTimestamp: date,
            level: .info,
            message: message,
            context: context,
            trace: trace
        )

        // Then
        XCTAssertEqual(log1, log2)
    }

    func testEquatableNotEqualDifferentTimestamp() {
        let date = Date()

        // Given
        let log1 = FaroLog(timestamp: "2024-03-20T10:00:00Z", dateTimestamp: date, level: .info, message: message, context: context, trace: trace)
        let log2 = FaroLog(timestamp: "2024-03-20T10:00:01Z", dateTimestamp: date, level: .info, message: message, context: context, trace: trace)

        // Then
        XCTAssertNotEqual(log1, log2, "Should not be equal with different timestamp")
    }

    func testEquatableNotEqualDifferentLevel() {
        let date = Date()

        // Given
        let log1 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: context, trace: trace)
        let log2 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .error, message: message, context: context, trace: trace)

        // Then
        XCTAssertNotEqual(log1, log2, "Should not be equal with different level")
    }

    func testEquatableNotEqualDifferentMessage() {
        let date = Date()

        // Given
        let log1 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: "Message 1", context: context, trace: trace)
        let log2 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: "Message 2", context: context, trace: trace)

        // Then
        XCTAssertNotEqual(log1, log2, "Should not be equal with different message")
    }

    func testEquatableNotEqualDifferentContext() {
        let date = Date()

        // Given
        let log1 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: ["key1": "value1"], trace: trace)
        let log2 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: ["key2": "value2"], trace: trace)

        // Then
        XCTAssertNotEqual(log1, log2, "Should not be equal with different context")
    }

    func testEquatableNotEqualDifferentTrace() {
        let date = Date()

        // Given
        let trace1 = FaroTraceContext.create(traceId: "trace1", spanId: "span1")
        let trace2 = FaroTraceContext.create(traceId: "trace2", spanId: "span2")

        let log1 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: context, trace: trace1)
        let log2 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: context, trace: trace2)

        // Then
        XCTAssertNotEqual(log1, log2, "Should not be equal with different trace")
    }

    func testEquatableWithNilValues() {
        let date = Date()

        // Given
        let log1 = FaroLog(
            timestamp: timestamp,
            dateTimestamp: date,
            level: .info,
            message: message,
            context: nil,
            trace: nil
        )

        let log2 = FaroLog(
            timestamp: timestamp,
            dateTimestamp: date,
            level: .info,
            message: message,
            context: nil,
            trace: nil
        )

        // Then
        XCTAssertEqual(log1, log2, "Should be equal with nil optional values")
    }

    func testEquatableWithMixedNilValues() {
        let date = Date()

        // Given
        let log1 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: context, trace: nil)
        let log2 = FaroLog(timestamp: timestamp, dateTimestamp: date, level: .info, message: message, context: nil, trace: trace)

        // Then
        XCTAssertNotEqual(log1, log2, "Should not be equal with mixed nil values")
    }
}
