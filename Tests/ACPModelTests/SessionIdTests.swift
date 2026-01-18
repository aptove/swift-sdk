import XCTest
@testable import ACPModel

internal final class SessionIdTests: XCTestCase {
    func testInitWithValue() {
        let sessionId = SessionId(value: "test-session-123")
        XCTAssertEqual(sessionId.value, "test-session-123")
    }

    func testInitGeneratesUUID() {
        let sessionId1 = SessionId()
        let sessionId2 = SessionId()

        XCTAssertNotEqual(sessionId1.value, sessionId2.value)
        XCTAssertFalse(sessionId1.value.isEmpty)
    }

    func testCodableRoundTrip() throws {
        let original = SessionId(value: "session-abc-123")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SessionId.self, from: encoded)

        XCTAssertEqual(original, decoded)
    }

    func testEncodesAsString() throws {
        let sessionId = SessionId(value: "my-session")
        let encoded = try JSONEncoder().encode(sessionId)
        let jsonString = String(data: encoded, encoding: .utf8)

        XCTAssertEqual(jsonString, "\"my-session\"")
    }

    func testStringLiteralInit() {
        let sessionId: SessionId = "test-session"
        XCTAssertEqual(sessionId.value, "test-session")
    }

    func testHashable() {
        let sessionId1 = SessionId(value: "session-1")
        let sessionId2 = SessionId(value: "session-1")
        let sessionId3 = SessionId(value: "session-2")

        XCTAssertEqual(sessionId1, sessionId2)
        XCTAssertNotEqual(sessionId1, sessionId3)

        let set: Set<SessionId> = [sessionId1, sessionId2, sessionId3]
        XCTAssertEqual(set.count, 2)
    }

    func testDescription() {
        let sessionId = SessionId(value: "session-xyz")
        XCTAssertEqual(sessionId.description, "session-xyz")
    }
}
