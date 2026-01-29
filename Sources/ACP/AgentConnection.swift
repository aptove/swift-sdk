import ACPModel
import Foundation

/// Manages an agent's connection with a client over a transport.
///
/// AgentConnection handles the ACP protocol lifecycle on the agent side:
/// - Receives initialization requests and responds with agent capabilities
/// - Routes incoming requests (session creation, prompts) to the Agent implementation
/// - Sends session updates to the client
/// - Provides agents with ability to make requests to the client during prompt handling
///
/// ## Usage
///
/// ```swift
/// let transport = StdioTransport()
/// let agent = MyAgent()
/// let connection = AgentConnection(transport: transport, agent: agent)
///
/// try await connection.start()
/// // Connection handles requests until transport closes
/// ```
public actor AgentConnection {
    // MARK: - State

    /// Current connection state.
    public enum State: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    /// The underlying transport.
    private let transport: Transport

    /// The protocol layer for bidirectional communication.
    /// This allows the agent to make requests to the client.
    private var protocolLayer: Protocol?

    /// The agent implementation.
    private let agent: any Agent

    /// Current connection state.
    public private(set) var state: State = .disconnected

    /// Client info received during initialization.
    public private(set) var clientInfo: Implementation?

    /// Client capabilities received during initialization.
    public private(set) var clientCapabilities: ClientCapabilities?

    /// Task monitoring transport state.
    private var messageHandler: Task<Void, Never>?

    // MARK: - Initialization

    /// Create an agent connection with a transport and agent.
    ///
    /// - Parameters:
    ///   - transport: Transport for communication
    ///   - agent: Agent implementation to handle requests
    public init(transport: any Transport, agent: any Agent) {
        self.transport = transport
        self.agent = agent
    }

    // MARK: - Lifecycle

    /// Start the agent connection and begin handling requests.
    ///
    /// This method starts the transport and message handler, then returns.
    /// Use `waitUntilComplete()` to wait for the connection to close.
    ///
    /// - Throws: Error if starting fails
    public func start() async throws {
        guard state == .disconnected else {
            throw AgentConnectionError.invalidState(expected: .disconnected, actual: state)
        }

        state = .connecting

        do {
            // Create protocol layer for bidirectional communication
            let proto = Protocol(transport: transport)
            self.protocolLayer = proto

            // Register request handlers with the protocol layer
            await registerRequestHandlers(proto)

            // Start the protocol layer (which starts transport and message processing)
            try await proto.start()

            state = .connected

            // Monitor for transport close
            messageHandler = Task { [weak self] in
                // Wait for transport state to become closed
                let stateStream = self?.transport.state ?? AsyncStream(unfolding: { nil })
                for await state in stateStream {
                    if state == .closed {
                        break
                    }
                }
                await self?.handleTransportClosed()
            }
        } catch {
            state = .disconnected
            throw error
        }
    }

    /// Handle transport close.
    private func handleTransportClosed() {
        state = .disconnected
    }

    /// Register request handlers with the protocol layer.
    private func registerRequestHandlers(_ proto: Protocol) async {
        await proto.onRequest(method: "initialize") { [weak self] request in
            try await self?.handleInitialize(request) ?? .null
        }

        await proto.onRequest(method: "session/new") { [weak self] request in
            try await self?.handleNewSession(request) ?? .null
        }

        await proto.onRequest(method: "session/load") { [weak self] request in
            try await self?.handleLoadSession(request) ?? .null
        }

        await proto.onRequest(method: "session/list") { [weak self] request in
            try await self?.handleListSessions(request) ?? .null
        }

        await proto.onRequest(method: "session/fork") { [weak self] request in
            try await self?.handleForkSession(request) ?? .null
        }

        await proto.onRequest(method: "session/resume") { [weak self] request in
            try await self?.handleResumeSession(request) ?? .null
        }

        await proto.onRequest(method: "session/prompt") { [weak self] request in
            try await self?.handlePrompt(request) ?? .null
        }

        await proto.onRequest(method: "session/set_mode") { [weak self] request in
            try await self?.handleSetSessionMode(request) ?? .null
        }

        await proto.onRequest(method: "session/set_model") { [weak self] request in
            try await self?.handleSetSessionModel(request) ?? .null
        }

        await proto.onRequest(method: "session/set_config_option") { [weak self] request in
            try await self?.handleSetSessionConfigOption(request) ?? .null
        }
    }

    /// Wait until the connection is complete (transport closes or error).
    public func waitUntilComplete() async {
        await messageHandler?.value
    }

    /// Stop the agent connection.
    public func stop() async {
        guard state == .connected else {
            return
        }

        state = .disconnecting
        messageHandler?.cancel()
        messageHandler = nil

        // Close protocol layer (which closes transport)
        if let proto = protocolLayer {
            await proto.close()
        }
        protocolLayer = nil

        state = .disconnected
    }

    // MARK: - Request Handlers

    /// Handle initialize request.
    private func handleInitialize(_ request: JsonRpcRequest) async throws -> JsonValue {
        let initRequest: InitializeRequest = try decodeParams(request.params)
        self.clientInfo = initRequest.clientInfo
        self.clientCapabilities = initRequest.clientCapabilities

        let response = InitializeResponse(
            protocolVersion: initRequest.protocolVersion,
            agentCapabilities: agent.capabilities,
            agentInfo: agent.info
        )

        return try encodeResult(response)
    }

    /// Handle new session request.
    private func handleNewSession(_ request: JsonRpcRequest) async throws -> JsonValue {
        let sessionRequest: NewSessionRequest = try decodeParams(request.params)
        let response = try await agent.createSession(request: sessionRequest)
        return try encodeResult(response)
    }

    /// Handle load session request.
    private func handleLoadSession(_ request: JsonRpcRequest) async throws -> JsonValue {
        let loadRequest: LoadSessionRequest = try decodeParams(request.params)
        let response = try await agent.loadSession(request: loadRequest)
        return try encodeResult(response)
    }

    /// Handle list sessions request.
    private func handleListSessions(_ request: JsonRpcRequest) async throws -> JsonValue {
        let listRequest: ListSessionsRequest = try decodeParams(request.params)
        let response = try await agent.listSessions(request: listRequest)
        return try encodeResult(response)
    }

    /// Handle fork session request.
    private func handleForkSession(_ request: JsonRpcRequest) async throws -> JsonValue {
        let forkRequest: ForkSessionRequest = try decodeParams(request.params)
        let response = try await agent.forkSession(request: forkRequest)
        return try encodeResult(response)
    }

    /// Handle resume session request.
    private func handleResumeSession(_ request: JsonRpcRequest) async throws -> JsonValue {
        let resumeRequest: ResumeSessionRequest = try decodeParams(request.params)
        let response = try await agent.resumeSession(request: resumeRequest)
        return try encodeResult(response)
    }

    /// Handle prompt request.
    private func handlePrompt(_ request: JsonRpcRequest) async throws -> JsonValue {
        let promptRequest: PromptRequest = try decodeParams(request.params)

        // Create the agent context for this prompt
        guard let protocolLayer = self.protocolLayer else {
            throw AgentConnectionError.notConnected
        }

        let context = RemoteClientOperations(
            sessionId: promptRequest.sessionId,
            clientCapabilities: clientCapabilities ?? ClientCapabilities(),
            protocolLayer: protocolLayer
        )

        let response = try await agent.handlePrompt(request: promptRequest, context: context)
        return try encodeResult(response)
    }

    /// Handle set session mode request (unstable API).
    private func handleSetSessionMode(_ request: JsonRpcRequest) async throws -> JsonValue {
        let modeRequest: SetSessionModeRequest = try decodeParams(request.params)
        let response = try await agent.setSessionMode(request: modeRequest)
        return try encodeResult(response)
    }

    /// Handle set session model request (unstable API).
    private func handleSetSessionModel(_ request: JsonRpcRequest) async throws -> JsonValue {
        let modelRequest: SetSessionModelRequest = try decodeParams(request.params)
        let response = try await agent.setSessionModel(request: modelRequest)
        return try encodeResult(response)
    }

    /// Handle set session config option request (unstable API).
    private func handleSetSessionConfigOption(_ request: JsonRpcRequest) async throws -> JsonValue {
        let configRequest: SetSessionConfigOptionRequest = try decodeParams(request.params)
        let response = try await agent.setSessionConfigOption(request: configRequest)
        return try encodeResult(response)
    }

    // MARK: - Outbound

    /// Send a session update to the client.
    ///
    /// - Parameter update: The session update to send
    /// - Throws: Error if sending fails
    public func sendSessionUpdate(_ update: SessionInfoUpdate) async throws {
        guard state == .connected else {
            throw AgentConnectionError.notConnected
        }

        guard let proto = protocolLayer else {
            throw AgentConnectionError.notConnected
        }

        try await proto.sendNotification(method: "acp/session/update", params: update)
    }

    // MARK: - Helpers

    /// Decode request params to a Codable type.
    private func decodeParams<T: Decodable>(_ params: JsonValue?) throws -> T {
        guard let params = params else {
            throw AgentConnectionError.missingParams
        }

        let data = try JSONEncoder().encode(params)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Encode a Codable result to JsonValue.
    private func encodeResult<T: Encodable>(_ value: T) throws -> JsonValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(JsonValue.self, from: data)
    }

    /// Get JSON-RPC error code for an error.
    private func errorCode(for error: Error) -> Int {
        if let agentError = error as? AgentError {
            return agentError.errorCode
        } else if error is AgentConnectionError {
            return -32600 // Invalid request
        } else {
            return -32603 // Internal error
        }
    }
}

// MARK: - AgentConnection Errors

/// Errors specific to agent connections.
public enum AgentConnectionError: Error, Sendable, LocalizedError {
    /// Invalid state for the operation.
    case invalidState(expected: AgentConnection.State, actual: AgentConnection.State)

    /// Not connected.
    case notConnected

    /// Unknown request method.
    case unknownMethod(String)

    /// Missing request params.
    case missingParams

    /// Failed to decode params.
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidState(let expected, let actual):
            return "Invalid state: expected \(expected), got \(actual)"
        case .notConnected:
            return "Not connected"
        case .unknownMethod(let method):
            return "Unknown method: \(method)"
        case .missingParams:
            return "Missing request params"
        case .decodingFailed(let message):
            return "Failed to decode: \(message)"
        }
    }
}
