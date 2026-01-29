import ACPModel
import Foundation

/// Manages an agent's connection with a client over a transport.
///
/// AgentConnection handles the ACP protocol lifecycle on the agent side:
/// - Receives initialization requests and responds with agent capabilities
/// - Routes incoming requests (session creation, prompts) to the Agent implementation
/// - Sends session updates to the client
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

    /// The agent implementation.
    private let agent: any Agent

    /// Current connection state.
    public private(set) var state: State = .disconnected

    /// Client info received during initialization.
    public private(set) var clientInfo: Implementation?

    /// Client capabilities received during initialization.
    public private(set) var clientCapabilities: ClientCapabilities?

    /// Task handling incoming requests.
    private var messageHandler: Task<Void, Never>?

    /// Pending request handlers that can be cancelled.
    /// Maps request ID to the Task handling that request.
    private var pendingRequestTasks: [RequestId: Task<Void, Never>] = [:]

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
            try await transport.start()
            state = .connected

            // Start handling messages in background
            messageHandler = Task { [weak self] in
                await self?.handleMessages()
            }
        } catch {
            state = .disconnected
            throw error
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
        await transport.close()
        state = .disconnected
    }

    // MARK: - Message Handling

    /// Handle incoming messages from the transport.
    private func handleMessages() async {
        for await message in transport.messages {
            switch message {
            case .request(let request):
                await handleRequest(request)
            case .notification(let notification):
                await handleNotification(notification)
            case .response, .error:
                // Agent doesn't receive responses
                break
            }
        }

        // Transport closed
        state = .disconnected
    }

    /// Handle an incoming request.
    private func handleRequest(_ request: JsonRpcRequest) async {
        // Create a task to handle the request so it can be cancelled
        let requestTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                let result = try await self.routeRequest(request)
                let response = JsonRpcResponse(id: request.id, result: result)
                try await self.transport.send(.response(response))
            } catch is CancellationError {
                // Request was cancelled - send cancelled error response
                let errorResponse = JsonRpcError(
                    id: request.id,
                    error: JsonRpcError.ErrorInfo(
                        code: -32800, // Request cancelled
                        message: "Request cancelled",
                        data: nil
                    )
                )
                try? await self.transport.send(.error(errorResponse))
            } catch {
                let errorCode = await self.errorCode(for: error)
                let errorResponse = JsonRpcError(
                    id: request.id,
                    error: JsonRpcError.ErrorInfo(
                        code: errorCode,
                        message: error.localizedDescription,
                        data: nil
                    )
                )
                try? await self.transport.send(.error(errorResponse))
            }

            // Remove from pending tasks when done
            await self.removePendingRequestTask(requestId: request.id)
        }

        // Track the request task
        pendingRequestTasks[request.id] = requestTask
    }

    /// Remove a pending request task.
    private func removePendingRequestTask(requestId: RequestId) {
        pendingRequestTasks.removeValue(forKey: requestId)
    }

    /// Route a request to the appropriate handler.
    private func routeRequest(_ request: JsonRpcRequest) async throws -> JsonValue {
        switch request.method {
        case "initialize":
            return try await handleInitialize(request)
        case "session/new":
            return try await handleNewSession(request)
        case "session/load":
            return try await handleLoadSession(request)
        case "session/prompt":
            return try await handlePrompt(request)
        default:
            throw AgentConnectionError.unknownMethod(request.method)
        }
    }

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

    /// Handle prompt request.
    private func handlePrompt(_ request: JsonRpcRequest) async throws -> JsonValue {
        let promptRequest: PromptRequest = try decodeParams(request.params)
        let response = try await agent.handlePrompt(request: promptRequest)
        return try encodeResult(response)
    }

    /// Handle an incoming notification.
    private func handleNotification(_ notification: JsonRpcNotification) async {
        switch notification.method {
        case "$/cancelRequest":
            await handleCancelRequest(notification)
        default:
            // Other notifications are currently ignored
            break
        }
    }

    /// Handle a cancel request notification.
    private func handleCancelRequest(_ notification: JsonRpcNotification) async {
        guard let params = notification.params else { return }

        do {
            let data = try JSONEncoder().encode(params)
            let cancelNotification = try JSONDecoder().decode(CancelRequestNotification.self, from: data)

            // Find and cancel the pending request task
            if let task = pendingRequestTasks.removeValue(forKey: cancelNotification.requestId) {
                task.cancel()
            }
        } catch {
            // Ignore malformed cancel notifications
        }
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

        let params = try encodeResult(update)
        let notification = JsonRpcNotification(method: "acp/session/update", params: params)
        try await transport.send(.notification(notification))
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
