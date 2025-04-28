@testable import FaroOtelExporter
import XCTest

final class FaroPayloadTests: XCTestCase {
    func testFaroPayloadEncoding() throws {
        // Given
        let payload = createTestPayload()
        let expectedJsonString = createExpectedJsonString()

        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Keep for readability if debugging output
        let actualJsonData = try encoder.encode(payload)

        // Then
        try assertJsonDataEqualsJsonString(actualJsonData, expectedJsonString)
    }

    // MARK: - Helpers

    private func createTestPayload() -> FaroPayload {
        let sdk = FaroSdkInfo(
            name: "test-sdk",
            version: "1.0.0",
            integrations: [FaroIntegration(name: "test-integration", version: "1.0.0")]
        )

        let app = FaroAppInfo(
            name: "TestApp",
            namespace: "com.test",
            version: "1.0.0",
            environment: "test",
            bundleId: "com.test.app",
            release: "1.0.0"
        )

        let session = FaroSession(
            id: "test-session",
            attributes: ["test": "value"]
        )

        let user = FaroUser(
            id: "test-user",
            username: "test user",
            email: "test@example.com",
            attributes: ["test": "value"]
        )

        let view = FaroView(name: "TestView")

        let meta = FaroMeta(
            sdk: sdk,
            app: app,
            session: session,
            user: user,
            view: view
        )

        let log = FaroLog(
            timestamp: "2024-03-20T10:00:00Z",
            dateTimestamp: Date(), // Note: Date() might make test flaky if exact time matters
            level: .info,
            message: "Test log message",
            context: ["context": "test"],
            trace: nil
        )

        return FaroPayload(
            meta: meta,
            logs: [log]
        )
    }

    private func createExpectedJsonString() -> String {
        """
        {
          "meta": {
            "sdk": {
              "name": "test-sdk",
              "version": "1.0.0",
              "integrations": [
                {
                  "name": "test-integration",
                  "version": "1.0.0"
                }
              ]
            },
            "app": {
              "name": "TestApp",
              "namespace": "com.test",
              "version": "1.0.0",
              "environment": "test",
              "bundleId": "com.test.app",
              "release": "1.0.0"
            },
            "session": {
              "id": "test-session",
              "attributes": {
                "test": "value"
              }
            },
            "user": {
              "id": "test-user",
              "username": "test user",
              "email": "test@example.com",
              "attributes": {
                "test": "value"
              }
            },
            "view": {
              "name": "TestView"
            }
          },
          "logs": [
            {
              "timestamp": "2024-03-20T10:00:00Z",
              "level": "info",
              "message": "Test log message",
              "context": {
                "context": "test"
              }
            }
          ]
        }
        """
    }

    private func assertJsonDataEqualsJsonString(_ actualData: Data, _ expectedJsonString: String, file: StaticString = #filePath, line: UInt = #line) throws {
        // Convert expected string to Data and then both to dictionaries for comparison
        let expectedJsonData = try XCTUnwrap(expectedJsonString.data(using: .utf8), file: file, line: line)

        let actualObject = try JSONSerialization.jsonObject(with: actualData)
        let expectedObject = try JSONSerialization.jsonObject(with: expectedJsonData)

        let actualDict = try XCTUnwrap(actualObject as? [String: Any], "Actual JSON data did not deserialize to a Dictionary", file: file, line: line)
        let expectedDict = try XCTUnwrap(expectedObject as? [String: Any], "Expected JSON string did not deserialize to a Dictionary", file: file, line: line)

        XCTAssertEqual(NSDictionary(dictionary: actualDict), NSDictionary(dictionary: expectedDict), file: file, line: line)
    }
}
