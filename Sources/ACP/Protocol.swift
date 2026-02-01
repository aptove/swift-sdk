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

    /// Pending outgoing requests awaiting responses (requests we sent)
    private var pendingOutgoingRequests: [RequestId: CheckedContinuation<JsonRpcResponse, Error>] = [:]

    /// Pending incoming requests being processed (requests we received)
    private var pendingIncomingRequests: [RequestId: Task<Void, Never>] = [:]

    /// Registered notification handlers by method name
    private var notificationHandlers: [String: @Sendable (JsonRpcNotification) async -> Void] = [:]

    /// Registered request handlers by method name
    private var requestHandlers: [String: @Sendable (JsonRpcRequest) async throws -> JsonValue] = [:]

    /// Continuation for the error stream
    private var errorContinuation: AsyncStream<ProtocolError>.Continuation?

    /// Message processing task
    private var messageTask: Task<Void, Never>?

    /// Default timeout in seconds
    private let defaultTimeoutSeconds: TimeInterval

    /// Timeout for graceful cancellation in seconds
    private let gracefulCancellationTimeoutSeconds: TimeInterval

    // MARK: - Public Properties

    /// Stream of protocol errors (non-fatal errors that don't stop the protocol)
    nonisolated public let errors: AsyncStream<ProtocolError>

    // MARK: - Initialization

    /// Creates a new protocol layer.
    ///
    /// - Parameters:
    ///   - transport: The transport to use for message exchange
    ///   - defaultTimeoutSeconds: Default timeout for requests in seconds (default: 30)
    ///   - gracefulCancellationTimeoutSeconds: Timeout for waiting for graceful cancellation (default: 1)
    public init(
        transport: Transport,
        defaultTimeoutSeconds: TimeInterval = 30,
        gracefulCancellationTimeoutSeconds: TimeInterval = 1
    ) {
        self.transport = transport
        self.defaultTimeoutSeconds = defaultTimeoutSeconds
        self.gracefulCancellationTimeoutSeconds = gracefulCancellationTimeoutSeconds

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
    /// 3. Registers the cancel request handler
    ///
    /// - Throws: ProtocolError if the transport fails to start
    public func start() async throws {
        // Register built-in cancel request handler
        registerCancelRequestHandler()

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

        // Fail all pending outgoing requests
        for (_, continuation) in pendingOutgoingRequests {
            continuation.resume(throwing: ProtocolError.transportClosed)
        }
        pendingOutgoingRequests.removeAll()

        // Cancel all pending incoming requests
        for (_, task) in pendingIncomingRequests {
            task.cancel()
        }
        pendingIncomingRequests.removeAll()

        // Close transport
        await transport.close()

        // Finish error stream
        errorContinuation?.finish()
        errorContinuation = nil
    }

    // MARK: - Cancellation Support

    /// Registers the built-in handler for cancel request notifications.
    private func registerCancelRequestHandler() {
        notificationHandlers["$/cancelRequest"] = { [weak self] notification in
            await self?.handleCancelRequest(notification)
        }
    }

    /// Handles an incoming cancel request notification.
    private func handleCancelRequest(_ notification: JsonRpcNotification) async {
        // Decode the cancel notification
        guard let params = notification.params else { return }

        do {
            let data = try JSONEncoder().encode(params)
            let cancelNotification = try JSONDecoder().decode(CancelRequestNotification.self, from: data)

            // Find and cancel the pending incoming request
            if let task = pendingIncomingRequests.removeValue(forKey: cancelNotification.requestId) {
                task.cancel()
            }
        } catch {
            // Log but don't fail - malformed cancel notifications should be ignored
            errorContinuation?.yield(.decodingFailed(underlying: error))
        }
    }

    /// Sends a cancel request notification to the other side.
    private func sendCancelNotification(requestId: RequestId, message: String?) async {
        let cancelNotification = CancelRequestNotification(requestId: requestId, message: message)
        do {
            try await sendNotification(method: "$/cancelRequest", params: cancelNotification)
        } catch {
            // Best effort - don't fail if cancel notification can't be sent
            errorContinuation?.yield(.encodingFailed(underlying: error))
        }
    }

    /// Cancels all pending incoming requests (requests we are handling).
    public func cancelPendingIncomingRequests() async {
        for (_, task) in pendingIncomingRequests {
            task.cancel()
        }
        pendingIncomingRequests.removeAll()
    }

    /// Cancels all pending outgoing requests (requests we are waiting for).
    public func cancelPendingOutgoingRequests(error: Error = CancellationError()) async {
        for (_, continuation) in pendingOutgoingRequests {
            continuation.resume(throwing: error)
        }
        pendingOutgoingRequests.removeAll()
    }

    // MARK: - Request Management

    /// Sends a request and awaits the response.
    ///
    /// If the calling task is cancelled, this method sends a `$/cancelRequest` notification
    /// to the other side and waits briefly for a graceful cancellation response.
    ///
    /// - Parameters:
    ///   - method: The JSON-RPC method name
    ///   - params: The method parameters (must be Encodable)
    ///   - timeoutSeconds: Optional timeout override in seconds (uses default if nil)
    ///
    /// - Returns: The JSON-RPC response
    /// - Throws: ProtocolError if the request fails, times out, or is cancelled
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

        // Create request message
        let request = JsonRpcRequest(id: requestId, method: method, params: paramsValue)
        let message = JsonRpcMessage.request(request)

        // Wait for response with timeout and cancellation handling
        let effectiveTimeout = timeoutSeconds ?? defaultTimeoutSeconds

        // Use withTaskCancellationHandler to properly handle cancellation
        // We need to capture `self` weakly since the closure runs synchronously
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<JsonRpcResponse, Error>) in
                // Store continuation FIRST (before sending request)
                self.pendingOutgoingRequests[requestId] = continuation

                // Start a task to send the request and handle timeout
                Task { [weak self] in
                    guard let self = self else {
                        return
                    }

                    do {
                        // Send the request
                        try await self.transport.send(message)

                        // Start timeout monitoring with cancellation checks
                        // Use smaller sleep intervals to respond to cancellation faster
                        let startTime = Date()
                        while Date().timeIntervalSince(startTime) < effectiveTimeout {
                            // Check for cancellation
                            if Task.isCancelled {
                                return
                            }
                            try await Task.sleep(nanoseconds: 50_000_000) // 50ms intervals
                        }

                        // If we get here, timeout occurred (request still pending)
                        await self.handleTimeout(requestId: requestId, method: method)
                    } catch is CancellationError {
                        // Task was cancelled - this is expected
                    } catch {
                        // Transport error
                        await self.handleTransportError(requestId: requestId, error: error)
                    }
                }
            }
        } onCancel: { [weak self] in
            // This runs synchronously when the outer task is cancelled
            // We need to dispatch to an actor-isolated context via a detached task
            // Using unstructured concurrency since onCancel is synchronous
            let capturedSelf = self
            let capturedRequestId = requestId
            Task.detached {
                guard let strongSelf = capturedSelf else { return }
                await strongSelf.handleRequestCancellation(requestId: capturedRequestId)
            }
        }
    }

    /// Handle cancellation of an outgoing request.
    ///
    /// This method sends a cancel notification and waits briefly (up to gracefulCancellationTimeoutSeconds)
    /// for the request to complete gracefully. If the request doesn't complete in time, it's forcibly cancelled.
    private func handleRequestCancellation(requestId: RequestId) async {
        // Send cancel notification to the other side
        await sendCancelNotification(requestId: requestId, message: "Request cancelled by client")

        // Wait for graceful cancellation (up to gracefulCancellationTimeoutSeconds)
        // The request handler may finish its cleanup work within this time
        let startTime = Date()
        let checkInterval: UInt64 = 50_000_000 // 50ms
        while Date().timeIntervalSince(startTime) < gracefulCancellationTimeoutSeconds {
            // Check if the request was already completed (response received or error)
            if pendingOutgoingRequests[requestId] == nil {
                return // Request completed gracefully
            }
            try? await Task.sleep(nanoseconds: checkInterval)
        }

        // Graceful timeout expired - force cancel if still pending
        if let continuation = pendingOutgoingRequests.removeValue(forKey: requestId) {
            continuation.resume(throwing: CancellationError())
        }
    }

    /// Handle request timeout.
    private func handleTimeout(requestId: RequestId, method: String) {
        if let continuation = pendingOutgoingRequests.removeValue(forKey: requestId) {
            continuation.resume(throwing: ProtocolError.timeout(method: method, requestId: requestId))
        }
    }

    /// Handle transport error during request.
    private func handleTransportError(requestId: RequestId, error: Error) {
        if let continuation = pendingOutgoingRequests.removeValue(forKey: requestId) {
            continuation.resume(throwing: error)
        }
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

    /// Registers a handler for requests with a specific method name.
    ///
    /// - Parameters:
    ///   - method: The method name to handle
    ///   - handler: The async handler to invoke when a request arrives, returns the result
    public func onRequest(
        method: String,
        handler: @escaping @Sendable (JsonRpcRequest) async throws -> JsonValue
    ) {
        requestHandlers[method] = handler
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
                await handleRequest(request)

            case .response(let response):
                await handleResponse(response)

            case .error(let error):
                await handleError(error)

            case .notification(let notification):
                await handleNotification(notification)
            }
        }
    }

    /// Handles an incoming request from the agent.
    private func handleRequest(_ request: JsonRpcRequest) async {
        guard let handler = requestHandlers[request.method] else {
            // No handler registered - send method not found error
            let errorResponse = JsonRpcError(
                id: request.id,
                error: JsonRpcError.ErrorInfo(
                    code: -32601,
                    message: "Method not found: \(request.method)",
                    data: nil
                )
            )
            let message = JsonRpcMessage.error(errorResponse)
            do {
                try await transport.send(message)
            } catch {
                errorContinuation?.yield(.encodingFailed(underlying: error))
            }
            return
        }

        // Create a task for handling this request so it can be cancelled
        let requestTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                // Execute handler
                let result = try await handler(request)
                let response = JsonRpcResponse(id: request.id, result: result)
                let message = JsonRpcMessage.response(response)
                try await self.transport.send(message)
            } catch is CancellationError {
                // Request was cancelled - send cancelled error response
                let errorResponse = JsonRpcError(
                    id: request.id,
                    error: JsonRpcError.ErrorInfo(
                        code: -32800, // Request cancelled
                        message: "Request cancelled",
                        data: nil
                    )
                )
                let message = JsonRpcMessage.error(errorResponse)
                do {
                    try await self.transport.send(message)
                } catch {
                    await self.errorContinuation?.yield(.encodingFailed(underlying: error))
                }
            } catch {
                // Handler threw error - send error response
                // Check for errors that provide their own error code
                let errorCode = self.jsonRpcErrorCode(for: error)
                let errorResponse = JsonRpcError(
                    id: request.id,
                    error: JsonRpcError.ErrorInfo(
                        code: errorCode,
                        message: error.localizedDescription,
                        data: nil
                    )
                )
                let message = JsonRpcMessage.error(errorResponse)
                do {
                    try await self.transport.send(message)
                } catch {
                    await self.errorContinuation?.yield(.encodingFailed(underlying: error))
                }
            }

            // Remove from pending incoming requests when done
            await self.removePendingIncomingRequest(requestId: request.id)
        }

        // Track the request task so it can be cancelled
        pendingIncomingRequests[request.id] = requestTask
    }

    /// Removes a pending incoming request from tracking.
    private func removePendingIncomingRequest(requestId: RequestId) {
        pendingIncomingRequests.removeValue(forKey: requestId)
    }

    /// Handles an incoming response.
    private func handleResponse(_ response: JsonRpcResponse) async {
        guard let continuation = pendingOutgoingRequests.removeValue(forKey: response.id) else {
            errorContinuation?.yield(.invalidResponseId(response.id))
            return
        }

        continuation.resume(returning: response)
    }

    /// Handles an incoming error response.
    private func handleError(_ error: JsonRpcError) async {
        guard let id = error.id,
              let continuation = pendingOutgoingRequests.removeValue(forKey: id) else {
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

        // Check if this is a cancellation error
        if error.error.code == -32800 {
            continuation.resume(throwing: CancellationError())
        } else {
            let protocolError = ProtocolError.jsonRpcError(
                code: error.error.code,
                message: error.error.message,
                data: error.error.data
            )
            continuation.resume(throwing: protocolError)
        }
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

    /// Get JSON-RPC error code for an error.
    ///
    /// Checks if the error conforms to `JsonRpcErrorConvertible` protocol
    /// and uses its error code, otherwise returns the generic internal error code.
    private nonisolated func jsonRpcErrorCode(for error: Error) -> Int {
        if let convertible = error as? JsonRpcErrorConvertible {
            return convertible.errorCode
        }
        return -32603 // Internal error
    }
}

// MARK: - JsonRpcErrorConvertible Protocol

/// Protocol for errors that can provide their own JSON-RPC error code.
public protocol JsonRpcErrorConvertible: Error {
    /// The JSON-RPC error code for this error.
    var errorCode: Int { get }
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
