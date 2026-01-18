/// ACP module
///
/// Core Agent Client Protocol runtime implementation.
/// Provides agent and client abstractions, protocol layer, and STDIO transport.
///
/// Key components:
/// - Protocol: JSON-RPC 2.0 implementation with typed method extensions
/// - Agent: Protocol for building ACP-compliant agents
/// - AgentConnection: Manages agent-side connections
/// - Client: Protocol for building ACP-compliant clients
/// - ClientConnection: Manages client-side connections
/// - Transport: Abstract message transport with STDIO implementation
/// - Session management and streaming support
///
/// ## Quick Start - Building an Agent
///
/// ```swift
/// import ACP
/// import ACPModel
///
/// struct MyAgent: Agent {
///     var capabilities: AgentCapabilities {
///         AgentCapabilities(sessions: SessionsCapability())
///     }
///
///     func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
///         NewSessionResponse(sessionId: SessionId())
///     }
///
///     func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
///         PromptResponse(stopReason: .endTurn)
///     }
/// }
///
/// // Run agent over stdio
/// let transport = StdioTransport()
/// let connection = AgentConnection(transport: transport, agent: MyAgent())
/// try await connection.start()
/// await connection.waitUntilComplete()
/// ```
///
/// ## Quick Start - Building a Client
///
/// ```swift
/// import ACP
/// import ACPModel
///
/// struct MyClient: Client {
///     var capabilities: ClientCapabilities { ClientCapabilities() }
/// }
///
/// let transport = StdioTransport()
/// let connection = ClientConnection(transport: transport, client: MyClient())
/// try await connection.connect()
///
/// let session = try await connection.createSession(request: NewSessionRequest())
/// let response = try await connection.prompt(request: PromptRequest(sessionId: session.sessionId))
///
/// await connection.disconnect()
/// ```

import Logging

// Re-export ACPModel types for convenience
@_exported import ACPModel

public struct ACP {
    /// The version of this SDK
    public static let version = "1.0.0"
}
