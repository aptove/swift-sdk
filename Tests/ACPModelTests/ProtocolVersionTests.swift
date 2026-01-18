import XCTest
@testable import ACPModel

final class ProtocolVersionTests: XCTestCase {
    func testInit() {
        let version = ProtocolVersion(major: 1, minor: 2, patch: 3)
        
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
    }
    
    func testInitFromString() {
        let version = ProtocolVersion(string: "2.5.7")
        
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 7)
    }
    
    func testInitFromInvalidString() {
        XCTAssertNil(ProtocolVersion(string: "1.2"))
        XCTAssertNil(ProtocolVersion(string: "1.2.3.4"))
        XCTAssertNil(ProtocolVersion(string: "abc"))
        XCTAssertNil(ProtocolVersion(string: ""))
    }
    
    func testCurrentVersion() {
        let current = ProtocolVersion.current
        
        XCTAssertEqual(current.major, 0)
        XCTAssertEqual(current.minor, 9)
        XCTAssertEqual(current.patch, 1)
    }
    
    func testCodableRoundTrip() throws {
        let original = ProtocolVersion(major: 3, minor: 14, patch: 159)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProtocolVersion.self, from: encoded)
        
        XCTAssertEqual(original, decoded)
    }
    
    func testEncodesAsString() throws {
        let version = ProtocolVersion(major: 1, minor: 0, patch: 0)
        let encoded = try JSONEncoder().encode(version)
        let jsonString = String(data: encoded, encoding: .utf8)
        
        XCTAssertEqual(jsonString, "\"1.0.0\"")
    }
    
    func testDecodesFromString() throws {
        let json = "\"2.3.4\"".data(using: .utf8)!
        let version = try JSONDecoder().decode(ProtocolVersion.self, from: json)
        
        XCTAssertEqual(version.major, 2)
        XCTAssertEqual(version.minor, 3)
        XCTAssertEqual(version.patch, 4)
    }
    
    func testDescription() {
        let version = ProtocolVersion(major: 10, minor: 20, patch: 30)
        XCTAssertEqual(version.description, "10.20.30")
    }
    
    func testComparable() {
        let v1_0_0 = ProtocolVersion(major: 1, minor: 0, patch: 0)
        let v1_0_1 = ProtocolVersion(major: 1, minor: 0, patch: 1)
        let v1_1_0 = ProtocolVersion(major: 1, minor: 1, patch: 0)
        let v2_0_0 = ProtocolVersion(major: 2, minor: 0, patch: 0)
        
        XCTAssertLessThan(v1_0_0, v1_0_1)
        XCTAssertLessThan(v1_0_1, v1_1_0)
        XCTAssertLessThan(v1_1_0, v2_0_0)
        
        XCTAssertGreaterThan(v2_0_0, v1_0_0)
        XCTAssertEqual(v1_0_0, v1_0_0)
    }
}
