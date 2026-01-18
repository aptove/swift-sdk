import XCTest
@testable import ACPHTTP

final class ACPHTTPTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(ACPHTTP.version, "1.0.0")
    }
}
