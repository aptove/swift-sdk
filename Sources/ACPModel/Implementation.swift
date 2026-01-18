import Foundation

/// Describes the name and version of an ACP implementation.
///
/// Used by both clients and agents to identify themselves during initialization.
public struct Implementation: Codable, Sendable, Hashable {
    /// The name of the implementation
    public let name: String

    /// The version of the implementation
    public let version: String

    /// An optional human-readable title
    public let title: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an implementation descriptor.
    ///
    /// - Parameters:
    ///   - name: Implementation name
    ///   - version: Implementation version
    ///   - title: Optional human-readable title
    ///   - _meta: Optional metadata
    public init(
        name: String,
        version: String,
        title: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.name = name
        self.version = version
        self.title = title
        self._meta = _meta
    }
}
