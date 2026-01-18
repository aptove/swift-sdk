import XCTest
@testable import ACPModel

/// Tests for File System request/response types.
internal final class FileMessagesTests: XCTestCase {

    // MARK: - ReadTextFileRequest Tests

    func testReadTextFileRequestEncoding() throws {
        let request = ReadTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/to/file.txt",
            line: 10,
            limit: 100
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-1")
        XCTAssertEqual(json?["path"] as? String, "/path/to/file.txt")
        XCTAssertEqual(json?["line"] as? UInt32, 10)
        XCTAssertEqual(json?["limit"] as? UInt32, 100)
    }

    func testReadTextFileRequestDecoding() throws {
        let json = """
        {
            "sessionId": "session-1",
            "path": "/etc/hosts",
            "line": 5,
            "limit": 50
        }
        """

        let request = try JSONDecoder().decode(ReadTextFileRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "session-1")
        XCTAssertEqual(request.path, "/etc/hosts")
        XCTAssertEqual(request.line, 5)
        XCTAssertEqual(request.limit, 50)
    }

    func testReadTextFileRequestMinimal() throws {
        let request = ReadTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/to/file.txt"
        )

        XCTAssertNil(request.line)
        XCTAssertNil(request.limit)
        XCTAssertNil(request._meta)
    }

    func testReadTextFileRequestRoundTrip() throws {
        let request = ReadTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/to/file.txt",
            line: 1,
            limit: 1000
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ReadTextFileRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, request.sessionId.value)
        XCTAssertEqual(decoded.path, request.path)
        XCTAssertEqual(decoded.line, request.line)
        XCTAssertEqual(decoded.limit, request.limit)
    }

    // MARK: - ReadTextFileResponse Tests

    func testReadTextFileResponseEncoding() throws {
        let response = ReadTextFileResponse(content: "Hello, World!")

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["content"] as? String, "Hello, World!")
    }

    func testReadTextFileResponseDecoding() throws {
        let json = """
        {"content": "File contents here"}
        """

        let response = try JSONDecoder().decode(ReadTextFileResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.content, "File contents here")
    }

    func testReadTextFileResponseRoundTrip() throws {
        let response = ReadTextFileResponse(content: "Multi\nline\ncontent")

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ReadTextFileResponse.self, from: data)

        XCTAssertEqual(decoded.content, "Multi\nline\ncontent")
    }

    // MARK: - WriteTextFileRequest Tests

    func testWriteTextFileRequestEncoding() throws {
        let request = WriteTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/to/output.txt",
            content: "New content"
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-1")
        XCTAssertEqual(json?["path"] as? String, "/path/to/output.txt")
        XCTAssertEqual(json?["content"] as? String, "New content")
    }

    func testWriteTextFileRequestDecoding() throws {
        let json = """
        {
            "sessionId": "session-1",
            "path": "/tmp/test.txt",
            "content": "Test content"
        }
        """

        let request = try JSONDecoder().decode(WriteTextFileRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "session-1")
        XCTAssertEqual(request.path, "/tmp/test.txt")
        XCTAssertEqual(request.content, "Test content")
    }

    func testWriteTextFileRequestRoundTrip() throws {
        let request = WriteTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/to/file.txt",
            content: "Content with\nnewlines"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(WriteTextFileRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, request.sessionId.value)
        XCTAssertEqual(decoded.path, request.path)
        XCTAssertEqual(decoded.content, request.content)
    }

    // MARK: - WriteTextFileResponse Tests

    func testWriteTextFileResponseEncoding() throws {
        let response = WriteTextFileResponse()

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Empty response should encode to empty object or just _meta
        XCTAssertNotNil(json)
    }

    func testWriteTextFileResponseDecoding() throws {
        let json = "{}"

        let response = try JSONDecoder().decode(WriteTextFileResponse.self, from: Data(json.utf8))

        XCTAssertNil(response._meta)
    }

    func testWriteTextFileResponseRoundTrip() throws {
        let response = WriteTextFileResponse()

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(WriteTextFileResponse.self, from: data)

        XCTAssertNil(decoded._meta)
    }

    // MARK: - Hashable Tests

    func testReadTextFileRequestHashable() {
        let request1 = ReadTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt"
        )
        let request2 = ReadTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt"
        )
        let request3 = ReadTextFileRequest(
            sessionId: SessionId("session-2"),
            path: "/path/file.txt"
        )

        XCTAssertEqual(request1, request2)
        XCTAssertNotEqual(request1, request3)

        let set: Set<ReadTextFileRequest> = [request1, request2, request3]
        XCTAssertEqual(set.count, 2)
    }

    func testWriteTextFileRequestHashable() {
        let request1 = WriteTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt",
            content: "content"
        )
        let request2 = WriteTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt",
            content: "content"
        )
        let request3 = WriteTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt",
            content: "different"
        )

        XCTAssertEqual(request1, request2)
        XCTAssertNotEqual(request1, request3)
    }

    // MARK: - Protocol Conformance Tests

    func testReadTextFileRequestProtocolConformance() {
        let request = ReadTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt"
        )

        // AcpWithSessionId
        XCTAssertEqual(request.sessionId.value, "session-1")

        // AcpWithMeta
        XCTAssertNil(request._meta)
    }

    func testWriteTextFileRequestProtocolConformance() {
        let request = WriteTextFileRequest(
            sessionId: SessionId("session-1"),
            path: "/path/file.txt",
            content: "content"
        )

        // AcpWithSessionId
        XCTAssertEqual(request.sessionId.value, "session-1")

        // AcpWithMeta
        XCTAssertNil(request._meta)
    }
}
