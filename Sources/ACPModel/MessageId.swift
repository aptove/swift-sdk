// MARK: - MessageId

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// A unique message identifier for PromptRequest, session update message chunks, and PromptResponse.
///
/// If provided by the client, the Agent SHOULD echo this value as `userMessageId` in the
/// PromptResponse to confirm it was recorded.
/// Both clients and agents MUST use UUID format for message IDs.
public struct MessageId: Codable, Sendable, Hashable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ value: String) {
        self.rawValue = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension MessageId: CustomStringConvertible {
    public var description: String { rawValue }
}

extension MessageId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
