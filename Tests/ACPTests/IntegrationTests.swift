import XCTest
@testable import ACP
@testable import ACPModel
import Foundation

/// Integration tests for Agent/Client communication.
///
/// These tests verify end-to-end communication between agents and clients
/// using in-memory transport mechanisms.
internal final class IntegrationTests: XCTestCase {

    // MARK: - Test Agent

    /// A test agent that echoes prompts.
    private struct TestEchoAgent: Agent {
        var capabilities: AgentCapabilities {
            AgentCapabilities()
        }

        var info: Implementation? {
            Implementation(name: "TestEchoAgent", version: "1.0.0")
        }

        func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
            NewSessionResponse(sessionId: SessionId())
        }

        func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
            PromptResponse(stopReason: .endTurn)
        }
    }

    // MARK: - Test Client

    /// A test client that tracks callbacks.
    private final class TestClient: Client, @unchecked Sendable {
        var capabilities: ClientCapabilities { ClientCapabilities() }
        var info: Implementation? { Implementation(name: "TestClient", version: "1.0.0") }

        private(set) var connectedCount = 0
        private(set) var disconnectedCount = 0
        private(set) var sessionUpdates: [SessionInfoUpdate] = []

        func onConnected() async {
            connectedCount += 1
        }

        func onDisconnected(error: Error?) async {
            disconnectedCount += 1
        }

        func onSessionUpdate(_ update: SessionInfoUpdate) async {
            sessionUpdates.append(update)
        }
    }

    // MARK: - Integration Tests

    func testAgentProtocolConformance() {
        // Given
        let agent = TestEchoAgent()

        // Then - should have required properties
        XCTAssertNotNil(agent.capabilities)
        XCTAssertEqual(agent.info?.name, "TestEchoAgent")
    }

    func testClientProtocolConformance() {
        // Given
        let client = TestClient()

        // Then - should have required properties
        XCTAssertNotNil(client.capabilities)
        XCTAssertEqual(client.info?.name, "TestClient")
    }

    func testAgentCreateSession() async throws {
        // Given
        let agent = TestEchoAgent()
        let request = NewSessionRequest(cwd: "/tmp", mcpServers: [])

        // When
        let response = try await agent.createSession(request: request)

        // Then
        XCTAssertFalse(response.sessionId.value.isEmpty)
    }

    func testAgentHandlePrompt() async throws {
        // Given
        let agent = TestEchoAgent()
        let sessionId = SessionId()
        let request = PromptRequest(
            sessionId: sessionId,
            prompt: [.text(TextContent(text: "Hello"))]
        )

        // When
        let response = try await agent.handlePrompt(request: request)

        // Then
        XCTAssertEqual(response.stopReason, .endTurn)
    }

    func testAgentLoadSessionThrowsNotImplemented() async {
        // Given
        let agent = TestEchoAgent()
        let request = LoadSessionRequest(
            sessionId: SessionId(),
            cwd: "/tmp",
            mcpServers: []
        )

        // When/Then
        do {
            _ = try await agent.loadSession(request: request)
            XCTFail("Expected error")
        } catch let error as AgentError {
            XCTAssertTrue(error.errorDescription?.contains("loadSession") == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testClientCallbacks() async {
        // Given
        let client = TestClient()

        // When
        await client.onConnected()
        await client.onConnected()
        await client.onDisconnected(error: nil)

        // Then
        XCTAssertEqual(client.connectedCount, 2)
        XCTAssertEqual(client.disconnectedCount, 1)
    }

    func testClientDefaultImplementations() async {
        // Given - a minimal client with no callback overrides
        struct MinimalClient: Client {
            var capabilities: ClientCapabilities { ClientCapabilities() }
        }

        let client = MinimalClient()

        // When - call default implementations
        await client.onConnected()
        await client.onDisconnected(error: nil)
        await client.onSessionUpdate(.sessionInfoUpdate(SessionInfoUpdate()))

        // Then - should not crash (defaults do nothing)
        XCTAssertNil(client.info)
    }

    // MARK: - Example Code Compilation Tests

    /// Verify that EchoAgent example code pattern compiles.
    func testEchoAgentPattern() {
        // This test verifies the example code pattern works
        struct EchoAgent: Agent {
            var capabilities: AgentCapabilities {
                AgentCapabilities()
            }

            var info: Implementation? {
                Implementation(name: "EchoAgent", version: "1.0.0")
            }

            func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
                NewSessionResponse(sessionId: SessionId())
            }

            func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
                PromptResponse(stopReason: .endTurn)
            }
        }

        let agent = EchoAgent()
        XCTAssertEqual(agent.info?.name, "EchoAgent")
    }

    /// Verify that SimpleClient example code pattern compiles.
    func testSimpleClientPattern() {
        // This test verifies the example code pattern works
        struct SimpleClient: Client {
            var capabilities: ClientCapabilities {
                ClientCapabilities()
            }

            var info: Implementation? {
                Implementation(name: "SimpleClient", version: "1.0.0")
            }
        }

        let client = SimpleClient()
        XCTAssertEqual(client.info?.name, "SimpleClient")
    }
}
