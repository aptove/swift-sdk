import Foundation

// MARK: - Set Session Mode Request

/// Request parameters for setting a session mode.
///
/// Changes the agent's operating mode for the session.
///
/// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
public struct SetSessionModeRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session to change the mode for
    public let sessionId: SessionId

    /// The mode to switch to
    public let modeId: SessionModeId

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a set session mode request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - modeId: The mode to switch to
    ///   - meta: Optional metadata
    public init(
        sessionId: SessionId,
        modeId: SessionModeId,
        meta: MetaField? = nil
    ) {
        self.sessionId = sessionId
        self.modeId = modeId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case modeId = "modeId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Set Session Mode Response

/// Response to `session/set_mode` method.
///
/// Confirms the mode change request was received. The actual mode change
/// will be reported via session updates.
public struct SetSessionModeResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a set session mode response.
    ///
    /// - Parameter meta: Optional metadata
    public init(meta: MetaField? = nil) {
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}
