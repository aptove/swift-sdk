import Foundation

// MARK: - V2NewSessionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/new` method.
public struct V2NewSessionRequest: Codable, Sendable, Hashable {
    public let cwd: String
    public let mcpServers: [V2McpServer]
    public let additionalDirectories: [String]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        cwd: String,
        mcpServers: [V2McpServer] = [],
        additionalDirectories: [String] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.cwd = cwd
        self.mcpServers = mcpServers
        self.additionalDirectories = additionalDirectories
        self._meta = _meta
    }
}

// MARK: - V2NewSessionResponse

/// **UNSTABLE** - Response to the v2 `session/new` method.
///
/// Unlike v1 there are no separate `modes` and `models` fields: everything configurable
/// arrives as `V2SessionConfigOption`s.
public struct V2NewSessionResponse: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let configOptions: [V2SessionConfigOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        configOptions: [V2SessionConfigOption] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.configOptions = configOptions
        self._meta = _meta
    }
}

// MARK: - V2PromptRequest

/// **UNSTABLE** - Request parameters for the v2 `session/prompt` method.
public struct V2PromptRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let prompt: [V2ContentBlock]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        prompt: [V2ContentBlock],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.prompt = prompt
        self._meta = _meta
    }
}

// MARK: - V2PromptResponse

/// **UNSTABLE** - Response to the v2 `session/prompt` method.
///
/// Deliberately empty: v2 moved the turn outcome into session updates (`V2StateUpdate.idle`).
public struct V2PromptResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2UpdateSessionNotification

/// **UNSTABLE** - The v2 `session/update` notification: one update for one session.
public struct V2UpdateSessionNotification: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let update: V2SessionUpdate
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        update: V2SessionUpdate,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.update = update
        self._meta = _meta
    }
}

// MARK: - V2CancelSessionNotification

/// **UNSTABLE** - The v2 `session/cancel` notification.
///
/// Carries only the session; the agent reports the interrupted turn outcome as a
/// `V2StateUpdate.idle` update.
public struct V2CancelSessionNotification: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId
        self._meta = _meta
    }
}

// MARK: - V2SessionInfo

/// **UNSTABLE** - Information about an existing session, as reported by v2 `session/list`.
public struct V2SessionInfo: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let cwd: String
    public let additionalDirectories: [String]
    public let title: String?
    public let updatedAt: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        cwd: String,
        additionalDirectories: [String] = [],
        title: String? = nil,
        updatedAt: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.additionalDirectories = additionalDirectories
        self.title = title
        self.updatedAt = updatedAt
        self._meta = _meta
    }
}

// MARK: - V2ListSessionsRequest

/// **UNSTABLE** - Request parameters for the v2 `session/list` method.
public struct V2ListSessionsRequest: Codable, Sendable, Hashable {
    public let cwd: String?
    public let cursor: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        cwd: String? = nil,
        cursor: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.cwd = cwd
        self.cursor = cursor
        self._meta = _meta
    }
}

// MARK: - V2ListSessionsResponse

/// **UNSTABLE** - Response to the v2 `session/list` method.
public struct V2ListSessionsResponse: Codable, Sendable, Hashable {
    public let sessions: [V2SessionInfo]
    public let nextCursor: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessions: [V2SessionInfo],
        nextCursor: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessions = sessions
        self.nextCursor = nextCursor
        self._meta = _meta
    }
}

// MARK: - V2CloseSessionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/close` method.
public struct V2CloseSessionRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId
        self._meta = _meta
    }
}

// MARK: - V2CloseSessionResponse

/// **UNSTABLE** - Response to the v2 `session/close` method.
public struct V2CloseSessionResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2DeleteSessionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/delete` method.
///
/// Deleting removes a session from what `session/list` reports; closing only ends the active one.
public struct V2DeleteSessionRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId
        self._meta = _meta
    }
}

// MARK: - V2DeleteSessionResponse

/// **UNSTABLE** - Response to the v2 `session/delete` method.
public struct V2DeleteSessionResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}
