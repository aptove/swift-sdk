import ACPModel
import Foundation

/// Context provided to agents during prompt handling.
///
/// The `AgentContext` provides access to client operations that agents can use
/// during prompt processing. This allows agents to:
/// - Request permissions from the client
/// - Read/write files on the client
/// - Execute terminal commands on the client
/// - Send notifications to the client
///
/// ## Usage
///
/// The context is passed to the `handlePrompt` method:
///
/// ```swift
/// func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
///     // Read a file from the client
///     let content = try await context.readTextFile(path: "/path/to/file")
///
///     // Request permission for an operation
///     let permission = try await context.requestPermissions(
///         toolCall: toolCall,
///         permissions: options
///     )
///
///     return PromptResponse(stopReason: .endTurn)
/// }
/// ```
public protocol AgentContext: Sendable {
    /// The session ID for this context.
    var sessionId: SessionId { get }

    /// The client capabilities.
    var clientCapabilities: ClientCapabilities { get }

    // MARK: - Permission Operations

    /// Request permissions from the client for a tool call.
    ///
    /// - Parameters:
    ///   - toolCall: The tool call that needs permission
    ///   - permissions: Available permission options
    ///   - meta: Optional metadata
    /// - Returns: The client's permission response
    /// - Throws: Error if the request fails or client doesn't respond
    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse

    /// Send a notification to the client.
    ///
    /// - Parameters:
    ///   - notification: The session update to send
    ///   - meta: Optional metadata
    func notify(notification: SessionUpdate, meta: MetaField?) async throws

    // MARK: - File System Operations

    /// Read a text file from the client.
    ///
    /// Requires `fs.readTextFile` capability.
    ///
    /// - Parameters:
    ///   - path: Path to the file
    ///   - line: Optional starting line number
    ///   - limit: Optional line limit
    ///   - meta: Optional metadata
    /// - Returns: The file content
    /// - Throws: Error if client doesn't support this capability or read fails
    func readTextFile(
        path: String,
        line: UInt32?,
        limit: UInt32?,
        meta: MetaField?
    ) async throws -> ReadTextFileResponse

    /// Write a text file on the client.
    ///
    /// Requires `fs.writeTextFile` capability.
    ///
    /// - Parameters:
    ///   - path: Path to the file
    ///   - content: Content to write
    ///   - meta: Optional metadata
    /// - Returns: The write response
    /// - Throws: Error if client doesn't support this capability or write fails
    func writeTextFile(
        path: String,
        content: String,
        meta: MetaField?
    ) async throws -> WriteTextFileResponse

    // MARK: - Terminal Operations

    /// Create a terminal on the client.
    ///
    /// Requires `terminal` capability.
    ///
    /// - Parameters:
    ///   - command: Command to execute
    ///   - args: Command arguments
    ///   - cwd: Working directory
    ///   - env: Environment variables
    ///   - outputByteLimit: Maximum output size
    ///   - meta: Optional metadata
    /// - Returns: Terminal creation response
    /// - Throws: Error if client doesn't support this capability
    func terminalCreate(
        command: String,
        args: [String],
        cwd: String?,
        env: [EnvVariable],
        outputByteLimit: UInt64?,
        meta: MetaField?
    ) async throws -> CreateTerminalResponse

    /// Get terminal output from the client.
    ///
    /// - Parameters:
    ///   - terminalId: Terminal identifier
    ///   - meta: Optional metadata
    /// - Returns: Terminal output response
    func terminalOutput(
        terminalId: String,
        meta: MetaField?
    ) async throws -> TerminalOutputResponse

    /// Wait for terminal to exit.
    ///
    /// - Parameters:
    ///   - terminalId: Terminal identifier
    ///   - meta: Optional metadata
    /// - Returns: Exit response with exit code
    func terminalWaitForExit(
        terminalId: String,
        meta: MetaField?
    ) async throws -> WaitForTerminalExitResponse

    /// Kill a terminal.
    ///
    /// - Parameters:
    ///   - terminalId: Terminal identifier
    ///   - meta: Optional metadata
    /// - Returns: Kill response
    func terminalKill(
        terminalId: String,
        meta: MetaField?
    ) async throws -> KillTerminalCommandResponse

    /// Release a terminal.
    ///
    /// - Parameters:
    ///   - terminalId: Terminal identifier
    ///   - meta: Optional metadata
    /// - Returns: Release response
    func terminalRelease(
        terminalId: String,
        meta: MetaField?
    ) async throws -> ReleaseTerminalResponse
}

// MARK: - Convenience Extensions

public extension AgentContext {
    /// Read a text file with default parameters.
    func readTextFile(path: String) async throws -> ReadTextFileResponse {
        try await readTextFile(path: path, line: nil, limit: nil, meta: nil)
    }

    /// Write a text file with default parameters.
    func writeTextFile(path: String, content: String) async throws -> WriteTextFileResponse {
        try await writeTextFile(path: path, content: content, meta: nil)
    }

    /// Request permissions with default metadata.
    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption]
    ) async throws -> RequestPermissionResponse {
        try await requestPermissions(toolCall: toolCall, permissions: permissions, meta: nil)
    }

    /// Send a notification with default metadata.
    func notify(notification: SessionUpdate) async throws {
        try await notify(notification: notification, meta: nil)
    }

    /// Send an agent message chunk notification.
    func sendMessage(_ content: ContentBlock) async throws {
        try await notify(notification: .agentMessageChunk(AgentMessageChunk(content: content)))
    }

    /// Send a text message notification.
    func sendTextMessage(_ text: String) async throws {
        try await sendMessage(.text(TextContent(text: text)))
    }

    /// Create a terminal with default parameters.
    func terminalCreate(
        command: String,
        args: [String] = [],
        cwd: String? = nil
    ) async throws -> CreateTerminalResponse {
        try await terminalCreate(
            command: command,
            args: args,
            cwd: cwd,
            env: [],
            outputByteLimit: nil,
            meta: nil
        )
    }
}

// MARK: - AgentContext Errors

/// Errors that can occur during agent context operations.
public enum AgentContextError: Error, Sendable, LocalizedError {
    /// The client doesn't have the required capability.
    case capabilityNotSupported(String)

    /// The operation failed.
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .capabilityNotSupported(let capability):
            return "Client doesn't support capability: \(capability)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}
