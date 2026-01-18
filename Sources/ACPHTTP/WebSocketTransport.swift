import ACP
import ACPModel
import Foundation
import Logging

/// WebSocket transport implementation for ACP.
///
/// This transport communicates over WebSocket connections, enabling
/// network-based agent/client communication.
///
/// ## Message Framing
///
/// Messages are sent as WebSocket text frames:
/// - Each JSON-RPC message is serialized to JSON
/// - Sent as a single text frame
/// - Received text frames are parsed as JSON-RPC messages
///
/// ## Usage Example
///
/// ```swift
/// let url = URL(string: "wss://agent.example.com/acp")!
/// let transport = WebSocketTransport(url: url)
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
public final class WebSocketTransport: Transport, @unchecked Sendable {
    private let logger = Logger(label: "WebSocketTransport")
    private let url: URL

    private let stateActor: WebSocketStateActor
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession

    /// Initialize a new WebSocket transport.
    ///
    /// - Parameters:
    ///   - url: The WebSocket URL to connect to (must use ws:// or wss://)
    ///   - session: URLSession to use for connections (defaults to shared)
    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        self.stateActor = WebSocketStateActor()
    }

    public var state: AsyncStream<TransportState> {
        stateActor.stateStream
    }

    public func start() async throws {
        logger.trace("Starting WebSocket transport to \(url)")

        // Ensure we're in created state
        try await stateActor.transitionTo(.starting)

        // Create WebSocket task
        webSocketTask = session.webSocketTask(with: url)

        // Start the connection
        webSocketTask?.resume()

        // Start read loop
        Task {
            await self.readLoop()
        }

        // Transition to started
        try await stateActor.transitionTo(.started)

        logger.trace("WebSocket transport started")
    }

    public func send(_ message: JsonRpcMessage) async throws {
        logger.trace("Sending message: \(message)")

        guard await stateActor.currentState == .started else {
            throw WebSocketTransportError.notConnected
        }

        let data = try JSONEncoder().encode(message)
        guard let text = String(data: data, encoding: .utf8) else {
            throw WebSocketTransportError.encodingFailed
        }

        try await webSocketTask?.send(.string(text))
    }

    public var messages: AsyncStream<JsonRpcMessage> {
        stateActor.messageStream
    }

    public func close() async {
        logger.trace("Closing WebSocket transport")

        do {
            try await stateActor.transitionTo(.closing)
        } catch {
            logger.trace("State transition to closing failed: \(error)")
        }

        // Close WebSocket with normal closure
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        do {
            try await stateActor.transitionTo(.closed)
        } catch {
            logger.trace("State transition to closed failed: \(error)")
        }

        await stateActor.finish()

        logger.trace("WebSocket transport closed")
    }

    // MARK: - Read Loop

    private func readLoop() async {
        logger.trace("Starting read loop")

        while let task = webSocketTask {
            do {
                let message = try await task.receive()

                switch message {
                case .string(let text):
                    await handleTextMessage(text)

                case .data(let data):
                    // Try to decode data as UTF-8 text
                    if let text = String(data: data, encoding: .utf8) {
                        await handleTextMessage(text)
                    } else {
                        logger.warning("Received binary data, ignoring")
                    }

                @unknown default:
                    logger.warning("Unknown WebSocket message type")
                }
            } catch {
                // Check if this is a cancellation or normal closure
                let nsError = error as NSError
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                    // Socket not connected - normal closure
                    logger.trace("WebSocket closed normally")
                    break
                }

                if Task.isCancelled {
                    logger.trace("Read loop cancelled")
                    break
                }

                logger.error("WebSocket receive error: \(error)")

                // For fatal errors, close the transport
                await close()
                break
            }
        }

        logger.trace("Read loop ended")
    }

    private func handleTextMessage(_ text: String) async {
        logger.trace("Received text message: \(text.prefix(100))...")

        guard let data = text.data(using: .utf8) else {
            logger.warning("Failed to convert text to data")
            return
        }

        do {
            let message = try JSONDecoder().decode(JsonRpcMessage.self, from: data)
            await stateActor.emitMessage(message)
        } catch {
            logger.warning("Failed to parse JSON-RPC message: \(error)")
        }
    }
}

// MARK: - WebSocket State Actor

/// Actor managing WebSocket transport state.
private actor WebSocketStateActor {
    private var currentStateValue: TransportState = .created
    private let stateContinuation: AsyncStream<TransportState>.Continuation
    private let messageContinuation: AsyncStream<JsonRpcMessage>.Continuation

    let stateStream: AsyncStream<TransportState>
    let messageStream: AsyncStream<JsonRpcMessage>

    var currentState: TransportState {
        currentStateValue
    }

    init() {
        (stateStream, stateContinuation) = AsyncStream.makeStream()
        (messageStream, messageContinuation) = AsyncStream.makeStream()

        // Yield initial state
        stateContinuation.yield(.created)
    }

    func transitionTo(_ newState: TransportState) throws {
        // Validate transition
        let validTransitions: [TransportState: Set<TransportState>] = [
            .created: [.starting],
            .starting: [.started, .closing],
            .started: [.closing],
            .closing: [.closed],
            .closed: []
        ]

        guard let valid = validTransitions[currentStateValue], valid.contains(newState) else {
            throw WebSocketTransportError.invalidStateTransition(from: currentStateValue, to: newState)
        }

        currentStateValue = newState
        stateContinuation.yield(newState)
    }

    func emitMessage(_ message: JsonRpcMessage) {
        messageContinuation.yield(message)
    }

    func finish() {
        stateContinuation.finish()
        messageContinuation.finish()
    }
}

// MARK: - WebSocket Transport Errors

/// Errors specific to WebSocket transport.
public enum WebSocketTransportError: Error, Sendable, LocalizedError {
    /// Not connected to the server.
    case notConnected

    /// Failed to encode message.
    case encodingFailed

    /// Invalid state transition.
    case invalidStateTransition(from: TransportState, to: TransportState)

    /// Connection failed.
    case connectionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to WebSocket server"
        case .encodingFailed:
            return "Failed to encode message"
        case .invalidStateTransition(let from, let to):
            return "Invalid state transition from \(from) to \(to)"
        case .connectionFailed(let reason):
            return "WebSocket connection failed: \(reason)"
        }
    }
}
