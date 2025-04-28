@testable import FaroOtelExporter
import XCTest

final class FaroSessionManagerFactoryTests: XCTestCase {
    func testGetInstanceReturnsSameInstance() {
        // When
        let instance1 = FaroSessionManagerFactory.getInstance()
        let instance2 = FaroSessionManagerFactory.getInstance()

        // Then
        XCTAssertTrue(instance1 === instance2, "Factory should return the same instance")
    }

    func testGetInstanceWithCustomProvidersReturnsSameInstance() {
        // Given
        let mockDateProvider = MockDateProvider()
        let mockDeviceAttributesProvider = MockDeviceAttributesProvider()

        // When
        let instance1 = FaroSessionManagerFactory.getInstance(
            dateProvider: mockDateProvider,
            deviceAttributesProvider: mockDeviceAttributesProvider
        )
        let instance2 = FaroSessionManagerFactory.getInstance() // Default providers

        // Then
        XCTAssertTrue(instance1 === instance2, "Factory should return the same instance regardless of provider arguments")
    }
}
