import ACPModel
import Foundation

/// Protocol for implementing ACP agents.
///
/// Agents process prompts from clients and can manage sessions.
/// Implement this protocol to create a custom ACP agent.
///
/// ## Required Methods
/// - `capabilities`: Agent capabilities to advertise during initialization
/// - `createSession(request:)`: Handle new session creation
/// - `handlePrompt(request:context:)`: Process prompts and return responses
///
/// ## Optional Methods
/// - `loadSession(request:)`: Load an existing session (requires loadSession capability)
/// - `forkSession(request:)`: Fork an existing session
/// - `resumeSession(request:)`: Resume an existing session
/// - `setSessionMode(request:)`: Change session mode
///
/// ## Example Implementation
///
/// ```swift
/// struct EchoAgent: Agent {
///     var capabilities: AgentCapabilities {
///         AgentCapabilities(sessions: SessionsCapability())
///     }
///
///     var info: Implementation? {
///         Implementation(name: "EchoAgent", version: "1.0")
///     }
///
///     func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
///         return NewSessionResponse(sessionId: SessionId())
///     }
///
///     func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
///         // Echo agent sends the prompt back as a message
///         try await context.sendTextMessage("You said: \(request.prompt)")
///         return PromptResponse(stopReason: .endTurn)
///     }
/// }
/// ```
public protocol Agent: Sendable {
    /// Capabilities advertised by this agent during initialization.
    var capabilities: AgentCapabilities { get }

    /// Optional implementation information for this agent.
    var info: Implementation? { get }

    /// Create a new session.
    ///
    /// - Parameter request: Session creation parameters
    /// - Returns: Response with the new session ID and initial state
    /// - Throws: Error if session creation fails
    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse

    /// Load an existing session.
    ///
    /// Default implementation throws NotImplementedError.
    ///
    /// - Parameter request: Session load parameters
    /// - Returns: Response with session state
    /// - Throws: Error if session loading fails
    func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse

    /// Process a prompt from the client.
    ///
    /// This is the legacy method without context. Override `handlePrompt(request:context:)`
    /// to access client operations during prompt handling.
    ///
    /// - Parameter request: The prompt request with session ID and content
    /// - Returns: Response indicating completion status
    /// - Throws: Error if prompt processing fails
    func handlePrompt(request: PromptRequest) async throws -> PromptResponse

    /// Process a prompt from the client with access to client operations.
    ///
    /// Override this method to access file system, terminal, and permission operations
    /// on the client during prompt handling.
    ///
    /// - Parameters:
    ///   - request: The prompt request with session ID and content
    ///   - context: Context providing access to client operations
    /// - Returns: Response indicating completion status
    /// - Throws: Error if prompt processing fails
    func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse

    // MARK: - Unstable API Methods

    /// **UNSTABLE** - List existing sessions.
    ///
    /// Default implementation throws not implemented error.
    /// Requires `sessionCapabilities.list` capability to be advertised.
    ///
    /// - Parameter request: The list sessions request
    /// - Returns: Response with paginated session list
    /// - Throws: Error if the request fails
    func listSessions(request: ListSessionsRequest) async throws -> ListSessionsResponse

    /// **UNSTABLE** - Fork an existing session.
    ///
    /// Creates a new session based on an existing session's context.
    /// Default implementation throws not implemented error.
    /// Requires `sessionCapabilities.fork` capability to be advertised.
    ///
    /// - Parameter request: The fork session request
    /// - Returns: Response with new session info
    /// - Throws: Error if the request fails
    func forkSession(request: ForkSessionRequest) async throws -> ForkSessionResponse

    /// **UNSTABLE** - Resume an existing session.
    ///
    /// Resumes a session without replaying message history.
    /// Default implementation throws not implemented error.
    /// Requires `sessionCapabilities.resume` capability to be advertised.
    ///
    /// - Parameter request: The resume session request
    /// - Returns: Response with session state
    /// - Throws: Error if the request fails
    func resumeSession(request: ResumeSessionRequest) async throws -> ResumeSessionResponse

    /// **UNSTABLE** - Set the mode for a session.
    ///
    /// Default implementation throws not implemented error.
    ///
    /// - Parameter request: The set mode request
    /// - Returns: Response confirming the mode change
    /// - Throws: Error if the request fails
    func setSessionMode(request: SetSessionModeRequest) async throws -> SetSessionModeResponse

    /// **UNSTABLE** - Set the model for a session.
    ///
    /// Default implementation throws not implemented error.
    ///
    /// - Parameter request: The set model request
    /// - Returns: Response confirming the request
    /// - Throws: Error if the request fails
    func setSessionModel(request: SetSessionModelRequest) async throws -> SetSessionModelResponse

    /// **UNSTABLE** - Set a configuration option for a session.
    ///
    /// Default implementation throws not implemented error.
    ///
    /// - Parameter request: The set config option request
    /// - Returns: Response with updated config options
    /// - Throws: Error if the request fails
    func setSessionConfigOption(request: SetSessionConfigOptionRequest) async throws -> SetSessionConfigOptionResponse
}

// MARK: - Default Implementations

public extension Agent {
    /// Default info is nil.
    var info: Implementation? { nil }

    /// Default load session implementation throws not implemented error.
    func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
        throw AgentError.notImplemented(method: "loadSession")
    }

    /// Default handlePrompt without context - calls the context version with a nil-like context.
    /// Agents should override the context version for full functionality.
    func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
        throw AgentError.notImplemented(method: "handlePrompt")
    }

    /// Default handlePrompt with context - calls the legacy version without context.
    /// This provides backwards compatibility.
    func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
        return try await handlePrompt(request: request)
    }

    /// Default list sessions implementation throws not implemented error.
    func listSessions(request: ListSessionsRequest) async throws -> ListSessionsResponse {
        throw AgentError.notImplemented(method: "listSessions")
    }

    /// Default fork session implementation throws not implemented error.
    func forkSession(request: ForkSessionRequest) async throws -> ForkSessionResponse {
        throw AgentError.notImplemented(method: "forkSession")
    }

    /// Default resume session implementation throws not implemented error.
    func resumeSession(request: ResumeSessionRequest) async throws -> ResumeSessionResponse {
        throw AgentError.notImplemented(method: "resumeSession")
    }

    /// Default set session mode implementation throws not implemented error.
    func setSessionMode(request: SetSessionModeRequest) async throws -> SetSessionModeResponse {
        throw AgentError.notImplemented(method: "setSessionMode")
    }

    /// Default set session model implementation throws not implemented error.
    func setSessionModel(request: SetSessionModelRequest) async throws -> SetSessionModelResponse {
        throw AgentError.notImplemented(method: "setSessionModel")
    }

    /// Default set session config option implementation throws not implemented error.
    func setSessionConfigOption(request: SetSessionConfigOptionRequest) async throws -> SetSessionConfigOptionResponse {
        throw AgentError.notImplemented(method: "setSessionConfigOption")
    }
}

// MARK: - Agent Errors

/// Errors that agents can throw.
public enum AgentError: Error, Sendable, LocalizedError, JsonRpcErrorConvertible {
    /// The requested method is not implemented by this agent.
    case notImplemented(method: String)

    /// The session was not found.
    case sessionNotFound(SessionId)

    /// Invalid request parameters.
    case invalidParams(String)

    /// Internal agent error.
    case internalError(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let method):
            return "Method not implemented: \(method)"
        case .sessionNotFound(let id):
            return "Session not found: \(id)"
        case .invalidParams(let message):
            return "Invalid parameters: \(message)"
        case .internalError(let message):
            return "Internal error: \(message)"
        }
    }

    /// JSON-RPC error code for this error.
    public var errorCode: Int {
        switch self {
        case .notImplemented:
            return -32601 // Method not found
        case .sessionNotFound:
            return -32001 // Resource not found (ACP-specific)
        case .invalidParams:
            return -32602 // Invalid params
        case .internalError:
            return -32603 // Internal error
        }
    }
}
