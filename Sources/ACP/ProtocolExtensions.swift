import ACPModel
import Foundation

// MARK: - Protocol Typed Method Extensions

extension Protocol {
    /// Send an initialize request to establish connection and negotiate capabilities.
    ///
    /// - Parameter request: The initialization request parameters
    /// - Returns: The initialization response with negotiated capabilities
    /// - Throws: ProtocolError if the request fails
    public func initialize(request: InitializeRequest) async throws -> InitializeResponse {
        let response = try await sendRequest(method: "initialize", params: request)
        return try decodeResult(response.result, as: InitializeResponse.self)
    }

    /// Create a new session with the agent.
    ///
    /// - Parameter request: Session creation parameters
    /// - Returns: Information about the created session
    /// - Throws: ProtocolError if the request fails
    public func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        let response = try await sendRequest(method: "agent/session_create", params: request)
        return try decodeResult(response.result, as: NewSessionResponse.self)
    }

    /// Load an existing session.
    ///
    /// - Parameter request: Session load parameters
    /// - Returns: Information about the loaded session
    /// - Throws: ProtocolError if the request fails
    public func loadSession(request: LoadSessionRequest) async throws -> LoadSessionResponse {
        let response = try await sendRequest(method: "agent/session_load", params: request)
        return try decodeResult(response.result, as: LoadSessionResponse.self)
    }

    /// Send a prompt to the agent for processing.
    ///
    /// - Parameter request: Prompt parameters including session ID and prompt content
    /// - Returns: The agent's response
    /// - Throws: ProtocolError if the request fails
    public func prompt(request: PromptRequest) async throws -> PromptResponse {
        let response = try await sendRequest(method: "agent/prompt", params: request)
        return try decodeResult(response.result, as: PromptResponse.self)
    }

    /// Set the session mode.
    ///
    /// - Parameter request: Session mode change parameters
    /// - Returns: Response confirming the request
    /// - Throws: ProtocolError if the request fails
    public func setSessionMode(request: SetSessionModeRequest) async throws -> SetSessionModeResponse {
        let response = try await sendRequest(method: "session/set_mode", params: request)
        return try decodeResult(response.result, as: SetSessionModeResponse.self)
    }

    /// Send a cancel notification for a session.
    ///
    /// - Parameter notification: Cancel notification with session ID
    /// - Throws: ProtocolError if the notification fails to send
    public func sendCancel(notification: CancelNotification) async throws {
        try await sendNotification(method: "acp/session/cancel", params: notification)
    }

    /// Send a cancel request notification to cancel a specific request.
    ///
    /// - Parameter notification: Cancel request notification with request ID
    /// - Throws: ProtocolError if the notification fails to send
    public func sendCancelRequest(notification: CancelRequestNotification) async throws {
        try await sendNotification(method: "$/cancelRequest", params: notification)
    }

    /// Authenticate with the agent using a specific method.
    ///
    /// - Parameter request: Authentication request parameters
    /// - Returns: Authentication response
    /// - Throws: ProtocolError if the request fails
    public func authenticate(request: AuthenticateRequest) async throws -> AuthenticateResponse {
        let response = try await sendRequest(method: "authenticate", params: request)
        return try decodeResult(response.result, as: AuthenticateResponse.self)
    }

    /// **UNSTABLE**
    ///
    /// Set the model for a session.
    ///
    /// - Parameter request: Model change parameters
    /// - Returns: Response confirming the request
    /// - Throws: ProtocolError if the request fails
    public func setSessionModel(request: SetSessionModelRequest) async throws -> SetSessionModelResponse {
        let response = try await sendRequest(method: "session/set_model", params: request)
        return try decodeResult(response.result, as: SetSessionModelResponse.self)
    }

    /// **UNSTABLE**
    ///
    /// Set a configuration option for a session.
    ///
    /// - Parameter request: Config option change parameters
    /// - Returns: Response with updated config options
    /// - Throws: ProtocolError if the request fails
    public func setSessionConfigOption(
        request: SetSessionConfigOptionRequest
    ) async throws -> SetSessionConfigOptionResponse {
        let response = try await sendRequest(method: "session/set_config_option", params: request)
        return try decodeResult(response.result, as: SetSessionConfigOptionResponse.self)
    }

    // MARK: - Helper Methods

    /// Decode a JsonValue result into a specific type.
    private func decodeResult<T: Decodable>(_ result: JsonValue, as type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(result)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ProtocolError.decodingFailed(underlying: error)
        }
    }
}
