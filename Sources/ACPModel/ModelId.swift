import Foundation

/// A unique identifier for a language model.
///
/// Model IDs identify selectable language models that can process
/// prompts in a session.
public struct ModelId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates a model ID from a string value.
    ///
    /// - Parameter value: The model ID string
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

extension ModelId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension ModelId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
