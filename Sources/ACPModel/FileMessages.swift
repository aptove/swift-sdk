import Foundation

// MARK: - File System Request/Response Types

/// Request to read content from a text file.
///
/// Only available if the client supports the `fs.readTextFile` capability.
/// The client reads the file and returns its content.
public struct ReadTextFileRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this request belongs to
    public let sessionId: SessionId

    /// The path to the file to read
    public let path: String

    /// Starting line number (1-indexed, optional)
    public let line: UInt32?

    /// Maximum number of lines to read (optional)
    public let limit: UInt32?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a read text file request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - path: The file path to read
    ///   - line: Starting line number (1-indexed)
    ///   - limit: Maximum lines to read
    ///   - meta: Optional metadata
    public init(
        sessionId: SessionId,
        path: String,
        line: UInt32? = nil,
        limit: UInt32? = nil,
        meta: MetaField? = nil
    ) {
        self.sessionId = sessionId
        self.path = path
        self.line = line
        self.limit = limit
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case path = "path"
        case line = "line"
        case limit = "limit"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response containing the contents of a text file.
public struct ReadTextFileResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The file content
    public let content: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a read text file response.
    ///
    /// - Parameters:
    ///   - content: The file content
    ///   - meta: Optional metadata
    public init(content: String, meta: MetaField? = nil) {
        self.content = content
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case content = "content"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Request to write content to a text file.
///
/// Only available if the client supports the `fs.writeTextFile` capability.
/// The client writes the content to the specified path, creating or overwriting
/// the file as needed.
public struct WriteTextFileRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this request belongs to
    public let sessionId: SessionId

    /// The path to write the file to
    public let path: String

    /// The content to write
    public let content: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a write text file request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - path: The file path to write
    ///   - content: The content to write
    ///   - meta: Optional metadata
    public init(
        sessionId: SessionId,
        path: String,
        content: String,
        meta: MetaField? = nil
    ) {
        self.sessionId = sessionId
        self.path = path
        self.content = content
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case path = "path"
        case content = "content"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

/// Response from writing a text file.
public struct WriteTextFileResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a write text file response.
    ///
    /// - Parameter meta: Optional metadata
    public init(meta: MetaField? = nil) {
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}
