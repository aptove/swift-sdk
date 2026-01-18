import XCTest
@testable import ACP
@testable import ACPModel
import Foundation

/// Tests for FileSystemOperations and TerminalOperations protocols.
internal final class OperationsTests: XCTestCase {

    // MARK: - FileSystemOperations Tests

    /// A test client that implements FileSystemOperations
    private final class TestFileSystemClient: FileSystemOperations, @unchecked Sendable {
        var files: [String: String] = [:]

        func fsReadTextFile(
            sessionId: SessionId,
            path: String,
            line: UInt32?,
            limit: UInt32?,
            meta: MetaField?
        ) async throws -> ReadTextFileResponse {
            guard let content = files[path] else {
                throw ClientError.requestFailed("File not found: \(path)")
            }
            return ReadTextFileResponse(content: content)
        }

        func fsWriteTextFile(
            sessionId: SessionId,
            path: String,
            content: String,
            meta: MetaField?
        ) async throws -> WriteTextFileResponse {
            files[path] = content
            return WriteTextFileResponse()
        }
    }

    func testFileSystemOperationsReadFile() async throws {
        let client = TestFileSystemClient()
        client.files["/test.txt"] = "Hello, World!"

        let response = try await client.fsReadTextFile(
            sessionId: SessionId("session-1"),
            path: "/test.txt",
            line: nil,
            limit: nil,
            meta: nil
        )

        XCTAssertEqual(response.content, "Hello, World!")
    }

    func testFileSystemOperationsWriteFile() async throws {
        let client = TestFileSystemClient()

        _ = try await client.fsWriteTextFile(
            sessionId: SessionId("session-1"),
            path: "/output.txt",
            content: "New content",
            meta: nil
        )

        XCTAssertEqual(client.files["/output.txt"], "New content")
    }

    func testFileSystemOperationsReadNonExistent() async {
        let client = TestFileSystemClient()

        do {
            _ = try await client.fsReadTextFile(
                sessionId: SessionId("session-1"),
                path: "/nonexistent.txt",
                line: nil,
                limit: nil,
                meta: nil
            )
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    // MARK: - Default Implementation Tests

    /// A client that uses default FileSystemOperations (not implemented)
    private struct DefaultFileSystemClient: FileSystemOperations {
    }

    func testDefaultReadTextFileThrows() async {
        let client = DefaultFileSystemClient()

        do {
            _ = try await client.fsReadTextFile(
                sessionId: SessionId("session-1"),
                path: "/test.txt",
                line: nil,
                limit: nil,
                meta: nil
            )
            XCTFail("Expected error")
        } catch let error as ClientError {
            XCTAssertTrue(error.errorDescription?.contains("notImplemented") == true ||
                          error.errorDescription?.contains("fsReadTextFile") == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDefaultWriteTextFileThrows() async {
        let client = DefaultFileSystemClient()

        do {
            _ = try await client.fsWriteTextFile(
                sessionId: SessionId("session-1"),
                path: "/test.txt",
                content: "content",
                meta: nil
            )
            XCTFail("Expected error")
        } catch let error as ClientError {
            XCTAssertTrue(error.errorDescription?.contains("notImplemented") == true ||
                          error.errorDescription?.contains("fsWriteTextFile") == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - TerminalOperations Tests

    /// Terminal state storage for tests
    private struct TerminalState {
        var command: String
        var output: String
        var exited: Bool
    }

    /// A test client that implements TerminalOperations
    private final class TestTerminalClient: TerminalOperations, @unchecked Sendable {
        var terminals: [String: TerminalState] = [:]
        private var nextId = 1

        func terminalCreate(request: CreateTerminalRequest) async throws -> CreateTerminalResponse {
            let terminalId = "term-\(nextId)"
            nextId += 1
            terminals[terminalId] = TerminalState(command: request.command, output: "", exited: false)
            return CreateTerminalResponse(terminalId: terminalId)
        }

        func terminalOutput(
            sessionId: SessionId,
            terminalId: String,
            meta: MetaField?
        ) async throws -> TerminalOutputResponse {
            guard let terminal = terminals[terminalId] else {
                throw ClientError.requestFailed("Terminal not found: \(terminalId)")
            }
            return TerminalOutputResponse(
                output: terminal.output,
                truncated: false,
                exitStatus: terminal.exited ? TerminalExitStatus(exitCode: 0) : nil
            )
        }

        func terminalRelease(
            sessionId: SessionId,
            terminalId: String,
            meta: MetaField?
        ) async throws -> ReleaseTerminalResponse {
            terminals.removeValue(forKey: terminalId)
            return ReleaseTerminalResponse()
        }

        func terminalWaitForExit(
            sessionId: SessionId,
            terminalId: String,
            meta: MetaField?
        ) async throws -> WaitForTerminalExitResponse {
            guard terminals[terminalId] != nil else {
                throw ClientError.requestFailed("Terminal not found: \(terminalId)")
            }
            // Simulate immediate exit
            terminals[terminalId]?.exited = true
            return WaitForTerminalExitResponse(exitCode: 0)
        }

        func terminalKill(
            sessionId: SessionId,
            terminalId: String,
            meta: MetaField?
        ) async throws -> KillTerminalCommandResponse {
            guard terminals[terminalId] != nil else {
                throw ClientError.requestFailed("Terminal not found: \(terminalId)")
            }
            terminals[terminalId]?.exited = true
            return KillTerminalCommandResponse()
        }

        func setOutput(terminalId: String, output: String) {
            terminals[terminalId]?.output = output
        }
    }

    func testTerminalOperationsCreate() async throws {
        let client = TestTerminalClient()

        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "/bin/bash",
            args: ["-c", "echo hello"]
        )
        let response = try await client.terminalCreate(request: request)

        XCTAssertEqual(response.terminalId, "term-1")
    }

    func testTerminalOperationsOutput() async throws {
        let client = TestTerminalClient()

        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "echo",
            args: ["hello"]
        )
        let createResponse = try await client.terminalCreate(request: request)

        client.setOutput(terminalId: createResponse.terminalId, output: "hello\n")

        let outputResponse = try await client.terminalOutput(
            sessionId: SessionId("session-1"),
            terminalId: createResponse.terminalId,
            meta: nil
        )

        XCTAssertEqual(outputResponse.output, "hello\n")
        XCTAssertFalse(outputResponse.truncated)
    }

    func testTerminalOperationsWaitForExit() async throws {
        let client = TestTerminalClient()

        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "true"
        )
        let createResponse = try await client.terminalCreate(request: request)

        let exitResponse = try await client.terminalWaitForExit(
            sessionId: SessionId("session-1"),
            terminalId: createResponse.terminalId,
            meta: nil
        )

        XCTAssertEqual(exitResponse.exitCode, 0)
    }

    func testTerminalOperationsKill() async throws {
        let client = TestTerminalClient()

        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "sleep",
            args: ["100"]
        )
        let createResponse = try await client.terminalCreate(request: request)

        _ = try await client.terminalKill(
            sessionId: SessionId("session-1"),
            terminalId: createResponse.terminalId,
            meta: nil
        )

        // Terminal should be marked as exited
        let outputResponse = try await client.terminalOutput(
            sessionId: SessionId("session-1"),
            terminalId: createResponse.terminalId,
            meta: nil
        )

        XCTAssertNotNil(outputResponse.exitStatus)
    }

    func testTerminalOperationsRelease() async throws {
        let client = TestTerminalClient()

        let request = CreateTerminalRequest(
            sessionId: SessionId("session-1"),
            command: "echo"
        )
        let createResponse = try await client.terminalCreate(request: request)

        _ = try await client.terminalRelease(
            sessionId: SessionId("session-1"),
            terminalId: createResponse.terminalId,
            meta: nil
        )

        // Terminal should be gone
        do {
            _ = try await client.terminalOutput(
                sessionId: SessionId("session-1"),
                terminalId: createResponse.terminalId,
                meta: nil
            )
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    // MARK: - Default Terminal Implementation Tests

    private struct DefaultTerminalClient: TerminalOperations {
    }

    func testDefaultTerminalCreateThrows() async {
        let client = DefaultTerminalClient()

        do {
            let request = CreateTerminalRequest(
                sessionId: SessionId("session-1"),
                command: "echo"
            )
            _ = try await client.terminalCreate(request: request)
            XCTFail("Expected error")
        } catch let error as ClientError {
            XCTAssertTrue(error.errorDescription?.contains("notImplemented") == true ||
                          error.errorDescription?.contains("terminalCreate") == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDefaultTerminalOutputThrows() async {
        let client = DefaultTerminalClient()

        do {
            _ = try await client.terminalOutput(
                sessionId: SessionId("session-1"),
                terminalId: "term-1",
                meta: nil
            )
            XCTFail("Expected error")
        } catch let error as ClientError {
            XCTAssertTrue(error.errorDescription?.contains("notImplemented") == true ||
                          error.errorDescription?.contains("terminalOutput") == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
