import ACPModel
import Foundation

/// Transport connection state.
///
/// Represents the lifecycle of a transport connection:
/// - `.created`: Initial state after initialization
/// - `.starting`: Transport is launching read/write tasks
/// - `.started`: Fully operational, can send and receive messages
/// - `.closing`: Transport is shutting down
/// - `.closed`: Fully shut down, no further operations possible
public enum TransportState: String, Sendable, Equatable {
    /// Initial state after initialization.
    case created = "created"
    /// Transport is starting (launching read/write tasks).
    case starting = "starting"
    /// Transport is fully operational.
    case started = "started"
    /// Transport is shutting down.
    case closing = "closing"
    /// Transport is fully closed.
    case closed = "closed"
}

/// Base protocol for ACP transport implementations.
///
/// Transports handle the actual communication between clients and agents,
/// supporting various protocols like STDIO, WebSocket, HTTP, and SSE.
///
/// ## Connection Lifecycle
///
/// A transport goes through the following states:
/// 1. `.created` - Initial state after initialization
/// 2. `.starting` - `start()` called, launching read/write tasks
/// 3. `.started` - Fully operational, can send and receive messages
/// 4. `.closing` - `close()` called, cleaning up resources
/// 5. `.closed` - Fully shut down, no further operations possible
///
/// ## Usage Example
///
/// ```swift
/// let transport = StdioTransport()
///
/// // Monitor state changes
/// Task {
///     for await state in transport.state {
///         print("Transport state: \(state)")
///     }
/// }
///
/// // Start the transport
/// try await transport.start()
///
/// // Send a message
/// let request = JsonRpcRequest(id: .int(1), method: "initialize", params: nil)
/// try await transport.send(.request(request))
///
/// // Receive messages
/// for await message in transport.messages {
///     print("Received: \(message)")
/// }
///
/// // Clean shutdown
/// await transport.close()
/// ```
public protocol Transport: AnyObject, Sendable {
    /// Async stream of state changes.
    ///
    /// Subscribers will receive state updates as the transport progresses
    /// through its lifecycle. The stream completes when the transport reaches `.closed`.
    var state: AsyncStream<TransportState> { get }

    /// Start the transport and begin listening for messages.
    ///
    /// This method launches the read and write tasks in the background.
    /// It can only be called once - subsequent calls will throw an error.
    ///
    /// - Throws: An error if the transport is not in `.created` state,
    ///   or if initialization fails.
    func start() async throws

    /// Send a JSON-RPC message over the transport.
    ///
    /// Messages are queued and sent asynchronously. This method returns
    /// after the message is queued, not after it's actually sent.
    ///
    /// - Parameter message: The JSON-RPC message to send.
    /// - Throws: An error if the transport is not in `.started` state,
    ///   or if serialization/sending fails.
    func send(_ message: JsonRpcMessage) async throws

    /// Async stream of received JSON-RPC messages.
    ///
    /// Messages are delivered in the order they are received from the underlying
    /// transport. The stream completes when the transport is closed or encounters
    /// a fatal error.
    ///
    /// Malformed messages are logged and skipped - they don't appear in this stream.
    var messages: AsyncStream<JsonRpcMessage> { get }

    /// Close the transport and release all resources.
    ///
    /// This method is idempotent - it can be called multiple times safely.
    /// It cancels all pending operations and transitions to `.closed` state.
    ///
    /// Any pending messages in the send queue may be lost.
    func close() async
}
