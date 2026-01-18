import Foundation

/// A unique identifier for a session mode.
///
/// Session modes represent different operating modes the agent can use
/// (e.g., "code", "chat", "ask").
public struct SessionModeId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a session mode ID from a string value.
    ///
    /// - Parameter value: The mode ID string
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

extension SessionModeId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension SessionModeId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
