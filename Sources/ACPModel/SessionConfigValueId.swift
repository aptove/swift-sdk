import Foundation

/// A unique identifier for a session configuration value (unstable API).
///
/// Configuration values identify user selections in session config options.
public struct SessionConfigValueId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a session config value ID from a string value.
    ///
    /// - Parameter value: The config value ID string
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

extension SessionConfigValueId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension SessionConfigValueId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
