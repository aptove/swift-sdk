import ACPModel
import Foundation

/// Protocol for ACP clients to receive agent callbacks.
///
/// Clients connect to agents and send prompts. The agent may call back
/// into the client through this delegate protocol.
///
/// ## Required Properties
/// - `capabilities`: Client capabilities to advertise during initialization
///
/// ## Optional Methods
/// - Various hooks for agent callbacks (e.g., tool calls, sampling requests)
///
/// ## Example Implementation
///
/// ```swift
/// struct SimpleClient: Client {
///     var capabilities: ClientCapabilities {
///         ClientCapabilities()
///     }
///
///     var info: Implementation? {
///         Implementation(name: "SimpleClient", version: "1.0")
///     }
/// }
/// ```
public protocol Client: Sendable {
    /// Capabilities advertised by this client during initialization.
    var capabilities: ClientCapabilities { get }

    /// Optional implementation information for this client.
    var info: Implementation? { get }

    /// Called when the agent sends a session update.
    ///
    /// Default implementation does nothing.
    ///
    /// - Parameter update: The session update notification
    func onSessionUpdate(_ update: SessionInfoUpdate) async

    /// Called when the connection to the agent is established.
    ///
    /// Default implementation does nothing.
    func onConnected() async

    /// Called when the connection to the agent is lost.
    ///
    /// Default implementation does nothing.
    ///
    /// - Parameter error: The error that caused disconnection, if any
    func onDisconnected(error: Error?) async
}

// MARK: - Default Implementations

public extension Client {
    /// Default info is nil.
    var info: Implementation? { nil }

    /// Default session update handler does nothing.
    func onSessionUpdate(_ update: SessionInfoUpdate) async {}

    /// Default connected handler does nothing.
    func onConnected() async {}

    /// Default disconnected handler does nothing.
    func onDisconnected(error: Error?) async {}
}

// MARK: - Client Errors

/// Errors specific to client operations.
public enum ClientError: Error, Sendable, LocalizedError {
    /// Not connected to an agent.
    case notConnected

    /// Already connected to an agent.
    case alreadyConnected

    /// Connection was rejected by the agent.
    case connectionRejected(String)

    /// Request timed out waiting for agent response.
    case timeout

    /// Invalid response received from agent.
    case invalidResponse(String)

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to an agent"
        case .alreadyConnected:
            return "Already connected to an agent"
        case .connectionRejected(let reason):
            return "Connection rejected: \(reason)"
        case .timeout:
            return "Request timed out"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        }
    }
}
