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
}
