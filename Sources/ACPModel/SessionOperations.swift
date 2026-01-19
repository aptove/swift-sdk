// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Anthropic, PBC

// MARK: - List Sessions

/// Request parameters for listing existing sessions.
///
/// Only available if the Agent supports the `session.list` capability.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
///
/// ## Example
/// ```swift
/// let request = ListSessionsRequest(cwd: "/home/user/project")
/// ```
@available(*, message: "Unstable API - may change without notice")
public struct ListSessionsRequest: Codable, Sendable, Hashable {
    /// Opaque cursor token from a previous response's nextCursor field.
    public let cursor: Cursor?

    /// Optional filter to list sessions from a specific working directory.
    public let cwd: String?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a list sessions request.
    ///
    /// - Parameters:
    ///   - cursor: Optional pagination cursor from previous response
    ///   - cwd: Optional filter by working directory
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        cursor: Cursor? = nil,
        cwd: String? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.cursor = cursor
        self.cwd = cwd
        self._meta = _meta
    }
}

/// Response from listing sessions.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
///
/// ## Example
/// ```swift
/// let response = try await client.listSessions()
/// for session in response.sessions {
///     print("Session: \(session.sessionId)")
/// }
/// if let next = response.nextCursor {
///     // Fetch next page
/// }
/// ```
@available(*, message: "Unstable API - may change without notice")
public struct ListSessionsResponse: Codable, Sendable, Hashable {
    /// Array of session information objects.
    public let sessions: [SessionInfo]

    /// Opaque cursor token for fetching the next page.
    /// If nil, there are no more results.
    public let nextCursor: Cursor?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a list sessions response.
    ///
    /// - Parameters:
    ///   - sessions: Array of session information objects
    ///   - nextCursor: Optional cursor for next page
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        sessions: [SessionInfo],
        nextCursor: Cursor? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessions = sessions
        self.nextCursor = nextCursor
        self._meta = _meta
    }
}

// MARK: - Fork Session

/// Request parameters for forking an existing session.
///
/// Creates a new session based on the context of an existing one, allowing
/// operations like generating summaries without affecting the original session's history.
///
/// Only available if the Agent supports the `session.fork` capability.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
///
/// ## Example
/// ```swift
/// let request = ForkSessionRequest(
///     sessionId: "original-session-id",
///     cwd: "/home/user/project"
/// )
/// ```
@available(*, message: "Unstable API - may change without notice")
public struct ForkSessionRequest: Codable, Sendable, Hashable {
    /// The ID of the session to fork.
    public let sessionId: SessionId

    /// The working directory for the new forked session.
    public let cwd: String

    /// List of MCP servers to connect to for this session.
    public let mcpServers: [McpServer]?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a fork session request.
    ///
    /// - Parameters:
    ///   - sessionId: The ID of the session to fork
    ///   - cwd: The working directory for the new session
    ///   - mcpServers: Optional list of MCP servers to connect
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        sessionId: SessionId,
        cwd: String,
        mcpServers: [McpServer]? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.mcpServers = mcpServers
        self._meta = _meta
    }
}

/// Response from forking a session.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
@available(*, message: "Unstable API - may change without notice")
public struct ForkSessionResponse: Codable, Sendable, Hashable {
    /// Unique identifier for the newly created forked session.
    public let sessionId: SessionId

    /// Initial session configuration options if supported by the Agent.
    public let configOptions: [SessionConfigOption]?

    /// Initial model state if supported by the Agent.
    public let models: SessionModelState?

    /// Initial mode state if supported by the Agent.
    public let modes: SessionModeState?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a fork session response.
    ///
    /// - Parameters:
    ///   - sessionId: The ID of the newly forked session
    ///   - configOptions: Optional initial configuration options
    ///   - models: Optional initial model state
    ///   - modes: Optional initial mode state
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        sessionId: SessionId,
        configOptions: [SessionConfigOption]? = nil,
        models: SessionModelState? = nil,
        modes: SessionModeState? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.configOptions = configOptions
        self.models = models
        self.modes = modes
        self._meta = _meta
    }
}

// MARK: - Resume Session

/// Request parameters for resuming an existing session.
///
/// Resumes an existing session without returning previous messages (unlike `session/load`).
/// This is useful for agents that can resume sessions but don't implement full session loading.
///
/// Only available if the Agent supports the `session.resume` capability.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
///
/// ## Example
/// ```swift
/// let request = ResumeSessionRequest(
///     sessionId: "existing-session-id",
///     cwd: "/home/user/project"
/// )
/// ```
@available(*, message: "Unstable API - may change without notice")
public struct ResumeSessionRequest: Codable, Sendable, Hashable {
    /// The ID of the session to resume.
    public let sessionId: SessionId

    /// The working directory for this session.
    public let cwd: String

    /// List of MCP servers to connect to for this session.
    public let mcpServers: [McpServer]?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a resume session request.
    ///
    /// - Parameters:
    ///   - sessionId: The ID of the session to resume
    ///   - cwd: The working directory for the session
    ///   - mcpServers: Optional list of MCP servers to connect
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        sessionId: SessionId,
        cwd: String,
        mcpServers: [McpServer]? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.mcpServers = mcpServers
        self._meta = _meta
    }
}

/// Response from resuming a session.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
@available(*, message: "Unstable API - may change without notice")
public struct ResumeSessionResponse: Codable, Sendable, Hashable {
    /// Initial session configuration options if supported by the Agent.
    public let configOptions: [SessionConfigOption]?

    /// Initial model state if supported by the Agent.
    public let models: SessionModelState?

    /// Initial mode state if supported by the Agent.
    public let modes: SessionModeState?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a resume session response.
    ///
    /// - Parameters:
    ///   - configOptions: Optional initial configuration options
    ///   - models: Optional initial model state
    ///   - modes: Optional initial mode state
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        configOptions: [SessionConfigOption]? = nil,
        models: SessionModelState? = nil,
        modes: SessionModeState? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.configOptions = configOptions
        self.models = models
        self.modes = modes
        self._meta = _meta
    }
}
