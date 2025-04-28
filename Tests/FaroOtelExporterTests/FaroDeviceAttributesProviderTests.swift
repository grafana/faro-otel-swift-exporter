@testable import FaroOtelExporter
import Foundation
import XCTest

final class FaroDeviceAttributesProviderTests: XCTestCase {
    func testGetDeviceAttributesWithCustomValues() {
        // Given
        let source = MockDeviceInformationSource(
            osName: "macOS",
            osVersion: "14.0",
            deviceBrand: "MacBook",
            deviceModel: "MacBookPro18,1",
            isPhysical: false,
            deviceId: "12345"
        )
        let provider = FaroDeviceAttributesProvider(source: source)

        // When
        let attributes = provider.getDeviceAttributes()

        // Then
        XCTAssertEqual(attributes["device_manufacturer"], "apple")
        XCTAssertEqual(attributes["device_os"], "macOS")
        XCTAssertEqual(attributes["device_os_version"], "14.0")
        XCTAssertEqual(attributes["device_os_detail"], "macOS 14.0")
        XCTAssertEqual(attributes["device_brand"], "MacBook")
        XCTAssertEqual(attributes["device_model"], "MacBookPro18,1")
        XCTAssertEqual(attributes["device_id"], "12345")
        XCTAssertEqual(attributes["device_is_physical"], "false")
    }

    func testGetDeviceAttributesContainsAllRequiredKeys() {
        // Given
        let source = MockDeviceInformationSource(
            osName: "macOS",
            osVersion: "14.0",
            deviceBrand: "MacBook",
            deviceModel: "MacBookPro18,1",
            isPhysical: false,
            deviceId: "12345"
        )
        let provider = FaroDeviceAttributesProvider(source: source)

        // When
        let attributes = provider.getDeviceAttributes()

        // Then
        let requiredKeys = [
            "device_manufacturer",
            "device_os",
            "device_os_version",
            "device_os_detail",
            "device_brand",
            "device_model",
            "device_id",
            "device_is_physical",
        ]

        for key in requiredKeys {
            XCTAssertNotNil(attributes[key], "Missing required key: \(key)")
        }
    }
}
