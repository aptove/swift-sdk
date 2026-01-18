import ACPModel
import Foundation

/// Protocol for client-side session operations.
///
/// Combines file system, terminal, and permission operations that
/// agents can invoke on clients during prompt processing.
///
/// ## Capabilities
///
/// Implement methods based on capabilities advertised:
/// - `fs.readTextFile` / `fs.writeTextFile`: File system operations
/// - `terminal`: Terminal operations
/// - Permission requests are always available
///
/// ## Usage
///
/// ```swift
/// class MySessionOperations: ClientSessionOperations {
///     func requestPermissions(
///         toolCall: ToolCallUpdateData,
///         permissions: [PermissionOption]
///     ) async throws -> RequestPermissionResponse {
///         // Present UI to user and return their selection
///         return RequestPermissionResponse(outcome: .selected(permissions[0].optionId))
///     }
///
///     func notify(notification: SessionUpdate) async {
///         // Handle out-of-band notifications
///     }
/// }
/// ```
public protocol ClientSessionOperations: FileSystemOperations, TerminalOperations {

    /// Request permissions from the user for a tool call.
    ///
    /// Called when the agent needs user authorization before performing
    /// a sensitive operation. Present the options to the user and return
    /// their selection.
    ///
    /// - Parameters:
    ///   - toolCall: The tool call that needs permission
    ///   - permissions: Available permission options to present
    ///   - meta: Optional metadata
    /// - Returns: The user's decision
    /// - Throws: Error if permission request fails
    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse

    /// Handle a notification from the agent not bound to a prompt.
    ///
    /// Called for session updates that occur outside of a prompt turn.
    ///
    /// - Parameters:
    ///   - notification: The session update
    ///   - meta: Optional metadata
    func notify(notification: SessionUpdate, meta: MetaField?) async
}

// MARK: - Default Implementations

extension ClientSessionOperations {

    /// Default implementation that throws not implemented error.
    public func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        throw ClientError.notImplemented("requestPermissions - Client must handle permission requests")
    }

    /// Default implementation that does nothing.
    public func notify(notification: SessionUpdate, meta: MetaField?) async {
        // Default: ignore notifications
    }
}
