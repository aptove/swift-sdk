import XCTest
@testable import ACPModel

internal final class ProtocolVersionTests: XCTestCase {
    func testInit() {
        let version = ProtocolVersion(version: 1)
        XCTAssertEqual(version.version, 1)
    }

    func testCurrentVersion() {
        let current = ProtocolVersion.current
        XCTAssertEqual(current.version, 1)
    }

    func testCodableRoundTrip() throws {
        let original = ProtocolVersion(version: 42)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProtocolVersion.self, from: encoded)

        XCTAssertEqual(original, decoded)
    }

    func testEncodesAsInt() throws {
        let version = ProtocolVersion(version: 1)
        let encoded = try JSONEncoder().encode(version)
        let jsonString = String(data: encoded, encoding: .utf8)

        XCTAssertEqual(jsonString, "1")
    }

    func testDecodesFromInt() throws {
        let json = Data("2".utf8)
        let version = try JSONDecoder().decode(ProtocolVersion.self, from: json)

        XCTAssertEqual(version.version, 2)
    }

    func testDescription() {
        let version = ProtocolVersion(version: 10)
        XCTAssertEqual(version.description, "10")
    }

    func testComparable() {
        let v1 = ProtocolVersion(version: 1)
        let v2 = ProtocolVersion(version: 2)
        let v3 = ProtocolVersion(version: 3)

        XCTAssertLessThan(v1, v2)
        XCTAssertLessThan(v2, v3)
        XCTAssertGreaterThan(v3, v1)
        XCTAssertEqual(v1, v1)
    }

    func testEquatable() {
        let v1a = ProtocolVersion(version: 1)
        let v1b = ProtocolVersion(version: 1)
        let v2 = ProtocolVersion(version: 2)

        XCTAssertEqual(v1a, v1b)
        XCTAssertNotEqual(v1a, v2)
    }

    func testHashable() {
        let v1 = ProtocolVersion(version: 1)
        let v2 = ProtocolVersion(version: 2)

        var set = Set<ProtocolVersion>()
        set.insert(v1)
        set.insert(v2)
        set.insert(v1) // Duplicate

        XCTAssertEqual(set.count, 2)
    }
}
