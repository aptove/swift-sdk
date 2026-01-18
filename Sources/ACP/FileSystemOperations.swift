import ACPModel
import Foundation

/// Protocol for file system operations that agents can invoke on clients.
///
/// Clients that support file system capabilities implement this protocol
/// to allow agents to read and write files in the user's environment.
///
/// ## Capabilities
///
/// File operations are gated by client capabilities:
/// - `fs.readTextFile`: Enables `fsReadTextFile` method
/// - `fs.writeTextFile`: Enables `fsWriteTextFile` method
///
/// ## Usage
///
/// Implement this protocol in your client to provide file access:
///
/// ```swift
/// class MyClient: Client, FileSystemOperations {
///     func fsReadTextFile(
///         sessionId: SessionId,
///         path: String,
///         line: UInt32?,
///         limit: UInt32?,
///         meta: MetaField?
///     ) async throws -> ReadTextFileResponse {
///         let content = try String(contentsOfFile: path, encoding: .utf8)
///         return ReadTextFileResponse(content: content)
///     }
///
///     func fsWriteTextFile(
///         sessionId: SessionId,
///         path: String,
///         content: String,
///         meta: MetaField?
///     ) async throws -> WriteTextFileResponse {
///         try content.write(toFile: path, atomically: true, encoding: .utf8)
///         return WriteTextFileResponse()
///     }
/// }
/// ```
public protocol FileSystemOperations: Sendable {

    /// Read text content from a file.
    ///
    /// The client reads the file at the given path and returns its content.
    /// If `line` and `limit` are provided, only a portion of the file is returned.
    ///
    /// - Parameters:
    ///   - sessionId: The session making the request
    ///   - path: The file path to read
    ///   - line: Starting line number (1-indexed, optional)
    ///   - limit: Maximum number of lines to read (optional)
    ///   - meta: Optional metadata
    /// - Returns: The file content
    /// - Throws: Error if file cannot be read
    func fsReadTextFile(
        sessionId: SessionId,
        path: String,
        line: UInt32?,
        limit: UInt32?,
        meta: MetaField?
    ) async throws -> ReadTextFileResponse

    /// Write text content to a file.
    ///
    /// The client writes the content to the specified path, creating
    /// the file if it doesn't exist or overwriting if it does.
    ///
    /// - Parameters:
    ///   - sessionId: The session making the request
    ///   - path: The file path to write
    ///   - content: The content to write
    ///   - meta: Optional metadata
    /// - Returns: Confirmation of the write
    /// - Throws: Error if file cannot be written
    func fsWriteTextFile(
        sessionId: SessionId,
        path: String,
        content: String,
        meta: MetaField?
    ) async throws -> WriteTextFileResponse
}

// MARK: - Default Implementations

extension FileSystemOperations {

    /// Default implementation that throws not implemented error.
    public func fsReadTextFile(
        sessionId: SessionId,
        path: String,
        line: UInt32?,
        limit: UInt32?,
        meta: MetaField?
    ) async throws -> ReadTextFileResponse {
        throw ClientError.notImplemented("fsReadTextFile - Client must advertise fs.readTextFile capability")
    }

    /// Default implementation that throws not implemented error.
    public func fsWriteTextFile(
        sessionId: SessionId,
        path: String,
        content: String,
        meta: MetaField?
    ) async throws -> WriteTextFileResponse {
        throw ClientError.notImplemented("fsWriteTextFile - Client must advertise fs.writeTextFile capability")
    }
}
