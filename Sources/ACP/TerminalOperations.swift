import ACPModel
import Foundation

/// Protocol for terminal operations that agents can invoke on clients.
///
/// Clients that support terminal capabilities implement this protocol
/// to allow agents to execute commands in the user's environment.
///
/// ## Capabilities
///
/// Terminal operations are gated by the `terminal` client capability.
/// When advertising this capability, the client must implement all
/// terminal operations.
///
/// ## Usage
///
/// Implement this protocol in your client to provide terminal access:
///
/// ```swift
/// class MyClient: Client, TerminalOperations {
///     private var terminals: [String: Process] = [:]
///
///     func terminalCreate(
///         sessionId: SessionId,
///         command: String,
///         args: [String],
///         cwd: String?,
///         env: [EnvVariable],
///         outputByteLimit: UInt64?,
///         meta: MetaField?
///     ) async throws -> CreateTerminalResponse {
///         let process = Process()
///         process.executableURL = URL(fileURLWithPath: command)
///         process.arguments = args
///         // ... setup process ...
///         try process.run()
///
///         let terminalId = UUID().uuidString
///         terminals[terminalId] = process
///         return CreateTerminalResponse(terminalId: terminalId)
///     }
///
///     // ... implement other methods ...
/// }
/// ```
public protocol TerminalOperations: Sendable {

    /// Create a new terminal session.
    ///
    /// Starts executing the specified command in a new terminal.
    /// The terminal captures output that can be retrieved with `terminalOutput`.
    ///
    /// - Parameter request: The terminal creation request
    /// - Returns: The terminal identifier
    /// - Throws: Error if terminal cannot be created
    func terminalCreate(request: CreateTerminalRequest) async throws -> CreateTerminalResponse

    /// Get output from a terminal.
    ///
    /// Retrieves the accumulated output from the terminal since the last call.
    ///
    /// - Parameters:
    ///   - sessionId: The session making the request
    ///   - terminalId: The terminal to get output from
    ///   - meta: Optional metadata
    /// - Returns: The terminal output
    /// - Throws: Error if terminal not found
    func terminalOutput(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> TerminalOutputResponse

    /// Release a terminal session.
    ///
    /// Releases the terminal resources. The terminal can no longer be used after this.
    /// If the process is still running, it will be terminated.
    ///
    /// - Parameters:
    ///   - sessionId: The session making the request
    ///   - terminalId: The terminal to release
    ///   - meta: Optional metadata
    /// - Returns: Confirmation of release
    /// - Throws: Error if terminal not found
    func terminalRelease(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> ReleaseTerminalResponse

    /// Wait for a terminal to exit.
    ///
    /// Blocks until the terminal process exits. Returns the exit code or signal.
    ///
    /// - Parameters:
    ///   - sessionId: The session making the request
    ///   - terminalId: The terminal to wait for
    ///   - meta: Optional metadata
    /// - Returns: The exit status
    /// - Throws: Error if terminal not found
    func terminalWaitForExit(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> WaitForTerminalExitResponse

    /// Kill a terminal command.
    ///
    /// Sends a termination signal to the running process but keeps the
    /// terminal resources allocated so output can still be retrieved.
    ///
    /// - Parameters:
    ///   - sessionId: The session making the request
    ///   - terminalId: The terminal to kill
    ///   - meta: Optional metadata
    /// - Returns: Confirmation of kill
    /// - Throws: Error if terminal not found
    func terminalKill(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> KillTerminalCommandResponse
}

// MARK: - Default Implementations

extension TerminalOperations {

    /// Default implementation that throws not implemented error.
    public func terminalCreate(request: CreateTerminalRequest) async throws -> CreateTerminalResponse {
        throw ClientError.notImplemented("terminalCreate - Client must advertise terminal capability")
    }

    /// Default implementation that throws not implemented error.
    public func terminalOutput(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> TerminalOutputResponse {
        throw ClientError.notImplemented("terminalOutput - Client must advertise terminal capability")
    }

    /// Default implementation that throws not implemented error.
    public func terminalRelease(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> ReleaseTerminalResponse {
        throw ClientError.notImplemented("terminalRelease - Client must advertise terminal capability")
    }

    /// Default implementation that throws not implemented error.
    public func terminalWaitForExit(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> WaitForTerminalExitResponse {
        throw ClientError.notImplemented("terminalWaitForExit - Client must advertise terminal capability")
    }

    /// Default implementation that throws not implemented error.
    public func terminalKill(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> KillTerminalCommandResponse {
        throw ClientError.notImplemented("terminalKill - Client must advertise terminal capability")
    }
}
