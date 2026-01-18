/// ACP module
///
/// Core Agent Client Protocol runtime implementation.
/// Provides agent and client abstractions, protocol layer, and STDIO transport.
///
/// Key components:
/// - Protocol: JSON-RPC 2.0 implementation
/// - Agent: Build ACP-compliant agents
/// - Client: Build ACP-compliant clients
/// - Transport: Abstract message transport with STDIO implementation
/// - Session management and streaming support

import ACPModel
import Logging

public struct ACP {
    /// The version of this SDK
    public static let version = "1.0.0"
}
