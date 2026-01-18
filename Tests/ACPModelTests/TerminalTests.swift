import XCTest
@testable import ACPModel

/// Tests for Terminal request/response types.
internal final class TerminalTests: XCTestCase {

    // MARK: - CreateTerminalRequest Tests

    func testCreateTerminalRequestEncoding() throws {
        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "/bin/bash",
            args: ["-c", "echo hello"],
            cwd: "/tmp",
            env: [EnvVariable(name: "PATH", value: "/usr/bin")],
            outputByteLimit: 1024
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-1")
        XCTAssertEqual(json?["command"] as? String, "/bin/bash")
        XCTAssertEqual(json?["args"] as? [String], ["-c", "echo hello"])
        XCTAssertEqual(json?["cwd"] as? String, "/tmp")
        XCTAssertEqual(json?["outputByteLimit"] as? UInt64, 1024)
    }

    func testCreateTerminalRequestDecoding() throws {
        let json = """
        {
            "sessionId": "session-1",
            "command": "/bin/bash",
            "args": ["-c", "ls"],
            "cwd": "/home",
            "env": [{"name": "HOME", "value": "/home/user"}],
            "outputByteLimit": 2048
        }
        """

        let request = try JSONDecoder().decode(CreateTerminalRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "session-1")
        XCTAssertEqual(request.command, "/bin/bash")
        XCTAssertEqual(request.args, ["-c", "ls"])
        XCTAssertEqual(request.cwd, "/home")
        XCTAssertEqual(request.env.first?.name, "HOME")
        XCTAssertEqual(request.outputByteLimit, 2048)
    }

    func testCreateTerminalRequestMinimal() throws {
        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "ls"
        )

        XCTAssertEqual(request.args, [])
        XCTAssertNil(request.cwd)
        XCTAssertEqual(request.env, [])
        XCTAssertNil(request.outputByteLimit)
    }

    // MARK: - CreateTerminalResponse Tests

    func testCreateTerminalResponseEncoding() throws {
        let response = CreateTerminalResponse(terminalId: "term-123")

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["terminalId"] as? String, "term-123")
    }

    func testCreateTerminalResponseDecoding() throws {
        let json = """
        {"terminalId": "term-abc"}
        """

        let response = try JSONDecoder().decode(CreateTerminalResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.terminalId, "term-abc")
    }

    // MARK: - TerminalOutputRequest Tests

    func testTerminalOutputRequestRoundTrip() throws {
        let request = TerminalOutputRequest(
            sessionId: SessionId("session-1"),
            terminalId: "term-123"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(TerminalOutputRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, "session-1")
        XCTAssertEqual(decoded.terminalId, "term-123")
    }

    // MARK: - TerminalOutputResponse Tests

    func testTerminalOutputResponseWithExit() throws {
        let response = TerminalOutputResponse(
            output: "Hello, World!\n",
            truncated: false,
            exitStatus: TerminalExitStatus(exitCode: 0)
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(TerminalOutputResponse.self, from: data)

        XCTAssertEqual(decoded.output, "Hello, World!\n")
        XCTAssertFalse(decoded.truncated)
        XCTAssertEqual(decoded.exitStatus?.exitCode, 0)
    }

    func testTerminalOutputResponseTruncated() throws {
        let response = TerminalOutputResponse(
            output: "Truncated output...",
            truncated: true,
            exitStatus: nil
        )

        XCTAssertTrue(response.truncated)
        XCTAssertNil(response.exitStatus)
    }

    // MARK: - ReleaseTerminalRequest Tests

    func testReleaseTerminalRequestRoundTrip() throws {
        let request = ReleaseTerminalRequest(
            sessionId: SessionId("session-1"),
            terminalId: "term-123"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ReleaseTerminalRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, "session-1")
        XCTAssertEqual(decoded.terminalId, "term-123")
    }

    // MARK: - ReleaseTerminalResponse Tests

    func testReleaseTerminalResponseRoundTrip() throws {
        let response = ReleaseTerminalResponse()

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ReleaseTerminalResponse.self, from: data)

        XCTAssertNil(decoded._meta)
    }

    // MARK: - WaitForTerminalExitRequest Tests

    func testWaitForTerminalExitRequestRoundTrip() throws {
        let request = WaitForTerminalExitRequest(
            sessionId: SessionId("session-1"),
            terminalId: "term-123"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(WaitForTerminalExitRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, "session-1")
        XCTAssertEqual(decoded.terminalId, "term-123")
    }

    // MARK: - WaitForTerminalExitResponse Tests

    func testWaitForTerminalExitResponseWithExitCode() throws {
        let response = WaitForTerminalExitResponse(exitCode: 0)

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(WaitForTerminalExitResponse.self, from: data)

        XCTAssertEqual(decoded.exitCode, 0)
        XCTAssertNil(decoded.signal)
    }

    func testWaitForTerminalExitResponseWithSignal() throws {
        let response = WaitForTerminalExitResponse(signal: "SIGKILL")

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(WaitForTerminalExitResponse.self, from: data)

        XCTAssertNil(decoded.exitCode)
        XCTAssertEqual(decoded.signal, "SIGKILL")
    }

    // MARK: - KillTerminalCommandRequest Tests

    func testKillTerminalCommandRequestRoundTrip() throws {
        let request = KillTerminalCommandRequest(
            sessionId: SessionId("session-1"),
            terminalId: "term-123"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(KillTerminalCommandRequest.self, from: data)

        XCTAssertEqual(decoded.sessionId.value, "session-1")
        XCTAssertEqual(decoded.terminalId, "term-123")
    }

    // MARK: - KillTerminalCommandResponse Tests

    func testKillTerminalCommandResponseRoundTrip() throws {
        let response = KillTerminalCommandResponse()

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(KillTerminalCommandResponse.self, from: data)

        XCTAssertNil(decoded._meta)
    }

    // MARK: - TerminalExitStatus Tests

    func testTerminalExitStatusWithExitCode() throws {
        let status = TerminalExitStatus(exitCode: 127)

        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(TerminalExitStatus.self, from: data)

        XCTAssertEqual(decoded.exitCode, 127)
        XCTAssertNil(decoded.signal)
    }

    func testTerminalExitStatusWithSignal() throws {
        let status = TerminalExitStatus(signal: "SIGTERM")

        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(TerminalExitStatus.self, from: data)

        XCTAssertNil(decoded.exitCode)
        XCTAssertEqual(decoded.signal, "SIGTERM")
    }

    func testTerminalExitStatusHashable() {
        let status1 = TerminalExitStatus(exitCode: 0)
        let status2 = TerminalExitStatus(exitCode: 0)
        let status3 = TerminalExitStatus(exitCode: 1)

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)

        let set: Set<TerminalExitStatus> = [status1, status2, status3]
        XCTAssertEqual(set.count, 2)
    }
}
