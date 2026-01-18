import Foundation

/// A unique identifier for a permission option.
///
/// Permission options represent user choices when the agent requests permission.
public struct PermissionOptionId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a permission option ID from a string value.
    ///
    /// - Parameter value: The permission option ID string
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

extension PermissionOptionId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension PermissionOptionId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
