import XCTest
@testable import ACPModel

/// Tests for Session Mode request/response types.
internal final class SessionModeMessagesTests: XCTestCase {

    // MARK: - SetSessionModeRequest Tests

    func testSetSessionModeRequestEncoding() throws {
        let request = SetSessionModeRequest(
            sessionId: SessionId("session-1"),
            modeId: SessionModeId("agent")
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-1")
        XCTAssertEqual(json?["modeId"] as? String, "agent")
    }

    func testSetSessionModeRequestDecoding() throws {
        let json = """
        {
            "sessionId": "session-1",
            "modeId": "chat"
        }
        """

        let request = try JSONDecoder().decode(SetSessionModeRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "session-1")
        XCTAssertEqual(request.modeId.value, "chat")
    }

    func testSetSessionModeRequestRoundTrip() throws {
        let request = SetSessionModeRequest(
            sessionId: SessionId("session-1"),
            modeId: SessionModeId("planning")
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(SetSessionModeRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, request.sessionId.value)
        XCTAssertEqual(decoded.modeId.value, request.modeId.value)
    }

    // MARK: - SetSessionModeResponse Tests

    func testSetSessionModeResponseEncoding() throws {
        let response = SetSessionModeResponse()

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
    }

    func testSetSessionModeResponseDecoding() throws {
        let json = "{}"

        let response = try JSONDecoder().decode(SetSessionModeResponse.self, from: Data(json.utf8))

        XCTAssertNil(response._meta)
    }

    func testSetSessionModeResponseRoundTrip() throws {
        let response = SetSessionModeResponse()

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(SetSessionModeResponse.self, from: data)

        XCTAssertNil(decoded._meta)
    }

    // MARK: - Hashable Tests

    func testSetSessionModeRequestHashable() {
        let req1 = SetSessionModeRequest(
            sessionId: SessionId("session-1"),
            modeId: SessionModeId("agent")
        )
        let req2 = SetSessionModeRequest(
            sessionId: SessionId("session-1"),
            modeId: SessionModeId("agent")
        )
        let req3 = SetSessionModeRequest(
            sessionId: SessionId("session-1"),
            modeId: SessionModeId("chat")
        )

        XCTAssertEqual(req1, req2)
        XCTAssertNotEqual(req1, req3)

        let set: Set<SetSessionModeRequest> = [req1, req2, req3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Protocol Conformance Tests

    func testSetSessionModeRequestProtocolConformance() {
        let request = SetSessionModeRequest(
            sessionId: SessionId("session-1"),
            modeId: SessionModeId("agent")
        )

        // AcpWithSessionId
        XCTAssertEqual(request.sessionId.value, "session-1")

        // AcpWithMeta
        XCTAssertNil(request._meta)
    }
}
