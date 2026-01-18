import ACPModel
import Foundation

/// Parameters used when creating a session.
///
/// Captures the configuration used to create a session for reference.
public struct SessionCreationParameters: Sendable {
    /// Working directory for the session
    public let cwd: String

    /// MCP servers configured for the session
    public let mcpServers: [McpServer]

    /// Creates session creation parameters.
    ///
    /// - Parameters:
    ///   - cwd: Working directory
    ///   - mcpServers: MCP server configurations
    public init(cwd: String, mcpServers: [McpServer] = []) {
        self.cwd = cwd
        self.mcpServers = mcpServers
    }
}

/// A session with an agent.
///
/// ClientSession provides a high-level interface for interacting with an agent session.
/// It handles prompt execution with event streaming, cancellation, and mode changes.
///
/// ## Usage
///
/// ```swift
/// // Create a session through ClientConnection
/// let session = try await connection.session(cwd: "/path/to/project")
///
/// // Send a prompt and stream events
/// let events = session.prompt(content: [.text(TextContent(text: "Hello"))])
/// for await event in events {
///     switch event {
///     case .sessionUpdate(let update):
///         print("Update received")
///     case .promptResponse(let response):
///         print("Done: \(response.stopReason)")
///     }
/// }
///
/// // Cancel if needed
/// try await session.cancel()
/// ```
public protocol ClientSession: Sendable {
    /// The session identifier
    var sessionId: SessionId { get }

    /// The parameters used to create this session
    var parameters: SessionCreationParameters { get }

    /// Whether the agent supports session modes
    var modesSupported: Bool { get }

    /// Available session modes (empty if not supported)
    var availableModes: [SessionMode] { get }

    /// Current mode ID (throws if modes not supported)
    var currentModeId: SessionModeId { get async throws }

    /// Send a prompt to the agent and stream events.
    ///
    /// Returns an AsyncStream that yields session updates as they arrive,
    /// followed by the final prompt response.
    ///
    /// - Parameters:
    ///   - content: The content blocks to send
    ///   - meta: Optional metadata
    /// - Returns: Stream of events from the agent
    func prompt(content: [ContentBlock], meta: MetaField?) -> AsyncStream<Event>

    /// Cancel the current prompt turn.
    ///
    /// Requests the agent to stop processing and clean up.
    /// The final event will have stopReason = .cancelled.
    func cancel() async throws

    /// Change the session mode.
    ///
    /// - Parameters:
    ///   - modeId: The mode to switch to
    ///   - meta: Optional metadata
    /// - Returns: Response confirming the request
    /// - Throws: Error if modes not supported or mode change fails
    func setMode(_ modeId: SessionModeId, meta: MetaField?) async throws -> SetSessionModeResponse
}

// MARK: - Default Implementations

extension ClientSession {
    /// Convenience method without metadata.
    public func prompt(content: [ContentBlock]) -> AsyncStream<Event> {
        prompt(content: content, meta: nil)
    }

    /// Convenience method without metadata.
    public func setMode(_ modeId: SessionModeId) async throws -> SetSessionModeResponse {
        try await setMode(modeId, meta: nil)
    }
}
