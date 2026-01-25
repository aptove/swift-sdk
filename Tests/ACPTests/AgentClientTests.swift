import ACPModel
import XCTest

@testable import ACP

/// Tests for the Agent and Client runtime components.
internal final class AgentClientTests: XCTestCase {
    // MARK: - Agent Protocol Tests

    func testAgentProtocolDefaultInfo() async {
        struct MinimalAgent: Agent {
            var capabilities: AgentCapabilities {
                AgentCapabilities()
            }

            func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
                NewSessionResponse(sessionId: SessionId())
            }

            func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
                PromptResponse(stopReason: .endTurn)
            }
        }

        let agent = MinimalAgent()

        // Default info should be nil
        XCTAssertNil(agent.info)
    }

    func testAgentProtocolDefaultLoadSession() async throws {
        struct MinimalAgent: Agent {
            var capabilities: AgentCapabilities {
                AgentCapabilities()
            }

            func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
                NewSessionResponse(sessionId: SessionId())
            }

            func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
                PromptResponse(stopReason: .endTurn)
            }
        }

        let agent = MinimalAgent()
        let request = LoadSessionRequest(sessionId: SessionId(), cwd: "/tmp", mcpServers: [])

        // Default loadSession should throw notImplemented
        do {
            _ = try await agent.loadSession(request: request)
            XCTFail("Expected notImplemented error")
        } catch let error as AgentError {
            if case .notImplemented(let method) = error {
                XCTAssertEqual(method, "loadSession")
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testAgentWithCustomInfo() async {
        struct NamedAgent: Agent {
            var capabilities: AgentCapabilities {
                AgentCapabilities()
            }

            var info: Implementation? {
                Implementation(name: "TestAgent", version: "1.0.0")
            }

            func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
                NewSessionResponse(sessionId: SessionId())
            }

            func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
                PromptResponse(stopReason: .endTurn)
            }
        }

        let agent = NamedAgent()

        XCTAssertNotNil(agent.info)
        XCTAssertEqual(agent.info?.name, "TestAgent")
        XCTAssertEqual(agent.info?.version, "1.0.0")
    }

    // MARK: - Client Protocol Tests

    func testClientProtocolDefaultInfo() async {
        struct MinimalClient: Client {
            var capabilities: ClientCapabilities {
                ClientCapabilities()
            }
        }

        let client = MinimalClient()

        // Default info should be nil
        XCTAssertNil(client.info)
    }

    func testClientWithCustomInfo() async {
        struct NamedClient: Client {
            var capabilities: ClientCapabilities {
                ClientCapabilities()
            }

            var info: Implementation? {
                Implementation(name: "TestClient", version: "2.0.0")
            }
        }

        let client = NamedClient()

        XCTAssertNotNil(client.info)
        XCTAssertEqual(client.info?.name, "TestClient")
        XCTAssertEqual(client.info?.version, "2.0.0")
    }

    func testClientDefaultCallbacks() async {
        struct MinimalClient: Client {
            var capabilities: ClientCapabilities {
                ClientCapabilities()
            }
        }

        let client = MinimalClient()

        // Default callbacks should not throw
        await client.onConnected()
        await client.onDisconnected(error: nil)
        await client.onSessionUpdate(.sessionInfoUpdate(SessionInfoUpdate(title: "Test")))
    }

    // MARK: - AgentError Tests

    func testAgentErrorNotImplemented() {
        let error = AgentError.notImplemented(method: "foo")
        XCTAssertEqual(error.errorCode, -32601)
        XCTAssertTrue(error.errorDescription?.contains("foo") ?? false)
    }

    func testAgentErrorSessionNotFound() {
        let sessionId = SessionId()
        let error = AgentError.sessionNotFound(sessionId)
        XCTAssertEqual(error.errorCode, -32001)
        XCTAssertTrue(error.errorDescription?.contains("\(sessionId)") ?? false)
    }

    func testAgentErrorInvalidParams() {
        let error = AgentError.invalidParams("bad params")
        XCTAssertEqual(error.errorCode, -32602)
        XCTAssertTrue(error.errorDescription?.contains("bad params") ?? false)
    }

    func testAgentErrorInternalError() {
        let error = AgentError.internalError("something broke")
        XCTAssertEqual(error.errorCode, -32603)
        XCTAssertTrue(error.errorDescription?.contains("something broke") ?? false)
    }

    // MARK: - ClientError Tests

    func testClientErrorNotConnected() {
        let error = ClientError.notConnected
        XCTAssertTrue(error.errorDescription?.contains("Not connected") ?? false)
    }

    func testClientErrorAlreadyConnected() {
        let error = ClientError.alreadyConnected
        XCTAssertTrue(error.errorDescription?.contains("Already connected") ?? false)
    }

    func testClientErrorConnectionRejected() {
        let error = ClientError.connectionRejected("permission denied")
        XCTAssertTrue(error.errorDescription?.contains("permission denied") ?? false)
    }

    func testClientErrorTimeout() {
        let error = ClientError.timeout
        XCTAssertTrue(error.errorDescription?.contains("timed out") ?? false)
    }

    func testClientErrorInvalidResponse() {
        let error = ClientError.invalidResponse("malformed")
        XCTAssertTrue(error.errorDescription?.contains("malformed") ?? false)
    }

    // MARK: - AgentConnectionError Tests

    func testAgentConnectionErrorInvalidState() {
        let error = AgentConnectionError.invalidState(
            expected: .disconnected,
            actual: .connected
        )
        XCTAssertTrue(error.errorDescription?.contains("expected") ?? false)
    }

    func testAgentConnectionErrorNotConnected() {
        let error = AgentConnectionError.notConnected
        XCTAssertTrue(error.errorDescription?.contains("Not connected") ?? false)
    }

    func testAgentConnectionErrorUnknownMethod() {
        let error = AgentConnectionError.unknownMethod("unknown/method")
        XCTAssertTrue(error.errorDescription?.contains("unknown/method") ?? false)
    }

    func testAgentConnectionErrorMissingParams() {
        let error = AgentConnectionError.missingParams
        XCTAssertTrue(error.errorDescription?.contains("Missing") ?? false)
    }

    func testAgentConnectionErrorDecodingFailed() {
        let error = AgentConnectionError.decodingFailed("bad json")
        XCTAssertTrue(error.errorDescription?.contains("bad json") ?? false)
    }

    // MARK: - AgentConnection State Tests

    func testAgentConnectionInitialState() async {
        struct SimpleAgent: Agent {
            var capabilities: AgentCapabilities { AgentCapabilities() }
            func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
                NewSessionResponse(sessionId: SessionId())
            }
            func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
                PromptResponse(stopReason: .endTurn)
            }
        }

        let transport = MockTransport()
        let agent = SimpleAgent()
        let connection = AgentConnection(transport: transport, agent: agent)

        let state = await connection.state
        XCTAssertEqual(state, .disconnected)
    }

    // MARK: - ClientConnection State Tests

    func testClientConnectionInitialState() async {
        struct SimpleClient: Client {
            var capabilities: ClientCapabilities { ClientCapabilities() }
        }

        let transport = MockTransport()
        let client = SimpleClient()
        let connection = ClientConnection(transport: transport, client: client)

        let state = await connection.state
        XCTAssertEqual(state, .disconnected)
    }
}
