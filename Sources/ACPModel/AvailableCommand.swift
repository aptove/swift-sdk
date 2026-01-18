import Foundation

/// Input specification for a command.
///
/// Specifies how the agent should collect input for this command.
public enum AvailableCommandInput: Codable, Sendable, Hashable {
    /// All text typed after the command name is provided as unstructured input
    case unstructured(UnstructuredInput)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "type"
    }

    private enum InputType: String, Codable {
        case unstructured = "unstructured"
    }

    public init(from decoder: Decoder) throws {
        // Try to decode with discriminator
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let type = try? container.decode(InputType.self, forKey: .type) {
            switch type {
            case .unstructured:
                self = .unstructured(try UnstructuredInput(from: decoder))
            }
        } else {
            // Fallback to unstructured if no discriminator
            self = .unstructured(try UnstructuredInput(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .unstructured(let input):
            try input.encode(to: encoder)
        }
    }
}

/// Unstructured command input.
public struct UnstructuredInput: Codable, Sendable, Hashable {
    /// A hint to display when input hasn't been provided yet
    public let hint: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates unstructured input.
    public init(
        hint: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.hint = hint
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case hint = "hint"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hint = try container.decode(String.self, forKey: .hint)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("unstructured", forKey: .type)
        try container.encode(hint, forKey: .hint)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Information about a command.
public struct AvailableCommand: Codable, Sendable, Hashable {
    /// Command name
    public let name: String

    /// Command description
    public let description: String

    /// Input specification (if any)
    public let input: AvailableCommandInput?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an available command.
    public init(
        name: String,
        description: String,
        input: AvailableCommandInput? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.name = name
        self.description = description
        self.input = input
        self._meta = _meta
    }
}
