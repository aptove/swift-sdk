import Foundation

/// Optional annotations for content blocks.
///
/// The client can use annotations to inform how objects are used or displayed.
public struct Annotations: Codable, Sendable, Hashable {
    /// Intended audience for this content
    public let audience: [Role]?

    /// Priority level (higher values indicate higher priority)
    public let priority: Double?

    /// ISO 8601 timestamp of last modification
    public let lastModified: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates annotations.
    ///
    /// - Parameters:
    ///   - audience: Intended audience
    ///   - priority: Priority level
    ///   - lastModified: Last modification timestamp
    ///   - _meta: Optional metadata
    public init(
        audience: [Role]? = nil,
        priority: Double? = nil,
        lastModified: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.audience = audience
        self.priority = priority
        self.lastModified = lastModified
        self._meta = _meta
    }
}
