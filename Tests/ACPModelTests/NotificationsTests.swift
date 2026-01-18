import XCTest
@testable import ACPModel

/// Tests for Notification types.
internal final class NotificationsTests: XCTestCase {

    // MARK: - CancelNotification Tests

    func testCancelNotificationEncoding() throws {
        let notification = CancelNotification(sessionId: SessionId("session-1"))

        let data = try JSONEncoder().encode(notification)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-1")
    }

    func testCancelNotificationDecoding() throws {
        let json = """
        {"sessionId": "session-1"}
        """

        let notification = try JSONDecoder().decode(CancelNotification.self, from: Data(json.utf8))

        XCTAssertEqual(notification.sessionId.value, "session-1")
    }

    func testCancelNotificationRoundTrip() throws {
        let notification = CancelNotification(sessionId: SessionId("session-1"))

        let data = try JSONEncoder().encode(notification)
        let decoded = try JSONDecoder().decode(CancelNotification.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, notification.sessionId.value)
    }

    // MARK: - SessionNotification Tests

    func testSessionNotificationEncoding() throws {
        let textContent = TextContent(text: "Hello")
        let update = SessionUpdate.userMessageChunk(
            UserMessageChunk(content: .text(textContent))
        )
        let notification = SessionNotification(
            sessionId: SessionId("session-1"),
            update: update
        )

        let data = try JSONEncoder().encode(notification)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-1")
        XCTAssertNotNil(json?["update"])
    }

    func testSessionNotificationDecoding() throws {
        let json = """
        {
            "sessionId": "session-1",
            "update": {
                "sessionUpdate": "user_message_chunk",
                "content": {"type": "text", "text": "Hello"}
            }
        }
        """

        let notification = try JSONDecoder().decode(SessionNotification.self, from: Data(json.utf8))

        XCTAssertEqual(notification.sessionId.value, "session-1")
        if case .userMessageChunk(let chunk) = notification.update {
            if case .text(let text) = chunk.content {
                XCTAssertEqual(text.text, "Hello")
            } else {
                XCTFail("Expected text content")
            }
        } else {
            XCTFail("Expected userMessageChunk")
        }
    }

    func testSessionNotificationRoundTrip() throws {
        let textContent = TextContent(text: "Response")
        let update = SessionUpdate.agentMessageChunk(
            AgentMessageChunk(content: .text(textContent))
        )
        let notification = SessionNotification(
            sessionId: SessionId("session-1"),
            update: update
        )

        let data = try JSONEncoder().encode(notification)
        let decoded = try JSONDecoder().decode(SessionNotification.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, notification.sessionId.value)
    }

    // MARK: - CancelRequestNotification Tests

    func testCancelRequestNotificationEncoding() throws {
        let notification = CancelRequestNotification(
            requestId: RequestId.int(42),
            message: "User cancelled"
        )

        let data = try JSONEncoder().encode(notification)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["requestId"] as? Int, 42)
        XCTAssertEqual(json?["message"] as? String, "User cancelled")
    }

    func testCancelRequestNotificationDecoding() throws {
        let json = """
        {"requestId": 123, "message": "Timeout"}
        """

        let notification = try JSONDecoder().decode(CancelRequestNotification.self, from: Data(json.utf8))

        XCTAssertEqual(notification.requestId, .int(123))
        XCTAssertEqual(notification.message, "Timeout")
    }

    func testCancelRequestNotificationMinimal() throws {
        let notification = CancelRequestNotification(requestId: RequestId.string("req-1"))

        XCTAssertNil(notification.message)
        XCTAssertNil(notification._meta)
    }

    func testCancelRequestNotificationRoundTrip() throws {
        let notification = CancelRequestNotification(
            requestId: RequestId.int(99),
            message: "Aborted"
        )

        let data = try JSONEncoder().encode(notification)
        let decoded = try JSONDecoder().decode(CancelRequestNotification.self, from: data)

        XCTAssertEqual(decoded.requestId, notification.requestId)
        XCTAssertEqual(decoded.message, notification.message)
    }

    // MARK: - Hashable Tests

    func testCancelNotificationHashable() {
        let n1 = CancelNotification(sessionId: SessionId("session-1"))
        let n2 = CancelNotification(sessionId: SessionId("session-1"))
        let n3 = CancelNotification(sessionId: SessionId("session-2"))

        XCTAssertEqual(n1, n2)
        XCTAssertNotEqual(n1, n3)

        let set: Set<CancelNotification> = [n1, n2, n3]
        XCTAssertEqual(set.count, 2)
    }

    func testCancelRequestNotificationHashable() {
        let n1 = CancelRequestNotification(requestId: RequestId.int(1))
        let n2 = CancelRequestNotification(requestId: RequestId.int(1))
        let n3 = CancelRequestNotification(requestId: RequestId.int(2))

        XCTAssertEqual(n1, n2)
        XCTAssertNotEqual(n1, n3)
    }

    // MARK: - Protocol Conformance Tests

    func testCancelNotificationProtocolConformance() {
        let notification = CancelNotification(sessionId: SessionId("session-1"))

        // AcpWithSessionId
        XCTAssertEqual(notification.sessionId.value, "session-1")

        // AcpWithMeta
        XCTAssertNil(notification._meta)
    }

    func testSessionNotificationProtocolConformance() {
        let notification = SessionNotification(
            sessionId: SessionId("session-1"),
            update: .sessionInfoUpdate(SessionInfoUpdate())
        )

        // AcpWithSessionId
        XCTAssertEqual(notification.sessionId.value, "session-1")

        // AcpWithMeta
        XCTAssertNil(notification._meta)
    }
}
