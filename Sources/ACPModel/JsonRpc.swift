import Foundation

/// A JSON-RPC 2.0 request message.
///
/// Represents a request sent from client to server or server to client.
/// All ACP protocol methods are sent as JSON-RPC requests.
public struct JsonRpcRequest: Codable, Sendable {
    /// The JSON-RPC version (always "2.0")
    public let jsonrpc: String

    /// The request identifier for correlation with responses
    public let id: RequestId

    /// The method name being invoked
    public let method: String

    /// The method parameters (optional)
    public let params: JsonValue?

    /// Creates a JSON-RPC request.
    ///
    /// - Parameters:
    ///   - id: The request identifier
    ///   - method: The method name
    ///   - params: The method parameters
    public init(id: RequestId, method: String, params: JsonValue? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

/// A JSON-RPC 2.0 success response message.
///
/// Represents a successful response to a request.
public struct JsonRpcResponse: Codable, Sendable {
    /// The JSON-RPC version (always "2.0")
    public let jsonrpc: String

    /// The request identifier this response corresponds to
    public let id: RequestId

    /// The result of the method invocation
    public let result: JsonValue

    /// Creates a JSON-RPC success response.
    ///
    /// - Parameters:
    ///   - id: The request identifier
    ///   - result: The method result
    public init(id: RequestId, result: JsonValue) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
    }
}

/// A JSON-RPC 2.0 error response message.
///
/// Represents an error response to a request.
public struct JsonRpcError: Codable, Sendable {
    /// The JSON-RPC version (always "2.0")
    public let jsonrpc: String

    /// The request identifier this error corresponds to
    public let id: RequestId?

    /// The error information
    public let error: ErrorInfo

    /// Creates a JSON-RPC error response.
    ///
    /// - Parameters:
    ///   - id: The request identifier (nil for parse errors)
    ///   - error: The error information
    public init(id: RequestId?, error: ErrorInfo) {
        self.jsonrpc = "2.0"
        self.id = id
        self.error = error
    }

    /// Error information for JSON-RPC errors.
    public struct ErrorInfo: Codable, Sendable {
        /// The error code
        public let code: Int

        /// A human-readable error message
        public let message: String

        /// Additional error data (optional)
        public let data: JsonValue?

        /// Creates error information.
        ///
        /// - Parameters:
        ///   - code: The error code
        ///   - message: The error message
        ///   - data: Additional error data
        public init(code: Int, message: String, data: JsonValue? = nil) {
            self.code = code
            self.message = message
            self.data = data
        }
    }
}

/// Standard JSON-RPC 2.0 error codes.
public enum JsonRpcErrorCode: Int {
    /// Invalid JSON was received by the server
    case parseError = -32700

    /// The JSON sent is not a valid Request object
    case invalidRequest = -32600

    /// The method does not exist / is not available
    case methodNotFound = -32601

    /// Invalid method parameter(s)
    case invalidParams = -32602

    /// Internal JSON-RPC error
    case internalError = -32603

    // ACP-specific error codes

    /// Authentication is required to perform this operation
    case authRequired = -32000

    /// The requested resource was not found
    case resourceNotFound = -32001
}

/// A JSON-RPC 2.0 notification message.
///
/// Notifications are like requests but do not expect a response.
/// They are used for fire-and-forget messages and server-initiated events.
public struct JsonRpcNotification: Codable, Sendable {
    /// The JSON-RPC version (always "2.0")
    public let jsonrpc: String

    /// The method name being invoked
    public let method: String

    /// The method parameters (optional)
    public let params: JsonValue?

    /// Creates a JSON-RPC notification.
    ///
    /// - Parameters:
    ///   - method: The method name
    ///   - params: The method parameters
    public init(method: String, params: JsonValue? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}

/// A JSON-RPC message envelope that can represent any message type.
///
/// This is useful for parsing incoming messages where the type is not known in advance.
public enum JsonRpcMessage: Codable, Sendable {
    case request(JsonRpcRequest)
    case response(JsonRpcResponse)
    case error(JsonRpcError)
    case notification(JsonRpcNotification)

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as each type
        if let request = try? container.decode(JsonRpcRequest.self) {
            self = .request(request)
        } else if let error = try? container.decode(JsonRpcError.self) {
            self = .error(error)
        } else if let response = try? container.decode(JsonRpcResponse.self) {
            self = .response(response)
        } else if let notification = try? container.decode(JsonRpcNotification.self) {
            self = .notification(notification)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown JSON-RPC message type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .request(let request):
            try container.encode(request)
        case .response(let response):
            try container.encode(response)
        case .error(let error):
            try container.encode(error)
        case .notification(let notification):
            try container.encode(notification)
        }
    }
}
