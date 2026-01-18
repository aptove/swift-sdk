import XCTest
@testable import ACP

final class ACPTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(ACP.version, "1.0.0")
    }
}
