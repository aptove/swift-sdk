/// ACPModel module
///
/// Pure data models representing the Agent Client Protocol (ACP) specification.
/// This module has no dependencies on the core runtime and can be used standalone
/// for schema validation, code generation, or integration with other systems.
///
/// Key components:
/// - JSON-RPC 2.0 message types
/// - ACP protocol message types (requests, responses, notifications)
/// - Content blocks and tool definitions
/// - Capability structures
/// - Session and prompt types

public struct ACPModel {
    /// The version of the ACP schema this SDK implements
    public static let schemaVersion = "0.9.1"
    
    /// The version of this SDK
    public static let sdkVersion = "1.0.0"
}
