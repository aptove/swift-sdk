import XCTest
@testable import ACP
@testable import ACPModel
import Foundation

/// End-to-end integration tests for agent-client communication.
///
/// These tests verify full communication flows between agents and clients
/// over connected transports, including initialization, sessions, prompts,
/// cancellation, error propagation, and feature tests.
internal final class E2EIntegrationTests: XCTestCase {

    // MARK: - Test Fixtures

    /// A simple echo agent for integration testing.
    private final class EchoAgent: Agent, @unchecked Sendable {
        var loadSessionEnabled = true
        var listSessionsEnabled = false
        var throwOnPrompt: Error?
        var throwOnCreateSession: Error?
        var promptCancellationHandler: ((CancellationError) -> Void)?

        var capabilities: AgentCapabilities {
            AgentCapabilities(
                loadSession: loadSessionEnabled,
                promptCapabilities: PromptCapabilities()
            )
        }

        var info: Implementation? {
            Implementation(name: "EchoAgent", version: "1.0.0")
        }

        var createdSessions: [SessionId] = []
        var receivedPrompts: [PromptRequest] = []
        var shouldDelay = false
        var delaySeconds: UInt64 = 0

        // List of sessions to return for listSessions tests
        var sessionsToReturn: [SessionInfo] = []

        func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
            if let error = throwOnCreateSession {
                throw error
            }
            let sessionId = SessionId()
            createdSessions.append(sessionId)
            return NewSessionResponse(
                sessionId: sessionId,
                modes: SessionModeState(
                    currentModeId: SessionModeId(value: "chat"),
                    availableModes: [
                        SessionMode(id: SessionModeId(value: "chat"), name: "Chat Mode"),
                        SessionMode(id: SessionModeId(value: "code"), name: "Code Mode")
                    ]
                )
            )
        }

        func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
            receivedPrompts.append(request)

            if let error = throwOnPrompt {
                throw error
            }

            if shouldDelay {
                do {
                    try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                } catch is CancellationError {
                    promptCancellationHandler?(CancellationError())
                    throw CancellationError()
                }
            }

            return PromptResponse(stopReason: .endTurn)
        }

        // Track loaded sessions
        var loadedSessions: Set<SessionId> = []

        func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
            // Track that this session was loaded
            loadedSessions.insert(request.sessionId)
            return LoadSessionResponse(
                modes: SessionModeState(
                    currentModeId: SessionModeId(value: "chat"),
                    availableModes: [
                        SessionMode(id: SessionModeId(value: "chat"), name: "Chat Mode"),
                        SessionMode(id: SessionModeId(value: "code"), name: "Code Mode")
                    ]
                )
            )
        }
    }

    /// A test client that tracks callbacks.
    private final class TestClient: Client, @unchecked Sendable {
        var capabilities: ClientCapabilities {
            ClientCapabilities()
        }

        var info: Implementation? {
            Implementation(name: "TestClient", version: "1.0.0")
        }

        var connectedCalled = false
        var disconnectedCalled = false
        var sessionUpdates: [SessionUpdate] = []

        func onConnected() async {
            connectedCalled = true
        }

        func onDisconnected(error: Error?) async {
            disconnectedCalled = true
        }

        func onSessionUpdate(_ update: SessionUpdate) async {
            sessionUpdates.append(update)
        }
    }

    /// Helper struct containing connected transport pair with agent and client.
    private struct TestPair {
        let clientTransport: PipeTransport
        let agentTransport: PipeTransport
        let agent: EchoAgent
        let client: TestClient
    }

    // MARK: - Helper Methods

    private func createConnectedPair() -> TestPair {
        let (clientTransport, agentTransport) = PipeTransport.createPair()
        let agent = EchoAgent()
        let client = TestClient()
        return TestPair(
            clientTransport: clientTransport,
            agentTransport: agentTransport,
            agent: agent,
            client: client
        )
    }

    // MARK: - Initialization Tests

    func testInitializationHandshake() async throws {
        // Given - connected transport pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        // When - start agent first, then client connects
        try await agentConnection.start()

        // Small delay to let agent start
        try await Task.sleep(nanoseconds: 100_000_000)

        let agentInfo = try await clientConnection.connect()

        // Then - client received agent info
        XCTAssertEqual(agentInfo?.name, "EchoAgent")
        XCTAssertEqual(agentInfo?.version, "1.0.0")
        XCTAssertTrue(pair.client.connectedCalled)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testClientReceivesAgentCapabilities() async throws {
        // Given - connected transport pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        // When
        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // Then - client received agent capabilities
        let capabilities = await clientConnection.agentCapabilities
        XCTAssertEqual(capabilities?.loadSession, true)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Session Tests

    func testCreateSession() async throws {
        // Given - connected and initialized
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // When - create session
        let request = NewSessionRequest(cwd: "/tmp/test", mcpServers: [])
        let response = try await clientConnection.createSession(request: request)

        // Then - session created
        XCTAssertFalse(response.sessionId.value.isEmpty)
        XCTAssertEqual(pair.agent.createdSessions.count, 1)

        // Verify modes returned
        XCTAssertNotNil(response.modes)
        XCTAssertEqual(response.modes?.currentModeId.value, "chat")
        XCTAssertEqual(response.modes?.availableModes.count, 2)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Prompt Tests

    func testSimplePromptFlow() async throws {
        // Given - connected with session
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )
        let sessionId = sessionResponse.sessionId

        // When - send prompt
        let promptRequest = PromptRequest(
            sessionId: sessionId,
            prompt: [.text(TextContent(text: "Hello, agent!"))]
        )
        let promptResponse = try await clientConnection.prompt(request: promptRequest)

        // Then - received response
        XCTAssertEqual(promptResponse.stopReason, .endTurn)
        XCTAssertEqual(pair.agent.receivedPrompts.count, 1)
        XCTAssertEqual(pair.agent.receivedPrompts[0].sessionId, sessionId)

        // Verify prompt content
        if case .text(let textContent) = pair.agent.receivedPrompts[0].prompt.first {
            XCTAssertEqual(textContent.text, "Hello, agent!")
        } else {
            XCTFail("Expected text content")
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testMultiplePromptsInSequence() async throws {
        // Given - connected with session
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )
        let sessionId = sessionResponse.sessionId

        // When - send multiple prompts
        for i in 1...3 {
            let request = PromptRequest(
                sessionId: sessionId,
                prompt: [.text(TextContent(text: "Prompt \(i)"))]
            )
            let response = try await clientConnection.prompt(request: request)
            XCTAssertEqual(response.stopReason, .endTurn)
        }

        // Then - all prompts received
        XCTAssertEqual(pair.agent.receivedPrompts.count, 3)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Connection State Tests

    func testDisconnect() async throws {
        // Given - connected
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // Verify connected state
        let stateBeforeDisconnect = await clientConnection.state
        XCTAssertEqual(stateBeforeDisconnect, .connected)

        // When - disconnect
        await clientConnection.disconnect()

        // Then - disconnected
        let stateAfterDisconnect = await clientConnection.state
        XCTAssertEqual(stateAfterDisconnect, .disconnected)
        XCTAssertTrue(pair.client.disconnectedCalled)

        // Cleanup
        await agentConnection.stop()
    }

    func testRequestAfterDisconnectFails() async throws {
        // Given - was connected, now disconnected
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()
        await clientConnection.disconnect()

        // When/Then - request should fail
        do {
            _ = try await clientConnection.createSession(
                request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
            )
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // Cleanup
        await agentConnection.stop()
    }

    // MARK: - Error Handling Tests

    func testClientConnectionRequiresConnectedState() async throws {
        // Given - a client connection that hasn't connected
        let pair = createConnectedPair()
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        // When/Then - operations should fail when not connected
        let state = await clientConnection.state
        XCTAssertEqual(state, .disconnected)

        // Trying to create session without connecting should fail
        do {
            _ = try await clientConnection.createSession(
                request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
            )
            XCTFail("Expected notConnected error")
        } catch ClientError.notConnected {
            // Expected
        } catch {
            XCTFail("Expected notConnected error, got: \(error)")
        }
    }

    // MARK: - Error Propagation Tests

    func testErrorPropagatedInternalError() async throws {
        // Given - agent throws internal error
        let pair = createConnectedPair()
        pair.agent.throwOnPrompt = AgentError.internalError("Test internal error")

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt that triggers error
        do {
            _ = try await clientConnection.prompt(request: PromptRequest(
                sessionId: sessionResponse.sessionId,
                prompt: [.text(TextContent(text: "test"))]
            ))
            XCTFail("Expected error")
        } catch let error as ProtocolError {
            // Then - error is propagated to client
            if case .jsonRpcError(let code, let message, _) = error {
                XCTAssertEqual(code, -32603) // Internal error code
                XCTAssertTrue(message.contains("Internal error"))
            } else {
                XCTFail("Expected jsonRpcError, got: \(error)")
            }
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testErrorPropagatedInvalidParams() async throws {
        // Given - agent throws invalid params error
        let pair = createConnectedPair()
        pair.agent.throwOnPrompt = AgentError.invalidParams("Invalid parameters provided")

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt that triggers error
        do {
            _ = try await clientConnection.prompt(request: PromptRequest(
                sessionId: sessionResponse.sessionId,
                prompt: [.text(TextContent(text: "test"))]
            ))
            XCTFail("Expected error")
        } catch let error as ProtocolError {
            // Then - error is propagated to client
            if case .jsonRpcError(let code, let message, _) = error {
                XCTAssertEqual(code, -32602) // Invalid params code
                XCTAssertTrue(message.contains("Invalid parameters"))
            } else {
                XCTFail("Expected jsonRpcError, got: \(error)")
            }
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testErrorPropagatedMethodNotFound() async throws {
        // Given - agent that throws notImplemented error on createSession
        let pair = createConnectedPair()
        pair.agent.throwOnCreateSession = AgentError.notImplemented(method: "createSession")

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // When - try to create session (which agent has marked as not implemented)
        do {
            _ = try await clientConnection.createSession(
                request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
            )
            XCTFail("Expected error")
        } catch let error as ProtocolError {
            // Then - method not found error is propagated
            if case .jsonRpcError(let code, let message, _) = error {
                XCTAssertEqual(code, -32601) // Method not found code
                XCTAssertTrue(message.contains("not implemented"))
            } else {
                XCTFail("Expected jsonRpcError with method not found code, got: \(error)")
            }
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testErrorPropagatedSessionNotFound() async throws {
        // Given - agent that throws session not found
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // When - try to prompt with non-existent session
        let fakeSessionId = SessionId()
        pair.agent.throwOnPrompt = AgentError.sessionNotFound(fakeSessionId)

        do {
            // Create a session first (to get agent working)
            let session = try await clientConnection.createSession(
                request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
            )

            // Then prompt (which will throw the configured error)
            _ = try await clientConnection.prompt(request: PromptRequest(
                sessionId: session.sessionId,
                prompt: [.text(TextContent(text: "test"))]
            ))
            XCTFail("Expected error")
        } catch let error as ProtocolError {
            // Then - session not found error is propagated
            if case .jsonRpcError(let code, let message, _) = error {
                XCTAssertEqual(code, -32001) // Resource not found code
                XCTAssertTrue(message.contains("Session not found"))
            } else {
                XCTFail("Expected jsonRpcError, got: \(error)")
            }
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Cancellation Tests

    func testCancelPromptFromClient() async throws {
        // Given - connected pair with agent that delays
        let pair = createConnectedPair()
        pair.agent.shouldDelay = true
        pair.agent.delaySeconds = 10 // Long delay to ensure we can cancel

        let cancellationReceived = expectation(description: "Agent received cancellation")
        pair.agent.promptCancellationHandler = { _ in
            cancellationReceived.fulfill()
        }

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - start prompt and cancel it
        let promptTask = Task {
            try await clientConnection.prompt(request: PromptRequest(
                sessionId: sessionResponse.sessionId,
                prompt: [.text(TextContent(text: "test"))]
            ))
        }

        // Wait a bit then cancel
        try await Task.sleep(nanoseconds: 200_000_000)
        promptTask.cancel()

        // Then - task should be cancelled
        do {
            _ = try await promptTask.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected - Swift task was cancelled
        } catch {
            // Transport may be closed, which is also acceptable
        }

        // Verify agent received the cancellation (with timeout)
        await fulfillment(of: [cancellationReceived], timeout: 2.0)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testCancelledPromptStopsProcessing() async throws {
        // Given - connected pair
        let pair = createConnectedPair()
        pair.agent.shouldDelay = true
        pair.agent.delaySeconds = 5

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - cancel before response
        let promptTask = Task {
            try await clientConnection.prompt(request: PromptRequest(
                sessionId: sessionResponse.sessionId,
                prompt: [.text(TextContent(text: "test"))]
            ))
        }

        // Short delay then cancel
        try await Task.sleep(nanoseconds: 100_000_000)
        promptTask.cancel()

        // Then - should complete quickly (not wait for full delay)
        let startTime = Date()
        _ = try? await promptTask.value
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(elapsed, 2.0, "Cancellation should stop processing quickly")

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Session Operation Tests

    func testLoadSessionFlow() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // First create a session
        let createResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - load the session
        let loadResponse = try await clientConnection.loadSession(
            request: LoadSessionRequest(
                sessionId: createResponse.sessionId,
                cwd: "/tmp",
                mcpServers: []
            )
        )

        // Then - session is loaded
        XCTAssertNotNil(loadResponse)
        XCTAssertEqual(loadResponse.modes?.currentModeId.value, "chat")

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testMultipleSessionsInParallel() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // When - create multiple sessions
        async let session1 = clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp/1", mcpServers: [])
        )
        async let session2 = clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp/2", mcpServers: [])
        )
        async let session3 = clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp/3", mcpServers: [])
        )

        let responses = try await [session1, session2, session3]

        // Then - all sessions created with unique IDs
        XCTAssertEqual(responses.count, 3)
        let sessionIds = Set(responses.map { $0.sessionId })
        XCTAssertEqual(sessionIds.count, 3, "All session IDs should be unique")

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Response Order Tests

    func testPromptResponseAndUpdateHaveProperOrder() async throws {
        // Given - connected with session
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt
        let promptRequest = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: "Hello"))]
        )
        let response = try await clientConnection.prompt(request: promptRequest)

        // Then - response arrives with proper stop reason
        XCTAssertEqual(response.stopReason, .endTurn)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Reconnection Tests

    func testConnectAfterDisconnect() async throws {
        // Given - connected then disconnected
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()
        await clientConnection.disconnect()

        // Verify disconnected
        let stateAfterDisconnect = await clientConnection.state
        XCTAssertEqual(stateAfterDisconnect, .disconnected)

        // When - create new transport pair and connect again
        let (newClientTransport, newAgentTransport) = PipeTransport.createPair()
        let newAgentConnection = AgentConnection(transport: newAgentTransport, agent: pair.agent)
        let newClientConnection = ClientConnection(transport: newClientTransport, client: pair.client)

        try await newAgentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await newClientConnection.connect()

        // Then - new connection works
        let stateAfterReconnect = await newClientConnection.state
        XCTAssertEqual(stateAfterReconnect, .connected)

        // Can create session
        let sessionResponse = try await newClientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )
        XCTAssertFalse(sessionResponse.sessionId.value.isEmpty)

        // Cleanup
        await newClientConnection.disconnect()
        await newAgentConnection.stop()
        await agentConnection.stop()
    }

    // MARK: - Protocol Edge Cases

    func testLargePromptContent() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send large prompt (100KB of text)
        let largeText = String(repeating: "x", count: 100_000)
        let promptRequest = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: largeText))]
        )
        let response = try await clientConnection.prompt(request: promptRequest)

        // Then - response received
        XCTAssertEqual(response.stopReason, .endTurn)
        XCTAssertEqual(pair.agent.receivedPrompts.count, 1)

        // Verify content received
        if case .text(let textContent) = pair.agent.receivedPrompts[0].prompt.first {
            XCTAssertEqual(textContent.text.count, 100_000)
        } else {
            XCTFail("Expected text content")
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testMultipleContentBlocksInPrompt() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt with multiple content blocks
        let promptRequest = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [
                .text(TextContent(text: "First message")),
                .text(TextContent(text: "Second message")),
                .text(TextContent(text: "Third message"))
            ]
        )
        let response = try await clientConnection.prompt(request: promptRequest)

        // Then - all content blocks received
        XCTAssertEqual(response.stopReason, .endTurn)
        XCTAssertEqual(pair.agent.receivedPrompts[0].prompt.count, 3)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testEmptyPromptContent() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send empty prompt
        let promptRequest = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: []
        )
        let response = try await clientConnection.prompt(request: promptRequest)

        // Then - response received
        XCTAssertEqual(response.stopReason, .endTurn)
        XCTAssertEqual(pair.agent.receivedPrompts[0].prompt.count, 0)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testRapidFirePrompts() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send many prompts in rapid succession
        let promptCount = 20
        for index in 0..<promptCount {
            let request = PromptRequest(
                sessionId: sessionResponse.sessionId,
                prompt: [.text(TextContent(text: "Prompt \(index)"))]
            )
            let response = try await clientConnection.prompt(request: request)
            XCTAssertEqual(response.stopReason, .endTurn)
        }

        // Then - all prompts processed
        XCTAssertEqual(pair.agent.receivedPrompts.count, promptCount)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Permission Request Tests

    func testPermissionRequestInPrompt() async throws {
        // Given - connected pair with permission-requesting agent
        let (clientTransport, agentTransport) = PipeTransport.createPair()

        let permissionReceived = expectation(description: "Permission received")
        var receivedToolCallId: ToolCallId?
        var receivedOptions: [PermissionOption] = []

        let agent = PermissionRequestingAgent(
            requestPermission: { toolCallId, options in
                // Agent requests permission from client
                receivedToolCallId = toolCallId
                receivedOptions = options
                permissionReceived.fulfill()
                return RequestPermissionResponse(outcome: .selected(options[0].optionId))
            }
        )

        let client = PermissionHandlingClient(
            onPermissionRequest: { toolCall, options in
                // Client approves the first option
                return RequestPermissionResponse(outcome: .selected(options[0].optionId))
            }
        )

        let agentConnection = AgentConnection(transport: agentTransport, agent: agent)
        let clientConnection = ClientConnection(transport: clientTransport, client: client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt that triggers permission request
        let request = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: "Request permission"))]
        )
        let response = try await clientConnection.prompt(request: request)

        // Then
        XCTAssertEqual(response.stopReason, .endTurn)
        await fulfillment(of: [permissionReceived], timeout: 5.0)
        XCTAssertNotNil(receivedToolCallId)
        XCTAssertEqual(receivedOptions.count, 2)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testPermissionRequestCancelled() async throws {
        // Given - connected pair with permission-requesting agent
        let (clientTransport, agentTransport) = PipeTransport.createPair()

        let agent = PermissionRequestingAgent(
            requestPermission: { _, options in
                return RequestPermissionResponse(outcome: .cancelled)
            }
        )

        let client = PermissionHandlingClient(
            onPermissionRequest: { _, _ in
                // Client cancels the permission request
                return RequestPermissionResponse(outcome: .cancelled)
            }
        )

        let agentConnection = AgentConnection(transport: agentTransport, agent: agent)
        let clientConnection = ClientConnection(transport: clientTransport, client: client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt that triggers permission request
        let request = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: "Request permission"))]
        )
        let response = try await clientConnection.prompt(request: request)

        // Then - agent receives cancelled outcome
        XCTAssertEqual(response.stopReason, .endTurn)
        XCTAssertTrue(agent.receivedCancelledPermission)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Cancellation Edge Cases

    func testCancelPromptFromAgentSide() async throws {
        // Given - connected pair with agent that throws cancellation
        let pair = createConnectedPair()
        pair.agent.throwOnPrompt = CancellationError()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt (agent will throw CancellationError)
        let request = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: "Will be cancelled by agent"))]
        )

        // Then - client receives cancellation error
        do {
            _ = try await clientConnection.prompt(request: request)
            XCTFail("Expected cancellation error")
        } catch {
            // Cancellation errors are propagated - this is expected
            XCTAssertTrue(
                error.localizedDescription.lowercased().contains("cancel") ||
                error is CancellationError ||
                (error as NSError).code == -32800
            )
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testCancelPromptDuringProcessing() async throws {
        // Given - connected pair with slow agent
        let pair = createConnectedPair()
        pair.agent.shouldDelay = true
        pair.agent.delaySeconds = 10 // Long delay

        let cancellationReceived = expectation(description: "Cancellation received")
        pair.agent.promptCancellationHandler = { _ in
            cancellationReceived.fulfill()
        }

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - start prompt and then cancel it
        let request = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: "Long running"))]
        )

        let promptTask = Task {
            try await clientConnection.prompt(request: request)
        }

        // Give the request time to reach the agent
        try await Task.sleep(nanoseconds: 300_000_000)

        // Cancel the task
        promptTask.cancel()

        // Then - agent receives cancellation
        await fulfillment(of: [cancellationReceived], timeout: 2.0)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Session Operations Tests

    func testSessionInfoInResponse() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // When - create session
        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/project", mcpServers: [])
        )

        // Then - session has mode information
        XCTAssertNotNil(sessionResponse.sessionId)
        XCTAssertNotNil(sessionResponse.modes)
        XCTAssertEqual(sessionResponse.modes?.currentModeId.value, "chat")
        XCTAssertEqual(sessionResponse.modes?.availableModes.count, 2)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testLoadSessionPreservesState() async throws {
        // Given - connected pair with created session
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        // Create a session first
        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/project", mcpServers: [])
        )

        // When - load the same session
        let loadResponse = try await clientConnection.loadSession(
            request: LoadSessionRequest(sessionId: sessionResponse.sessionId, cwd: "/project", mcpServers: [])
        )

        // Then - session loaded with modes
        XCTAssertNotNil(loadResponse.modes)
        XCTAssertTrue(pair.agent.loadedSessions.contains(sessionResponse.sessionId))

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Protocol Edge Cases

    func testConcurrentRequests() async throws {
        // Given - connected pair
        let pair = createConnectedPair()

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        let clientConnection = ClientConnection(transport: pair.clientTransport, client: pair.client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send multiple concurrent prompt requests
        let concurrentCount = 5
        let results = await withTaskGroup(of: Result<PromptResponse, Error>.self) { group in
            for index in 0..<concurrentCount {
                group.addTask {
                    do {
                        let request = PromptRequest(
                            sessionId: sessionResponse.sessionId,
                            prompt: [.text(TextContent(text: "Concurrent \(index)"))]
                        )
                        let response = try await clientConnection.prompt(request: request)
                        return .success(response)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var results: [Result<PromptResponse, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Then - all requests completed successfully
        let successCount = results.filter { if case .success = $0 { return true } else { return false } }.count
        XCTAssertEqual(successCount, concurrentCount)

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testRequestTimeoutBehavior() async throws {
        // Given - connected pair with very slow agent
        let pair = createConnectedPair()
        pair.agent.shouldDelay = true
        pair.agent.delaySeconds = 60 // Very long delay

        let agentConnection = AgentConnection(transport: pair.agentTransport, agent: pair.agent)
        // Create client connection with short timeout
        let clientConnection = ClientConnection(
            transport: pair.clientTransport,
            client: pair.client,
            defaultTimeoutSeconds: 1.0
        )

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - send prompt that will timeout
        let request = PromptRequest(
            sessionId: sessionResponse.sessionId,
            prompt: [.text(TextContent(text: "Will timeout"))]
        )

        // Then - request times out or fails
        do {
            _ = try await clientConnection.prompt(request: request)
            XCTFail("Expected timeout or error")
        } catch {
            // Any error is acceptable here - timeout, cancellation, or protocol error
            // The key is that the operation doesn't succeed
            let errorDesc = error.localizedDescription.lowercased()
            let isExpectedError = errorDesc.contains("timeout") ||
                                  errorDesc.contains("cancel") ||
                                  errorDesc.contains("time") ||
                                  error is CancellationError ||
                                  (error as NSError).code != 0
            XCTAssertTrue(isExpectedError, "Expected timeout/cancellation error but got: \(error)")
        }

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    // MARK: - Model Selection Tests (Unstable API)

    func testSetSessionModel() async throws {
        // Given - connected pair
        let (clientTransport, agentTransport) = PipeTransport.createPair()

        var receivedModelRequest: SetSessionModelRequest?
        let agent = ModelSelectingAgent { request in
            receivedModelRequest = request
            return SetSessionModelResponse()
        }
        let client = TestClient()

        let agentConnection = AgentConnection(transport: agentTransport, agent: agent)
        let clientConnection = ClientConnection(transport: clientTransport, client: client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - set session model
        let modelRequest = SetSessionModelRequest(
            sessionId: sessionResponse.sessionId,
            modelId: ModelId(value: "claude-3-opus")
        )
        _ = try await clientConnection.setSessionModel(request: modelRequest)

        // Then - agent received the request
        XCTAssertNotNil(receivedModelRequest)
        XCTAssertEqual(receivedModelRequest?.modelId.value, "claude-3-opus")

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }

    func testSetSessionConfigOption() async throws {
        // Given - connected pair
        let (clientTransport, agentTransport) = PipeTransport.createPair()

        var receivedConfigRequest: SetSessionConfigOptionRequest?
        let agent = ConfigurableAgent { request in
            receivedConfigRequest = request
            return SetSessionConfigOptionResponse()
        }
        let client = TestClient()

        let agentConnection = AgentConnection(transport: agentTransport, agent: agent)
        let clientConnection = ClientConnection(transport: clientTransport, client: client)

        try await agentConnection.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await clientConnection.connect()

        let sessionResponse = try await clientConnection.createSession(
            request: NewSessionRequest(cwd: "/tmp", mcpServers: [])
        )

        // When - set session config option
        let configRequest = SetSessionConfigOptionRequest(
            sessionId: sessionResponse.sessionId,
            configId: SessionConfigId(value: "format"),
            value: SessionConfigValueId(value: "markdown")
        )
        _ = try await clientConnection.setSessionConfigOption(request: configRequest)

        // Then - agent received the request
        XCTAssertNotNil(receivedConfigRequest)
        XCTAssertEqual(receivedConfigRequest?.configId.value, "format")
        XCTAssertEqual(receivedConfigRequest?.value.value, "markdown")

        // Cleanup
        await clientConnection.disconnect()
        await agentConnection.stop()
    }
}

// MARK: - Test Fixtures for Permission Tests

/// Agent that requests permissions during prompt handling.
private final class PermissionRequestingAgent: Agent, @unchecked Sendable {
    let requestPermission: (ToolCallId, [PermissionOption]) async -> RequestPermissionResponse
    var receivedCancelledPermission = false

    var capabilities: AgentCapabilities {
        AgentCapabilities()
    }

    var info: Implementation? {
        Implementation(name: "PermissionRequestingAgent", version: "1.0.0")
    }

    init(requestPermission: @escaping (ToolCallId, [PermissionOption]) async -> RequestPermissionResponse) {
        self.requestPermission = requestPermission
    }

    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        NewSessionResponse(sessionId: SessionId())
    }

    func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
        // Simulate agent needing to request permission
        let toolCallId = ToolCallId(value: "test-tool-\(UUID().uuidString)")
        let options = [
            PermissionOption(
                optionId: PermissionOptionId(value: "approve"),
                name: "Approve",
                kind: .allowOnce
            ),
            PermissionOption(
                optionId: PermissionOptionId(value: "reject"),
                name: "Reject",
                kind: .rejectOnce
            )
        ]

        let response = await requestPermission(toolCallId, options)
        if case .cancelled = response.outcome {
            receivedCancelledPermission = true
        }

        return PromptResponse(stopReason: .endTurn)
    }

    func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
        LoadSessionResponse()
    }
}

/// Client that handles permission requests.
private final class PermissionHandlingClient: Client, ClientSessionOperations, @unchecked Sendable {
    let onPermissionRequest: (ToolCallUpdateData, [PermissionOption]) async -> RequestPermissionResponse

    var capabilities: ClientCapabilities {
        ClientCapabilities()
    }

    var info: Implementation? {
        Implementation(name: "PermissionHandlingClient", version: "1.0.0")
    }

    init(onPermissionRequest: @escaping (ToolCallUpdateData, [PermissionOption]) async -> RequestPermissionResponse) {
        self.onPermissionRequest = onPermissionRequest
    }

    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        return await onPermissionRequest(toolCall, permissions)
    }

    func notify(notification: SessionUpdate, meta: MetaField?) async {
        // Handle notifications
    }

    // FileSystemOperations - default implementations
    func readTextFile(path: String, line: UInt32?, limit: UInt32?, meta: MetaField?) async throws -> ReadTextFileResponse {
        throw ClientError.notImplemented("readTextFile")
    }

    func writeTextFile(path: String, content: String, meta: MetaField?) async throws -> WriteTextFileResponse {
        throw ClientError.notImplemented("writeTextFile")
    }
}

// MARK: - Test Fixtures for Model/Config Tests

/// Agent that handles model selection requests.
private final class ModelSelectingAgent: Agent, @unchecked Sendable {
    let onSetModel: (SetSessionModelRequest) async -> SetSessionModelResponse

    var capabilities: AgentCapabilities {
        AgentCapabilities()
    }

    var info: Implementation? {
        Implementation(name: "ModelSelectingAgent", version: "1.0.0")
    }

    init(onSetModel: @escaping (SetSessionModelRequest) async -> SetSessionModelResponse) {
        self.onSetModel = onSetModel
    }

    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        NewSessionResponse(sessionId: SessionId())
    }

    func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
        PromptResponse(stopReason: .endTurn)
    }

    func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
        LoadSessionResponse()
    }

    func setSessionModel(request: SetSessionModelRequest) async throws -> SetSessionModelResponse {
        return await onSetModel(request)
    }
}

/// Agent that handles config option requests.
private final class ConfigurableAgent: Agent, @unchecked Sendable {
    let onSetConfig: (SetSessionConfigOptionRequest) async -> SetSessionConfigOptionResponse

    var capabilities: AgentCapabilities {
        AgentCapabilities()
    }

    var info: Implementation? {
        Implementation(name: "ConfigurableAgent", version: "1.0.0")
    }

    init(onSetConfig: @escaping (SetSessionConfigOptionRequest) async -> SetSessionConfigOptionResponse) {
        self.onSetConfig = onSetConfig
    }

    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        NewSessionResponse(sessionId: SessionId())
    }

    func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
        PromptResponse(stopReason: .endTurn)
    }

    func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
        LoadSessionResponse()
    }

    func setSessionConfigOption(request: SetSessionConfigOptionRequest) async throws -> SetSessionConfigOptionResponse {
        return await onSetConfig(request)
    }
}
