import XCTest
@testable import ACPModel

/// Tests for unstable session operations: list, fork, and resume.
internal final class SessionOperationsTests: XCTestCase {

    // MARK: - SessionInfo Tests

    func testSessionInfoEncoding() throws {
        let info = SessionInfo(
            sessionId: SessionId("session-123"),
            cwd: "/home/user/project",
            title: "Test Session",
            updatedAt: "2024-01-15T10:30:00Z"
        )

        let data = try JSONEncoder().encode(info)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["sessionId"] as? String, "session-123")
        XCTAssertEqual(json["cwd"] as? String, "/home/user/project")
        XCTAssertEqual(json["title"] as? String, "Test Session")
        XCTAssertEqual(json["updatedAt"] as? String, "2024-01-15T10:30:00Z")
    }

    func testSessionInfoDecoding() throws {
        let json = """
        {
            "sessionId": "session-456",
            "cwd": "/workspace",
            "title": "My Session",
            "updatedAt": "2024-01-20T14:00:00Z"
        }
        """

        let info = try JSONDecoder().decode(SessionInfo.self, from: Data(json.utf8))

        XCTAssertEqual(info.sessionId.value, "session-456")
        XCTAssertEqual(info.cwd, "/workspace")
        XCTAssertEqual(info.title, "My Session")
        XCTAssertEqual(info.updatedAt, "2024-01-20T14:00:00Z")
    }

    func testSessionInfoMinimalDecoding() throws {
        let json = """
        {
            "sessionId": "session-minimal",
            "cwd": "/home"
        }
        """

        let info = try JSONDecoder().decode(SessionInfo.self, from: Data(json.utf8))

        XCTAssertEqual(info.sessionId.value, "session-minimal")
        XCTAssertEqual(info.cwd, "/home")
        XCTAssertNil(info.title)
        XCTAssertNil(info.updatedAt)
    }

    func testSessionInfoRoundTrip() throws {
        let info = SessionInfo(
            sessionId: SessionId("session-rt"),
            cwd: "/test/path",
            title: "Round Trip Test",
            updatedAt: "2024-02-01T08:00:00Z"
        )

        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(SessionInfo.self, from: data)

        XCTAssertEqual(decoded.sessionId, info.sessionId)
        XCTAssertEqual(decoded.cwd, info.cwd)
        XCTAssertEqual(decoded.title, info.title)
        XCTAssertEqual(decoded.updatedAt, info.updatedAt)
    }

    func testSessionInfoHashable() {
        let info1 = SessionInfo(sessionId: SessionId("session-1"), cwd: "/home")
        let info2 = SessionInfo(sessionId: SessionId("session-1"), cwd: "/home")
        let info3 = SessionInfo(sessionId: SessionId("session-2"), cwd: "/home")

        XCTAssertEqual(info1, info2)
        XCTAssertNotEqual(info1, info3)

        let set: Set<SessionInfo> = [info1, info2, info3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ListSessionsRequest Tests

    func testListSessionsRequestEncoding() throws {
        let request = ListSessionsRequest(cursor: "abc123", cwd: "/home")

        let data = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["cursor"] as? String, "abc123")
        XCTAssertEqual(json["cwd"] as? String, "/home")
    }

    func testListSessionsRequestDecoding() throws {
        let json = """
        {
            "cursor": "page-2",
            "cwd": "/workspace"
        }
        """

        let request = try JSONDecoder().decode(ListSessionsRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.cursor, "page-2")
        XCTAssertEqual(request.cwd, "/workspace")
    }

    func testListSessionsRequestEmptyDecoding() throws {
        let json = "{}"

        let request = try JSONDecoder().decode(ListSessionsRequest.self, from: Data(json.utf8))

        XCTAssertNil(request.cursor)
        XCTAssertNil(request.cwd)
    }

    func testListSessionsRequestRoundTrip() throws {
        let request = ListSessionsRequest(cursor: "test-cursor", cwd: "/test")

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ListSessionsRequest.self, from: data)

        XCTAssertEqual(decoded.cursor, request.cursor)
        XCTAssertEqual(decoded.cwd, request.cwd)
    }

    // MARK: - ListSessionsResponse Tests

    func testListSessionsResponseEncoding() throws {
        let response = ListSessionsResponse(
            sessions: [
                SessionInfo(sessionId: SessionId("session-1"), cwd: "/home", title: "First"),
                SessionInfo(sessionId: SessionId("session-2"), cwd: "/home", title: "Second")
            ],
            nextCursor: "next-page"
        )

        let data = try JSONEncoder().encode(response)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        let sessions = json["sessions"] as? [[String: Any]]
        XCTAssertEqual(sessions?.count, 2)
        XCTAssertEqual(json["nextCursor"] as? String, "next-page")
    }

    func testListSessionsResponseDecoding() throws {
        let json = """
        {
            "sessions": [
                {"sessionId": "s1", "cwd": "/home", "title": "Session 1"},
                {"sessionId": "s2", "cwd": "/home", "title": "Session 2"}
            ],
            "nextCursor": "cursor-123"
        }
        """

        let response = try JSONDecoder().decode(ListSessionsResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.sessions.count, 2)
        XCTAssertEqual(response.sessions[0].sessionId.value, "s1")
        XCTAssertEqual(response.sessions[1].title, "Session 2")
        XCTAssertEqual(response.nextCursor, "cursor-123")
    }

    func testListSessionsResponseEmptyDecoding() throws {
        let json = """
        {
            "sessions": []
        }
        """

        let response = try JSONDecoder().decode(ListSessionsResponse.self, from: Data(json.utf8))

        XCTAssertTrue(response.sessions.isEmpty)
        XCTAssertNil(response.nextCursor)
    }

    func testListSessionsResponseRoundTrip() throws {
        let response = ListSessionsResponse(
            sessions: [SessionInfo(sessionId: SessionId("rt-session"), cwd: "/home")],
            nextCursor: nil
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ListSessionsResponse.self, from: data)

        XCTAssertEqual(decoded.sessions.count, response.sessions.count)
        XCTAssertEqual(decoded.sessions[0].sessionId, response.sessions[0].sessionId)
        XCTAssertNil(decoded.nextCursor)
    }

    // MARK: - ForkSessionRequest Tests

    func testForkSessionRequestEncoding() throws {
        let request = ForkSessionRequest(
            sessionId: SessionId("parent-session"),
            cwd: "/home/user/project"
        )

        let data = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["sessionId"] as? String, "parent-session")
        XCTAssertEqual(json["cwd"] as? String, "/home/user/project")
    }

    func testForkSessionRequestDecoding() throws {
        let json = """
        {
            "sessionId": "fork-source",
            "cwd": "/workspace"
        }
        """

        let request = try JSONDecoder().decode(ForkSessionRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "fork-source")
        XCTAssertEqual(request.cwd, "/workspace")
    }

    func testForkSessionRequestRoundTrip() throws {
        let request = ForkSessionRequest(
            sessionId: SessionId("roundtrip-fork"),
            cwd: "/test/path"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ForkSessionRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId, request.sessionId)
        XCTAssertEqual(decoded.cwd, request.cwd)
    }

    func testForkSessionRequestHashable() {
        let req1 = ForkSessionRequest(sessionId: SessionId("session-1"), cwd: "/home")
        let req2 = ForkSessionRequest(sessionId: SessionId("session-1"), cwd: "/home")
        let req3 = ForkSessionRequest(sessionId: SessionId("session-2"), cwd: "/home")

        XCTAssertEqual(req1, req2)
        XCTAssertNotEqual(req1, req3)

        let set: Set<ForkSessionRequest> = [req1, req2, req3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ForkSessionResponse Tests

    func testForkSessionResponseEncoding() throws {
        let response = ForkSessionResponse(sessionId: SessionId("forked-session"))

        let data = try JSONEncoder().encode(response)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["sessionId"] as? String, "forked-session")
    }

    func testForkSessionResponseDecoding() throws {
        let json = """
        {
            "sessionId": "new-fork"
        }
        """

        let response = try JSONDecoder().decode(ForkSessionResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.sessionId.value, "new-fork")
    }

    func testForkSessionResponseWithConfigOptions() throws {
        let json = """
        {
            "sessionId": "fork-with-config",
            "configOptions": []
        }
        """

        let response = try JSONDecoder().decode(ForkSessionResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.sessionId.value, "fork-with-config")
        XCTAssertNotNil(response.configOptions)
    }

    func testForkSessionResponseRoundTrip() throws {
        let response = ForkSessionResponse(sessionId: SessionId("rt-fork"))

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ForkSessionResponse.self, from: data)

        XCTAssertEqual(decoded.sessionId, response.sessionId)
    }

    // MARK: - ResumeSessionRequest Tests

    func testResumeSessionRequestEncoding() throws {
        let request = ResumeSessionRequest(
            sessionId: SessionId("resume-session"),
            cwd: "/home/user"
        )

        let data = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["sessionId"] as? String, "resume-session")
        XCTAssertEqual(json["cwd"] as? String, "/home/user")
    }

    func testResumeSessionRequestDecoding() throws {
        let json = """
        {
            "sessionId": "session-to-resume",
            "cwd": "/workspace"
        }
        """

        let request = try JSONDecoder().decode(ResumeSessionRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "session-to-resume")
        XCTAssertEqual(request.cwd, "/workspace")
    }

    func testResumeSessionRequestRoundTrip() throws {
        let request = ResumeSessionRequest(
            sessionId: SessionId("roundtrip-resume"),
            cwd: "/test/path"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ResumeSessionRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId, request.sessionId)
        XCTAssertEqual(decoded.cwd, request.cwd)
    }

    func testResumeSessionRequestHashable() {
        let req1 = ResumeSessionRequest(sessionId: SessionId("session-1"), cwd: "/home")
        let req2 = ResumeSessionRequest(sessionId: SessionId("session-1"), cwd: "/home")
        let req3 = ResumeSessionRequest(sessionId: SessionId("session-2"), cwd: "/home")

        XCTAssertEqual(req1, req2)
        XCTAssertNotEqual(req1, req3)

        let set: Set<ResumeSessionRequest> = [req1, req2, req3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ResumeSessionResponse Tests

    func testResumeSessionResponseEncoding() throws {
        let response = ResumeSessionResponse()

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
    }

    func testResumeSessionResponseDecoding() throws {
        let json = "{}"

        let response = try JSONDecoder().decode(ResumeSessionResponse.self, from: Data(json.utf8))

        XCTAssertNil(response.configOptions)
        XCTAssertNil(response.models)
        XCTAssertNil(response.modes)
    }

    func testResumeSessionResponseWithConfigOptions() throws {
        let json = """
        {
            "configOptions": []
        }
        """

        let response = try JSONDecoder().decode(ResumeSessionResponse.self, from: Data(json.utf8))

        XCTAssertNotNil(response.configOptions)
    }

    func testResumeSessionResponseRoundTrip() throws {
        let response = ResumeSessionResponse()

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ResumeSessionResponse.self, from: data)

        XCTAssertNil(decoded.configOptions)
    }
}
