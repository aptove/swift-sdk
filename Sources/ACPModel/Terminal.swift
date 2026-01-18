import Foundation

// MARK: - Terminal Request/Response Types

/// Request to create a new terminal session.
///
/// Creates a terminal that can execute commands and capture output.
/// Only available if the client supports the `terminal` capability.
///
/// See protocol docs: [Terminal](https://agentclientprotocol.com/protocol/terminal)
public struct CreateTerminalRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this terminal belongs to
    public let sessionId: SessionId

    /// The command to execute
    public let command: String

    /// Arguments to pass to the command
    public let args: [String]

    /// Working directory for the command
    public let cwd: String?

    /// Environment variables to set
    public let env: [EnvVariable]

    /// Maximum bytes of output to capture
    public let outputByteLimit: UInt64?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a terminal creation request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - command: The command to execute
    ///   - args: Command arguments
    ///   - cwd: Working directory
    ///   - env: Environment variables
    ///   - outputByteLimit: Maximum output bytes to capture
    ///   - meta: Optional metadata
    public init(
        sessionId: SessionId,
        command: String,
        args: [String] = [],
        cwd: String? = nil,
        env: [EnvVariable] = [],
        outputByteLimit: UInt64? = nil,
        meta: MetaField? = nil
    ) {
        self.sessionId = sessionId
        self.command = command
        self.args = args
        self.cwd = cwd
        self.env = env
        self.outputByteLimit = outputByteLimit
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case command = "command"
        case args = "args"
        case cwd = "cwd"
        case env = "env"
        case outputByteLimit = "outputByteLimit"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response from creating a terminal session.
public struct CreateTerminalResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The unique identifier for the created terminal
    public let terminalId: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a terminal creation response.
    ///
    /// - Parameters:
    ///   - terminalId: The terminal identifier
    ///   - meta: Optional metadata
    public init(terminalId: String, meta: MetaField? = nil) {
        self.terminalId = terminalId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case terminalId = "terminalId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Terminal Output

/// Request to get output from a terminal.
public struct TerminalOutputRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this terminal belongs to
    public let sessionId: SessionId

    /// The terminal to get output from
    public let terminalId: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a terminal output request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - terminalId: The terminal ID
    ///   - meta: Optional metadata
    public init(sessionId: SessionId, terminalId: String, meta: MetaField? = nil) {
        self.sessionId = sessionId
        self.terminalId = terminalId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case terminalId = "terminalId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response containing terminal output.
public struct TerminalOutputResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The terminal output text
    public let output: String

    /// Whether the output was truncated due to size limits
    public let truncated: Bool

    /// Exit status if the terminal has exited
    public let exitStatus: TerminalExitStatus?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a terminal output response.
    ///
    /// - Parameters:
    ///   - output: The output text
    ///   - truncated: Whether output was truncated
    ///   - exitStatus: Exit status if terminal exited
    ///   - meta: Optional metadata
    public init(
        output: String,
        truncated: Bool,
        exitStatus: TerminalExitStatus? = nil,
        meta: MetaField? = nil
    ) {
        self.output = output
        self.truncated = truncated
        self.exitStatus = exitStatus
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case output = "output"
        case truncated = "truncated"
        case exitStatus = "exitStatus"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Terminal Release

/// Request to release a terminal session.
///
/// Releases the terminal resources. The terminal can no longer be used after this.
public struct ReleaseTerminalRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this terminal belongs to
    public let sessionId: SessionId

    /// The terminal to release
    public let terminalId: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a release terminal request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - terminalId: The terminal ID
    ///   - meta: Optional metadata
    public init(sessionId: SessionId, terminalId: String, meta: MetaField? = nil) {
        self.sessionId = sessionId
        self.terminalId = terminalId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case terminalId = "terminalId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response from releasing a terminal.
public struct ReleaseTerminalResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a release terminal response.
    ///
    /// - Parameter meta: Optional metadata
    public init(meta: MetaField? = nil) {
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Wait for Exit

/// Request to wait for a terminal to exit.
///
/// Blocks until the terminal process exits or times out.
public struct WaitForTerminalExitRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this terminal belongs to
    public let sessionId: SessionId

    /// The terminal to wait for
    public let terminalId: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a wait for exit request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - terminalId: The terminal ID
    ///   - meta: Optional metadata
    public init(sessionId: SessionId, terminalId: String, meta: MetaField? = nil) {
        self.sessionId = sessionId
        self.terminalId = terminalId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case terminalId = "terminalId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response from waiting for terminal exit.
public struct WaitForTerminalExitResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The exit code if the process exited normally
    public let exitCode: UInt32?

    /// The signal name if the process was killed by a signal
    public let signal: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a wait for exit response.
    ///
    /// - Parameters:
    ///   - exitCode: The exit code
    ///   - signal: The signal name
    ///   - meta: Optional metadata
    public init(exitCode: UInt32? = nil, signal: String? = nil, meta: MetaField? = nil) {
        self.exitCode = exitCode
        self.signal = signal
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case exitCode = "exitCode"
        case signal = "signal"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Kill Terminal

/// Request to kill a terminal command without releasing the terminal.
///
/// Sends a termination signal to the running process but keeps the terminal
/// resources allocated so output can still be retrieved.
public struct KillTerminalCommandRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this terminal belongs to
    public let sessionId: SessionId

    /// The terminal to kill
    public let terminalId: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a kill terminal request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - terminalId: The terminal ID
    ///   - meta: Optional metadata
    public init(sessionId: SessionId, terminalId: String, meta: MetaField? = nil) {
        self.sessionId = sessionId
        self.terminalId = terminalId
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case terminalId = "terminalId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response from killing a terminal command.
public struct KillTerminalCommandResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a kill terminal response.
    ///
    /// - Parameter meta: Optional metadata
    public init(meta: MetaField? = nil) {
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Terminal Exit Status

/// Terminal exit status information.
///
/// Contains information about how a terminal process exited.
public struct TerminalExitStatus: AcpWithMeta, Codable, Sendable, Hashable {
    /// The exit code if the process exited normally
    public let exitCode: UInt32?

    /// The signal name if the process was killed by a signal
    public let signal: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates terminal exit status.
    ///
    /// - Parameters:
    ///   - exitCode: The exit code
    ///   - signal: The signal name
    ///   - meta: Optional metadata
    public init(exitCode: UInt32? = nil, signal: String? = nil, meta: MetaField? = nil) {
        self.exitCode = exitCode
        self.signal = signal
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case exitCode = "exitCode"
        case signal = "signal"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}
