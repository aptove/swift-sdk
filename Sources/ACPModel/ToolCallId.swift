import Foundation

/// A unique identifier for a tool call.
///
/// Tool calls represent agent requests to execute tools through the client.
public struct ToolCallId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a tool call ID from a string value.
    ///
    /// - Parameter value: The tool call ID string
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

extension ToolCallId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension ToolCallId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
