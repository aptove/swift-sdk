import Foundation

// MARK: - Cancel Notification

/// Notification to cancel ongoing operations for a session.
///
/// Sent by the client to request cancellation of the current prompt turn.
///
/// See protocol docs: [Cancellation](https://agentclientprotocol.com/protocol/prompt-turn#cancellation)
public struct CancelNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session to cancel operations for
    public let sessionId: SessionId

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a cancel notification.
    ///
    /// - Parameters:
    ///   - sessionId: The session to cancel
    ///   - meta: Optional metadata
    public init(sessionId: SessionId, meta: MetaField? = nil) {
        self.sessionId = sessionId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Cancel Request Notification

/// Notification used to cancel a running request by its ID.
///
/// This is similar to the LSP cancellation mechanism.
public struct CancelRequestNotification: AcpNotification, Codable, Sendable, Hashable {
    /// The ID of the request to cancel
    public let requestId: RequestId

    /// Optional message explaining the cancellation
    public let message: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a cancel request notification.
    ///
    /// - Parameters:
    ///   - requestId: The request to cancel
    ///   - message: Optional explanation
    ///   - meta: Optional metadata
    public init(requestId: RequestId, message: String? = nil, meta: MetaField? = nil) {
        self.requestId = requestId
        self.message = message
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case requestId = "requestId"
        case message = "message"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}
