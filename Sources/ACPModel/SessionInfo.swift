// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Anthropic, PBC

/// Information about a session returned by session/list.
///
/// Contains metadata about an existing session including its ID,
/// working directory, optional title, and last update time.
///
/// - Note: This is an **UNSTABLE** API that may change without notice.
///
/// ## Example
/// ```swift
/// let sessions = try await client.listSessions()
/// for session in sessions.sessions {
///     print("Session \(session.sessionId): \(session.title ?? "Untitled")")
/// }
/// ```
@available(*, message: "Unstable API - may change without notice")
public struct SessionInfo: Codable, Sendable, Hashable {
    /// Unique identifier for this session.
    public let sessionId: SessionId

    /// The working directory for this session.
    public let cwd: String

    /// Optional human-readable title for this session.
    public let title: String?

    /// ISO 8601 timestamp of when this session was last updated.
    public let updatedAt: String?

    /// Optional metadata for protocol extensibility.
    public let _meta: JsonValue? // swiftlint:disable:this identifier_name

    /// Creates a new session info.
    ///
    /// - Parameters:
    ///   - sessionId: Unique identifier for this session
    ///   - cwd: The working directory for this session
    ///   - title: Optional human-readable title
    ///   - updatedAt: Optional ISO 8601 timestamp of last update
    ///   - _meta: Optional metadata for protocol extensibility
    public init(
        sessionId: SessionId,
        cwd: String,
        title: String? = nil,
        updatedAt: String? = nil,
        _meta: JsonValue? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.title = title
        self.updatedAt = updatedAt
        self._meta = _meta
    }
}
