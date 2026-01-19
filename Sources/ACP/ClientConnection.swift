import ACPModel
import Foundation

/// Manages a client's connection to an agent over a transport.
///
/// ClientConnection handles the ACP protocol lifecycle on the client side:
/// - Sends initialization requests with client capabilities
/// - Creates and loads sessions on the agent
/// - Sends prompts and receives responses
/// - Receives session updates from the agent
///
/// ## Usage
///
/// ```swift
/// let transport = StdioTransport()
/// let client = MyClient()
/// let connection = ClientConnection(transport: transport, client: client)
///
/// // Connect and initialize
/// let agentInfo = try await connection.connect()
///
/// // Create a session
/// let session = try await connection.createSession(
///     request: NewSessionRequest()
/// )
///
/// // Send a prompt
/// let response = try await connection.prompt(
///     request: PromptRequest(sessionId: session.sessionId)
/// )
///
/// // Disconnect when done
/// try await connection.disconnect()
/// ```
public actor ClientConnection {
    // MARK: - State

    /// Current connection state.
    public enum State: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    /// The underlying protocol layer.
    private let protocolLayer: Protocol

    /// The client delegate.
    private let client: any Client

    /// Current connection state.
    public private(set) var state: State = .disconnected

    /// Agent info received during initialization.
    public private(set) var agentInfo: Implementation?

    /// Agent capabilities received during initialization.
    public private(set) var agentCapabilities: AgentCapabilities?

    /// Protocol version negotiated during initialization.
    public private(set) var protocolVersion: ProtocolVersion?

    /// Task handling incoming notifications.
    private var notificationHandler: Task<Void, Never>?

    // MARK: - Initialization

    /// Create a client connection with a transport and client.
    ///
    /// - Parameters:
    ///   - transport: Transport for communication
    ///   - client: Client delegate to receive callbacks
    public init(transport: any Transport, client: any Client) {
        self.protocolLayer = Protocol(transport: transport)
        self.client = client
    }

    // MARK: - Lifecycle

    /// Connect to the agent and perform initialization.
    ///
    /// - Parameter version: Protocol version to request (defaults to current)
    /// - Returns: The agent info from the initialization response
    /// - Throws: Error if connection fails
    @discardableResult
    public func connect(version: ProtocolVersion = .current) async throws -> Implementation? {
        guard state == .disconnected else {
            throw ClientError.alreadyConnected
        }

        state = .connecting

        do {
            // Start the protocol layer
            try await protocolLayer.start()

            // Register notification handler for session updates
            await registerNotificationHandlers()

            // Send initialize request
            let initRequest = InitializeRequest(
                protocolVersion: version,
                clientCapabilities: client.capabilities,
                clientInfo: client.info
            )

            let response = try await protocolLayer.initialize(request: initRequest)

            // Store agent info
            self.agentInfo = response.agentInfo
            self.agentCapabilities = response.agentCapabilities
            self.protocolVersion = response.protocolVersion

            state = .connected

            // Notify client
            await client.onConnected()

            return response.agentInfo
        } catch {
            state = .disconnected
            throw error
        }
    }

    /// Disconnect from the agent.
    public func disconnect() async {
        guard state == .connected else {
            return
        }

        state = .disconnecting

        // Stop notification handler
        notificationHandler?.cancel()
        notificationHandler = nil

        // Close protocol layer
        await protocolLayer.close()

        state = .disconnected

        // Notify client
        await client.onDisconnected(error: nil)
    }

    // MARK: - Session Operations

    /// Create a new session on the agent.
    ///
    /// - Parameter request: Session creation parameters
    /// - Returns: Session creation response
    /// - Throws: Error if session creation fails
    public func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        guard state == .connected else {
            throw ClientError.notConnected
        }

        return try await protocolLayer.createSession(request: request)
    }

    /// Load an existing session on the agent.
    ///
    /// - Parameter request: Session load parameters
    /// - Returns: Session load response
    /// - Throws: Error if session loading fails
    public func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
        guard state == .connected else {
            throw ClientError.notConnected
        }

        return try await protocolLayer.loadSession(request: request)
    }

    // MARK: - Unstable Session Operations

    /// List existing sessions from the agent.
    ///
    /// This method is only available if the agent advertises the `session.list` capability.
    ///
    /// - Note: This is an **UNSTABLE** API that may change without notice.
    ///
    /// - Parameter request: The list sessions request with optional filters
    /// - Returns: List of sessions with optional pagination cursor
    /// - Throws: Error if listing fails or capability not supported
    @available(*, message: "Unstable API - may change without notice")
    public func listSessions(request: ListSessionsRequest) async throws -> ListSessionsResponse {
        guard state == .connected else {
            throw ClientError.notConnected
        }

        return try await protocolLayer.request(
            method: "session/list",
            params: request,
            responseType: ListSessionsResponse.self
        )
    }

    /// Fork an existing session to create a new independent session.
    ///
    /// Creates a new session based on the context of an existing one, allowing
    /// operations like generating summaries without affecting the original session's history.
    ///
    /// This method is only available if the agent advertises the `session.fork` capability.
    ///
    /// - Note: This is an **UNSTABLE** API that may change without notice.
    ///
    /// - Parameter request: The fork session request
    /// - Returns: Response with the new session ID and initial state
    /// - Throws: Error if forking fails or capability not supported
    @available(*, message: "Unstable API - may change without notice")
    public func forkSession(request: ForkSessionRequest) async throws -> ForkSessionResponse {
        guard state == .connected else {
            throw ClientError.notConnected
        }

        return try await protocolLayer.request(
            method: "session/fork",
            params: request,
            responseType: ForkSessionResponse.self
        )
    }

    /// Resume an existing session without returning previous messages.
    ///
    /// This method is only available if the agent advertises the `session.resume` capability.
    /// Unlike `loadSession`, this does not replay the message history.
    ///
    /// - Note: This is an **UNSTABLE** API that may change without notice.
    ///
    /// - Parameter request: The resume session request
    /// - Returns: Response with initial session state
    /// - Throws: Error if resuming fails or capability not supported
    @available(*, message: "Unstable API - may change without notice")
    public func resumeSession(request: ResumeSessionRequest) async throws -> ResumeSessionResponse {
        guard state == .connected else {
            throw ClientError.notConnected
        }

        return try await protocolLayer.request(
            method: "session/resume",
            params: request,
            responseType: ResumeSessionResponse.self
        )
    }

    // MARK: - Prompt Operations

    /// Send a prompt to the agent.
    ///
    /// - Parameter request: The prompt request
    /// - Returns: The prompt response
    /// - Throws: Error if prompt fails
    public func prompt(request: PromptRequest) async throws -> PromptResponse {
        guard state == .connected else {
            throw ClientError.notConnected
        }

        return try await protocolLayer.prompt(request: request)
    }

    // MARK: - Notification Handling

    /// Register notification handlers with the protocol layer.
    private func registerNotificationHandlers() async {
        await protocolLayer.onNotification(method: "acp/session/update") { [weak self] notification in
            await self?.handleSessionUpdate(notification)
        }
    }

    /// Handle a session update notification.
    private func handleSessionUpdate(_ notification: JsonRpcNotification) async {
        guard let params = notification.params else { return }

        do {
            let data = try JSONEncoder().encode(params)
            let update = try JSONDecoder().decode(SessionInfoUpdate.self, from: data)
            await client.onSessionUpdate(update)
        } catch {
            // Failed to decode notification - ignore
        }
    }
}
