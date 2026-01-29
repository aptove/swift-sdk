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

    // MARK: - Model Selection (Unstable API)

    /// **UNSTABLE** - Whether the agent supports model selection.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    var modelsSupported: Bool { get }

    /// **UNSTABLE** - Available models for this session.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    /// Returns an empty array if models are not supported.
    var availableModels: [ModelInfo] { get }

    /// **UNSTABLE** - The current model ID.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    ///
    /// - Throws: Error if models not supported
    var currentModelId: ModelId { get async throws }

    /// **UNSTABLE** - Change the session model.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    ///
    /// - Parameters:
    ///   - modelId: The model to switch to
    ///   - meta: Optional metadata
    /// - Returns: Response confirming the request
    /// - Throws: Error if models not supported or model change fails
    @available(*, message: "Unstable API - may change without notice")
    func setModel(_ modelId: ModelId, meta: MetaField?) async throws -> SetSessionModelResponse

    // MARK: - Configuration Options (Unstable API)

    /// **UNSTABLE** - Whether the agent supports configuration options.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    var configOptionsSupported: Bool { get }

    /// **UNSTABLE** - Available configuration options for this session.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    /// Returns an empty array if config options are not supported.
    var configOptions: [SessionConfigOption] { get async throws }

    /// **UNSTABLE** - Set a configuration option value.
    ///
    /// This capability is not part of the spec yet, and may be removed or changed at any point.
    ///
    /// - Parameters:
    ///   - configId: The configuration option identifier
    ///   - value: The value to set
    ///   - meta: Optional metadata
    /// - Returns: Response with updated configuration options
    /// - Throws: Error if config options not supported or change fails
    @available(*, message: "Unstable API - may change without notice")
    func setConfigOption(
        _ configId: SessionConfigId,
        value: SessionConfigValueId,
        meta: MetaField?
    ) async throws -> SetSessionConfigOptionResponse
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

    /// **UNSTABLE** - Convenience method without metadata.
    @available(*, message: "Unstable API - may change without notice")
    public func setModel(_ modelId: ModelId) async throws -> SetSessionModelResponse {
        try await setModel(modelId, meta: nil)
    }

    /// **UNSTABLE** - Convenience method without metadata.
    @available(*, message: "Unstable API - may change without notice")
    public func setConfigOption(
        _ configId: SessionConfigId,
        value: SessionConfigValueId
    ) async throws -> SetSessionConfigOptionResponse {
        try await setConfigOption(configId, value: value, meta: nil)
    }
}
