import XCTest
@testable import ACP
@testable import ACPModel
import Foundation

/// Tests for ClientSession and related types.
internal final class ClientSessionTests: XCTestCase {

    // MARK: - Event Tests

    func testEventSessionUpdate() {
        let textContent = TextContent(text: "Hello")
        let update = SessionUpdate.userMessageChunk(
            UserMessageChunk(content: .text(textContent))
        )
        let event = Event.sessionUpdate(update)

        if case .sessionUpdate(let receivedUpdate) = event {
            if case .userMessageChunk(let chunk) = receivedUpdate {
                if case .text(let text) = chunk.content {
                    XCTAssertEqual(text.text, "Hello")
                } else {
                    XCTFail("Expected text content")
                }
            } else {
                XCTFail("Expected userMessageChunk")
            }
        } else {
            XCTFail("Expected sessionUpdate event")
        }
    }

    func testEventPromptResponse() {
        let response = PromptResponse(stopReason: .endTurn)
        let event = Event.promptResponse(response)

        if case .promptResponse(let receivedResponse) = event {
            XCTAssertEqual(receivedResponse.stopReason, .endTurn)
        } else {
            XCTFail("Expected promptResponse event")
        }
    }

    // MARK: - SessionCreationParameters Tests

    func testSessionCreationParametersInit() {
        let params = SessionCreationParameters(
            cwd: "/home/user/project",
            mcpServers: []
        )

        XCTAssertEqual(params.cwd, "/home/user/project")
        XCTAssertTrue(params.mcpServers.isEmpty)
    }

    func testSessionCreationParametersWithServers() {
        let stdioServer = StdioMcpServer(
            name: "test-server",
            command: "npx",
            args: ["-y", "server"],
            env: []
        )
        let server = McpServer.stdio(stdioServer)
        let params = SessionCreationParameters(
            cwd: "/project",
            mcpServers: [server]
        )

        XCTAssertEqual(params.mcpServers.count, 1)
    }

    // MARK: - ClientSessionOperations Tests

    /// A mock implementation of ClientSessionOperations
    private final class MockSessionOperations: ClientSessionOperations, @unchecked Sendable {
        var permissionRequests: [(ToolCallUpdateData, [PermissionOption])] = []
        var notifications: [SessionUpdate] = []

        func requestPermissions(
            toolCall: ToolCallUpdateData,
            permissions: [PermissionOption],
            meta: MetaField?
        ) async throws -> RequestPermissionResponse {
            permissionRequests.append((toolCall, permissions))
            return RequestPermissionResponse(outcome: .selected(permissions[0].optionId))
        }

        func notify(notification: SessionUpdate, meta: MetaField?) async {
            notifications.append(notification)
        }
    }

    func testMockSessionOperationsRequestPermissions() async throws {
        let ops = MockSessionOperations()
        let toolCall = ToolCallUpdateData(
            toolCallId: ToolCallId("tc-1"),
            title: "file_write",
            status: .inProgress
        )
        let options = [
            PermissionOption(
                optionId: PermissionOptionId("opt-1"),
                name: "Allow",
                kind: .allowOnce
            )
        ]

        let response = try await ops.requestPermissions(
            toolCall: toolCall,
            permissions: options,
            meta: nil
        )

        XCTAssertEqual(ops.permissionRequests.count, 1)
        if case .selected(let optionId) = response.outcome {
            XCTAssertEqual(optionId.value, "opt-1")
        } else {
            XCTFail("Expected selected outcome")
        }
    }

    func testMockSessionOperationsNotify() async {
        let ops = MockSessionOperations()
        let update = SessionUpdate.sessionInfoUpdate(SessionInfoUpdate(title: "Test"))

        await ops.notify(notification: update, meta: nil)

        XCTAssertEqual(ops.notifications.count, 1)
    }

    // MARK: - Default Implementation Tests

    /// A client that uses default ClientSessionOperations
    private struct DefaultSessionOperations: ClientSessionOperations {
    }

    func testDefaultRequestPermissionsThrows() async {
        let ops = DefaultSessionOperations()
        let toolCall = ToolCallUpdateData(
            toolCallId: ToolCallId("tc-1"),
            title: "exec",
            status: .inProgress
        )
        let options = [
            PermissionOption(
                optionId: PermissionOptionId("opt-1"),
                name: "Allow",
                kind: .allowOnce
            )
        ]

        do {
            _ = try await ops.requestPermissions(
                toolCall: toolCall,
                permissions: options,
                meta: nil
            )
            XCTFail("Expected error")
        } catch let error as ClientError {
            XCTAssertTrue(error.errorDescription?.contains("notImplemented") == true ||
                          error.errorDescription?.contains("requestPermissions") == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDefaultNotifyDoesNothing() async {
        let ops = DefaultSessionOperations()
        let update = SessionUpdate.sessionInfoUpdate(SessionInfoUpdate())

        // Should not throw
        await ops.notify(notification: update, meta: nil)
    }
}
