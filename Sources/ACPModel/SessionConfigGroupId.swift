import Foundation

/// A unique identifier for a session configuration group (unstable API).
///
/// Configuration groups organize related config options together.
public struct SessionConfigGroupId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a session config group ID from a string value.
    ///
    /// - Parameter value: The config group ID string
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

extension SessionConfigGroupId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension SessionConfigGroupId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
