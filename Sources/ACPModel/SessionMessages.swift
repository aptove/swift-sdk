import Foundation

// MARK: - Session Creation

/// Request to create a new session.
///
/// See protocol docs: [Creating a Session](https://agentclientprotocol.com/protocol/session-setup#creating-a-session)
public struct NewSessionRequest: AcpRequest, Codable, Sendable, Hashable {
    /// Current working directory for the session
    public let cwd: String

    /// MCP servers to configure for this session
    public let mcpServers: [McpServer]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a new session request.
    public init(
        cwd: String,
        mcpServers: [McpServer],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.cwd = cwd
        self.mcpServers = mcpServers
        self._meta = _meta
    }
}

/// Response from creating a new session.
///
/// See protocol docs: [Creating a Session](https://agentclientprotocol.com/protocol/session-setup#creating-a-session)
public struct NewSessionResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The ID of the newly created session
    public let sessionId: SessionId

    /// Current mode state
    public let modes: SessionModeState?

    /// Current model state (unstable)
    public let models: SessionModelState?

    /// Configuration options (unstable)
    public let configOptions: [SessionConfigOption]?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a new session response.
    public init(
        sessionId: SessionId,
        modes: SessionModeState? = nil,
        models: SessionModelState? = nil,
        configOptions: [SessionConfigOption]? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.modes = modes
        self.models = models
        self.configOptions = configOptions
        self._meta = _meta
    }
}

// MARK: - Session Loading

/// Request to load an existing session.
///
/// Only available if the agent supports the `loadSession` capability.
///
/// See protocol docs: [Loading Sessions](https://agentclientprotocol.com/protocol/session-setup#loading-sessions)
public struct LoadSessionRequest: AcpRequest, Codable, Sendable, Hashable {
    /// ID of the session to load
    public let sessionId: SessionId

    /// Current working directory for the session
    public let cwd: String

    /// MCP servers to configure for this session
    public let mcpServers: [McpServer]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a load session request.
    public init(
        sessionId: SessionId,
        cwd: String,
        mcpServers: [McpServer],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.mcpServers = mcpServers
        self._meta = _meta
    }
}

/// Response from loading an existing session.
public struct LoadSessionResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Current mode state
    public let modes: SessionModeState?

    /// Current model state (unstable)
    public let models: SessionModelState?

    /// Configuration options (unstable)
    public let configOptions: [SessionConfigOption]?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a load session response.
    public init(
        modes: SessionModeState? = nil,
        models: SessionModelState? = nil,
        configOptions: [SessionConfigOption]? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.modes = modes
        self.models = models
        self.configOptions = configOptions
        self._meta = _meta
    }
}

// MARK: - Prompting

/// Request to send a user prompt to the agent.
///
/// Contains the user's message and any additional context.
///
/// See protocol docs: [User Message](https://agentclientprotocol.com/protocol/prompt-turn#1-user-message)
public struct PromptRequest: AcpRequest, Codable, Sendable, Hashable {
    /// The session ID
    public let sessionId: SessionId

    /// The user's prompt as a list of content blocks
    public let prompt: [ContentBlock]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a prompt request.
    public init(
        sessionId: SessionId,
        prompt: [ContentBlock],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.prompt = prompt
        self._meta = _meta
    }
}

/// Reasons why an agent stops processing a prompt turn.
///
/// See protocol docs: [Stop Reasons](https://agentclientprotocol.com/protocol/prompt-turn#stop-reasons)
public enum StopReason: String, Codable, Sendable, Hashable {
    /// Natural completion of the turn
    case endTurn = "end_turn"

    /// Maximum tokens limit reached
    case maxTokens = "max_tokens"

    /// Maximum turn requests limit reached
    case maxTurnRequests = "max_turn_requests"

    /// Agent refused to continue
    case refusal = "refusal"

    /// Request was cancelled
    case cancelled = "cancelled"
}

/// Response from processing a user prompt.
///
/// See protocol docs: [Check for Completion](https://agentclientprotocol.com/protocol/prompt-turn#4-check-for-completion)
public struct PromptResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The reason the agent stopped processing
    public let stopReason: StopReason

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a prompt response.
    public init(
        stopReason: StopReason,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.stopReason = stopReason
        self._meta = _meta
    }
}

// MARK: - Session Notifications

/// Notification containing session updates from the agent.
///
/// See protocol docs: [Agent Reports Output](https://agentclientprotocol.com/protocol/prompt-turn#3-agent-reports-output)
public struct SessionNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session ID
    public let sessionId: SessionId

    /// The update being reported
    public let update: SessionUpdate

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a session notification.
    public init(
        sessionId: SessionId,
        update: SessionUpdate,
        meta: MetaField? = nil
    ) {
        self.sessionId = sessionId
        self.update = update
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case update = "update"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}
