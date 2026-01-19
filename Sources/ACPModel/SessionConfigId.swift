import Foundation

/// A unique identifier for a session configuration option (unstable API).
///
/// Configuration option IDs identify specific configuration settings
/// that can be modified during a session.
public struct SessionConfigId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a session config ID from a string value.
    ///
    /// - Parameter value: The config ID string
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

extension SessionConfigId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension SessionConfigId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
