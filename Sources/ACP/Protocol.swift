import ACPModel
import Foundation

/// Errors that can occur in the protocol layer.
public enum ProtocolError: Error, Sendable {
    /// The transport was closed before the operation could complete
    case transportClosed

    /// Received a response with an unknown or unexpected request ID
    case invalidResponseId(RequestId)

    /// A request timed out waiting for a response
    case timeout(method: String, requestId: RequestId)

    /// Received a JSON-RPC error response
    case jsonRpcError(code: Int, message: String, data: JsonValue?)

    /// Failed to encode request parameters
    case encodingFailed(underlying: Error)

    /// Failed to decode response data
    case decodingFailed(underlying: Error)
}

// MARK: - LocalizedError

extension ProtocolError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .transportClosed:
            return "Transport was closed before operation could complete"

        case .invalidResponseId(let id):
            return "Received response with unknown request ID: \(id)"

        case .timeout(let method, let requestId):
            return "Request timed out: \(method) (ID: \(requestId))"

        case .jsonRpcError(let code, let message, let data):
            var desc = "JSON-RPC error \(code): \(message)"
            if let data = data {
                desc += " (data: \(data))"
            }
            return desc

        case .encodingFailed(let underlying):
            return "Failed to encode request parameters: \(underlying.localizedDescription)"

        case .decodingFailed(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        }
    }
}

/// Manages JSON-RPC 2.0 protocol communication over a transport layer.
///
/// The Protocol layer sits above the transport layer and provides:
/// - Request/response correlation by ID
/// - Typed method invocations with automatic encoding/decoding
/// - Notification routing to registered handlers
/// - Error handling and timeout support
/// - Concurrent request management with actor isolation
///
/// ## Usage Example
///
/// ```swift
/// let transport = StdioTransport()
/// let protocol = Protocol(transport: transport)
///
/// // Start the protocol layer
/// try await protocol.start()
///
/// // Register notification handler
/// await protocol.onNotification(method: "session/update") { notification in
///     print("Received update: \(notification.params)")
/// }
///
/// // Send a request
/// let response = try await protocol.sendRequest(
///     method: "initialize",
///     params: ["version": "1.0"]
/// )
///
/// // Close when done
/// await protocol.close()
/// ```
public actor Protocol {
    // MARK: - Private Properties

    /// The underlying transport for message exchange
    private let transport: Transport

    /// Request ID counter (auto-incrementing)
    private var nextRequestId: Int = 1

    /// Pending requests awaiting responses
    private var pendingRequests: [RequestId: CheckedContinuation<JsonRpcResponse, Error>] = [:]

    /// Registered notification handlers by method name
    private var notificationHandlers: [String: @Sendable (JsonRpcNotification) async -> Void] = [:]

    /// Continuation for the error stream
    private var errorContinuation: AsyncStream<ProtocolError>.Continuation?

    /// Message processing task
    private var messageTask: Task<Void, Never>?

    /// Default timeout in seconds
    private let defaultTimeoutSeconds: TimeInterval

    // MARK: - Public Properties

    /// Stream of protocol errors (non-fatal errors that don't stop the protocol)
    nonisolated public let errors: AsyncStream<ProtocolError>

    // MARK: - Initialization

    /// Creates a new protocol layer.
    ///
    /// - Parameters:
    ///   - transport: The transport to use for message exchange
    ///   - defaultTimeoutSeconds: Default timeout for requests in seconds (default: 30)
    public init(transport: Transport, defaultTimeoutSeconds: TimeInterval = 30) {
        self.transport = transport
        self.defaultTimeoutSeconds = defaultTimeoutSeconds

        // Create error stream
        var continuation: AsyncStream<ProtocolError>.Continuation?
        self.errors = AsyncStream { continuation = $0 }
        self.errorContinuation = continuation
    }

    // MARK: - Lifecycle

    /// Starts the protocol layer.
    ///
    /// This method:
    /// 1. Starts the underlying transport
    /// 2. Begins processing incoming messages
    ///
    /// - Throws: ProtocolError if the transport fails to start
    public func start() async throws {
        // Start transport
        try await transport.start()

        // Start message processing
        messageTask = Task { [weak self] in
            await self?.processMessages()
        }
    }

    /// Closes the protocol connection.
    ///
    /// This method:
    /// 1. Cancels all pending requests
    /// 2. Closes the underlying transport
    /// 3. Cleans up resources
    public func close() async {
        // Cancel message processing
        messageTask?.cancel()
        messageTask = nil

        // Fail all pending requests
        for (_, continuation) in pendingRequests {
            continuation.resume(throwing: ProtocolError.transportClosed)
        }
        pendingRequests.removeAll()

        // Close transport
        await transport.close()

        // Finish error stream
        errorContinuation?.finish()
        errorContinuation = nil
    }

    // MARK: - Request Management

    /// Sends a request and awaits the response.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name
    ///   - params: The method parameters (must be Encodable)
    ///   - timeoutSeconds: Optional timeout override in seconds (uses default if nil)
    ///
    /// - Returns: The JSON-RPC response
    /// - Throws: ProtocolError if the request fails or times out
    public func sendRequest(
        method: String,
        params: (any Encodable)? = nil,
        timeoutSeconds: TimeInterval? = nil
    ) async throws -> JsonRpcResponse {
        // Generate request ID
        let requestId = generateRequestId()

        // Encode params
        let paramsValue: JsonValue?
        if let params = params {
            do {
                let data = try JSONEncoder().encode(AnyEncodable(params))
                paramsValue = try JSONDecoder().decode(JsonValue.self, from: data)
            } catch {
                throw ProtocolError.encodingFailed(underlying: error)
            }
        } else {
            paramsValue = nil
        }

        // Create request
        let request = JsonRpcRequest(id: requestId, method: method, params: paramsValue)
        let message = JsonRpcMessage.request(request)

        // Send via transport
        try await transport.send(message)

        // Wait for response with timeout
        let effectiveTimeout = timeoutSeconds ?? defaultTimeoutSeconds
        return try await withTimeout(seconds: effectiveTimeout) { [weak self] in
            guard let self = self else {
                throw ProtocolError.transportClosed
            }
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    await self.storeContinuation(requestId: requestId, continuation: continuation)
                }
            }
        }
    }

    /// Stores a continuation for a pending request.
    private func storeContinuation(
        requestId: RequestId,
        continuation: CheckedContinuation<JsonRpcResponse, Error>
    ) {
        pendingRequests[requestId] = continuation
    }

    /// Sends a notification (no response expected).
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name
    ///   - params: The method parameters (must be Encodable)
    ///
    /// - Throws: ProtocolError if the notification fails to send
    public func sendNotification(
        method: String,
        params: (any Encodable)? = nil
    ) async throws {
        // Encode params
        let paramsValue: JsonValue?
        if let params = params {
            do {
                let data = try JSONEncoder().encode(AnyEncodable(params))
                paramsValue = try JSONDecoder().decode(JsonValue.self, from: data)
            } catch {
                throw ProtocolError.encodingFailed(underlying: error)
            }
        } else {
            paramsValue = nil
        }

        // Create notification
        let notification = JsonRpcNotification(method: method, params: paramsValue)
        let message = JsonRpcMessage.notification(notification)

        // Send via transport (fire and forget)
        try await transport.send(message)
    }

    // MARK: - Notification Handling

    /// Registers a handler for notifications with a specific method name.
    ///
    /// - Parameters:
    ///   - method: The method name to handle
    ///   - handler: The async handler to invoke when a notification arrives
    public func onNotification(
        method: String,
        handler: @escaping @Sendable (JsonRpcNotification) async -> Void
    ) {
        notificationHandlers[method] = handler
    }

    // MARK: - Private Methods

    /// Generates a unique request ID.
    private func generateRequestId() -> RequestId {
        let id = nextRequestId
        nextRequestId += 1
        return .int(id)
    }

    /// Processes incoming messages from the transport.
    private func processMessages() async {
        for await message in transport.messages {
            switch message {
            case .request(let request):
                // We don't handle incoming requests yet (future: Agent/Client layer)
                errorContinuation?.yield(.invalidResponseId(request.id))

            case .response(let response):
                await handleResponse(response)

            case .error(let error):
                await handleError(error)

            case .notification(let notification):
                await handleNotification(notification)
            }
        }
    }

    /// Handles an incoming response.
    private func handleResponse(_ response: JsonRpcResponse) async {
        guard let continuation = pendingRequests.removeValue(forKey: response.id) else {
            errorContinuation?.yield(.invalidResponseId(response.id))
            return
        }

        continuation.resume(returning: response)
    }

    /// Handles an incoming error response.
    private func handleError(_ error: JsonRpcError) async {
        guard let id = error.id,
              let continuation = pendingRequests.removeValue(forKey: id) else {
            if let id = error.id {
                errorContinuation?.yield(.invalidResponseId(id))
            } else {
                errorContinuation?.yield(.jsonRpcError(
                    code: error.error.code,
                    message: error.error.message,
                    data: error.error.data
                ))
            }
            return
        }

        let protocolError = ProtocolError.jsonRpcError(
            code: error.error.code,
            message: error.error.message,
            data: error.error.data
        )
        continuation.resume(throwing: protocolError)
    }

    /// Handles an incoming notification.
    private func handleNotification(_ notification: JsonRpcNotification) async {
        guard let handler = notificationHandlers[notification.method] else {
            // Log warning for unhandled notification
            return
        }

        // Invoke handler in separate task to avoid blocking message loop
        Task {
            await handler(notification)
        }
    }
}

// MARK: - Timeout Support

/// Runs an async operation with a timeout.
private func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Start the operation
        group.addTask {
            try await operation()
        }

        // Start timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }

        // Wait for first to complete
        let result = try await group.next()!

        // Cancel remaining tasks
        group.cancelAll()

        return result
    }
}

// MARK: - Type Erasure

/// Type-erased wrapper for Encodable types.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { try value.encode(to: $0) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
