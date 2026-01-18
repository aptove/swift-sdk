import XCTest
@testable import ACPModel

final class ACPModelTests: XCTestCase {
    func testSchemaVersion() {
        XCTAssertEqual(ACPModel.schemaVersion, "0.9.1")
    }
    
    func testSDKVersion() {
        XCTAssertEqual(ACPModel.sdkVersion, "1.0.0")
    }
}
