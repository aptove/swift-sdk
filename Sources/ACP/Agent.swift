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
/// - `handlePrompt(request:)`: Process prompts and return responses
///
/// ## Optional Methods
/// - `loadSession(request:)`: Load an existing session (requires loadSession capability)
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
///     func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
///         // Echo agent just reports completion
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
    /// - Parameter request: The prompt request with session ID and content
    /// - Returns: Response indicating completion status
    /// - Throws: Error if prompt processing fails
    func handlePrompt(request: PromptRequest) async throws -> PromptResponse

    // MARK: - Unstable API Methods

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
public enum AgentError: Error, Sendable, LocalizedError {
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
