import XCTest
@testable import ACPHTTP

internal final class ACPHTTPTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(ACPHTTP.version, "1.0.0")
    }
}
