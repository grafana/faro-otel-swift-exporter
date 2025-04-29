@testable import FaroOtelExporter
import XCTest

final class FaroTransportTests: XCTestCase {
    private var sut: FaroTransport!
    private var httpClient: MockFaroHttpClient!
    private var sessionManager: MockFaroSessionManager!
    private var endpointConfiguration: FaroEndpointConfiguration!

    override func setUp() {
        super.setUp()
        httpClient = MockFaroHttpClient()
        sessionManager = MockFaroSessionManager()
        endpointConfiguration = FaroEndpointConfiguration(
            collectorUrl: URL(string: "https://faro-collector.example.com/api/collect")!,
            apiKey: "test-api-key"
        )

        sut = FaroTransport(
            endpointConfiguration: endpointConfiguration,
            sessionManager: sessionManager,
            httpClient: httpClient,
            logger: MockFaroLogger(),
        )
    }

    override func tearDown() {
        sut = nil
        httpClient = nil
        sessionManager = nil
        endpointConfiguration = nil
        super.tearDown()
    }

    func testSendAddsCorrectHeaders() {
        // Given
        let payload = createTestPayload()

        // When
        let expectation = expectation(description: "Request sent")
        sut.send(payload) { _ in
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(httpClient.lastRequest?.url, endpointConfiguration.collectorUrl)
        XCTAssertEqual(httpClient.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(httpClient.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(httpClient.lastRequest?.value(forHTTPHeaderField: "x-api-key"), endpointConfiguration.apiKey)
        XCTAssertEqual(httpClient.lastRequest?.value(forHTTPHeaderField: "x-faro-session-id"), sessionManager.sessionId)
    }

    func testSendEncodesPayload() throws {
        // Given
        let payload = createTestPayload()

        // When
        let expectation = expectation(description: "Request sent")
        sut.send(payload) { _ in
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(httpClient.lastRequest?.httpBody)

        // Validate the JSON structure matches our expected payload
        if let data = httpClient.lastRequest?.httpBody {
            var expectedData: Data!
            XCTAssertNoThrow(expectedData = try JSONEncoder().encode(payload))

            // Convert both to dictionaries for comparison (order-independent)
            var actualObject: Any!
            var expectedObject: Any!
            XCTAssertNoThrow(actualObject = try JSONSerialization.jsonObject(with: data))
            XCTAssertNoThrow(expectedObject = try JSONSerialization.jsonObject(with: expectedData))

            let actualDict = try XCTUnwrap(actualObject as? [String: Any])
            let expectedDict = try XCTUnwrap(expectedObject as? [String: Any])

            // Compare top-level keys
            XCTAssertEqual(Set(actualDict.keys), Set(expectedDict.keys))
        }
    }

    func testSendCompletesSuccessfully() {
        // Given
        let payload = createTestPayload()
        httpClient.mockResponse = MockHttpResponse(
            data: nil,
            response: HTTPURLResponse(url: endpointConfiguration.collectorUrl, statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )

        // When
        let expectation = expectation(description: "Request completed")
        var receivedResult: Result<Void, Error>?
        sut.send(payload) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)

        switch receivedResult {
        case .success:
            // Expected success
            break
        case let .failure(error):
            XCTFail("Expected success but got error: \(error)")
        case nil:
            XCTFail("Expected a result but got nil")
        }
    }

    func testSendFailsWithNetworkError() {
        // Given
        let payload = createTestPayload()
        let expectedError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        httpClient.mockResponse = MockHttpResponse(data: nil, response: nil, error: expectedError)

        // When
        let expectation = expectation(description: "Request completed")
        var receivedResult: Result<Void, Error>?
        sut.send(payload) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)

        switch receivedResult {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(error):
            guard case let FaroTransportError.networkError(underlyingError) = error else {
                XCTFail("Expected networkError but got \(error)")
                return
            }
            XCTAssertEqual(underlyingError as NSError, expectedError)
        case nil:
            XCTFail("Expected a result but got nil")
        }
    }

    func testSendFailsWithHttpError() {
        // Given
        let payload = createTestPayload()
        let responseData = Data("Error message".utf8)
        httpClient.mockResponse = MockHttpResponse(
            data: responseData,
            response: HTTPURLResponse(url: endpointConfiguration.collectorUrl, statusCode: 400, httpVersion: nil, headerFields: nil),
            error: nil
        )

        // When
        let expectation = expectation(description: "Request completed")
        var receivedResult: Result<Void, Error>?
        sut.send(payload) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)

        switch receivedResult {
        case .success:
            XCTFail("Expected failure but got success")
        case let .failure(error):
            guard case let FaroTransportError.httpError(statusCode, message) = error else {
                XCTFail("Expected httpError but got \(error)")
                return
            }
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(message, "Error message")
        case nil:
            XCTFail("Expected a result but got nil")
        }
    }

    // MARK: - Helpers

    private func createTestPayload() -> FaroPayload {
        FaroPayload(
            meta: FaroMeta(
                sdk: FaroSdkInfo(name: "test-sdk", version: "1.0.0", integrations: []),
                app: FaroAppInfo(
                    name: "test-app",
                    namespace: "com.example",
                    version: "1.0.0",
                    environment: "test",
                    bundleId: "com.example.app",
                    release: "123"
                ),
                session: FaroSession(id: "test-session", attributes: [:]),
                user: FaroUser(id: "test-user", username: "user", email: "user@example.com", attributes: [:]),
                view: FaroView(name: "test-view")
            ),
            logs: [
                FaroLog(
                    timestamp: "2023-01-01T00:00:00Z",
                    dateTimestamp: Date(),
                    level: .info,
                    message: "Test log",
                    context: nil,
                    trace: nil
                ),
            ]
        )
    }
}
