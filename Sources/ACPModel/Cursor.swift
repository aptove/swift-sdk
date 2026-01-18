import Foundation

/// An opaque cursor for pagination.
///
/// Cursors are used to track position in paginated result sets.
/// They should be treated as opaque strings and not interpreted by clients.
public struct Cursor: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a cursor from a string value.
    ///
    /// - Parameter value: The cursor string
    public init(value: String) {
        self.value = value
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - CustomStringConvertible

extension Cursor: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension Cursor: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
