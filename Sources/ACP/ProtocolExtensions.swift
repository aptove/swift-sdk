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
        print("📡 Protocol: Sending initialize request: \(request)")
        let response = try await sendRequest(method: "initialize", params: request)
        print("📡 Protocol: Received response, result: \(response.result)")
        let decoded = try decodeResult(response.result, as: InitializeResponse.self)
        print("📡 Protocol: Successfully decoded InitializeResponse: \(decoded)")
        return decoded
    }

    /// Create a new session with the agent.
    ///
    /// - Parameter request: Session creation parameters
    /// - Returns: Information about the created session
    /// - Throws: ProtocolError if the request fails
    public func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        print("📡 Protocol: Creating session with request: \(request)")
        let response = try await sendRequest(method: "session/new", params: request)
        print("📡 Protocol: Create session response: \(response)")
        let decoded = try decodeResult(response.result, as: NewSessionResponse.self)
        print("📡 Protocol: Decoded session response: \(decoded)")
        return decoded
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
        print("📡 Protocol: Sending prompt request: \(request)")
        let response = try await sendRequest(method: "session/prompt", params: request)
        print("📡 Protocol: Prompt response: \(response)")
        let decoded = try decodeResult(response.result, as: PromptResponse.self)
        print("📡 Protocol: Decoded prompt response: \(decoded)")
        return decoded
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
        try await sendNotification(method: "session/cancel", params: notification)
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

    // MARK: - Unstable Session Operations

    /// **UNSTABLE**
    ///
    /// List existing sessions from the agent.
    ///
    /// - Parameter request: List sessions request with optional filters
    /// - Returns: Response with session list and pagination cursor
    /// - Throws: ProtocolError if the request fails
    @available(*, message: "Unstable API - may change without notice")
    public func listSessions(request: ListSessionsRequest) async throws -> ListSessionsResponse {
        let response = try await sendRequest(method: "session/list", params: request)
        return try decodeResult(response.result, as: ListSessionsResponse.self)
    }

    /// **UNSTABLE**
    ///
    /// Fork an existing session to create a new independent session.
    ///
    /// - Parameter request: Fork session request
    /// - Returns: Response with new session ID and initial state
    /// - Throws: ProtocolError if the request fails
    @available(*, message: "Unstable API - may change without notice")
    public func forkSession(request: ForkSessionRequest) async throws -> ForkSessionResponse {
        let response = try await sendRequest(method: "session/fork", params: request)
        return try decodeResult(response.result, as: ForkSessionResponse.self)
    }

    /// **UNSTABLE**
    ///
    /// Resume an existing session without returning previous messages.
    ///
    /// - Parameter request: Resume session request
    /// - Returns: Response with initial session state
    /// - Throws: ProtocolError if the request fails
    @available(*, message: "Unstable API - may change without notice")
    public func resumeSession(request: ResumeSessionRequest) async throws -> ResumeSessionResponse {
        let response = try await sendRequest(method: "session/resume", params: request)
        return try decodeResult(response.result, as: ResumeSessionResponse.self)
    }

    // MARK: - Generic Request

    /// Send a typed request and decode the response.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name
    ///   - params: Request parameters (must be Encodable)
    ///   - responseType: The expected response type
    /// - Returns: Decoded response
    /// - Throws: ProtocolError if the request fails
    public func request<P: Encodable, R: Decodable>(
        method: String,
        params: P,
        responseType: R.Type
    ) async throws -> R {
        let response = try await sendRequest(method: method, params: params)
        return try decodeResult(response.result, as: R.self)
    }

    // MARK: - Request Handlers

    /// Register a typed handler for incoming requests from the agent.
    ///
    /// - Parameters:
    ///   - method: The method name to handle
    ///   - requestType: The type to decode request params as
    ///   - handler: The handler that processes the request and returns a response
    public func onRequest<P: Decodable, R: Encodable>(
        method: String,
        requestType: P.Type,
        handler: @escaping @Sendable (P) async throws -> R
    ) {
        onRequest(method: method) { request in
            // Decode request params
            let params: P
            if let paramsValue = request.params {
                let data = try JSONEncoder().encode(paramsValue)
                params = try JSONDecoder().decode(P.self, from: data)
            } else {
                throw ProtocolError.decodingFailed(underlying: NSError(
                    domain: "ACP",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Missing required params"]
                ))
            }
            
            // Execute handler
            let result = try await handler(params)
            
            // Encode result as JsonValue
            let data = try JSONEncoder().encode(result)
            return try JSONDecoder().decode(JsonValue.self, from: data)
        }
    }

    // MARK: - Helper Methods

    /// Decode a JsonValue result into a specific type.
    private func decodeResult<T: Decodable>(_ result: JsonValue, as type: T.Type) throws -> T {
        print("🔍 Protocol: Decoding result as \(type)")
        print("🔍 Protocol: JsonValue: \(result)")
        let data = try JSONEncoder().encode(result)
        print("🔍 Protocol: Encoded data: \(String(data: data, encoding: .utf8) ?? "invalid")")
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            print("🔍 Protocol: Successfully decoded as \(type)")
            return decoded
        } catch {
            print("🔍 Protocol: Decoding failed: \(error)")
            throw ProtocolError.decodingFailed(underlying: error)
        }
    }
}
