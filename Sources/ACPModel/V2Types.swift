import Foundation

// MARK: - V2Role

/// **UNSTABLE** - The sender or recipient of messages and data in a conversation.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2Role: Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public static let assistant = V2Role(rawValue: "assistant")
    public static let user = V2Role(rawValue: "user")
}

extension V2Role: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension V2Role: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - V2StopReason

/// **UNSTABLE** - Reasons why an agent stops active session work.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2StopReason: Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public static let endTurn = V2StopReason(rawValue: "end_turn")
    public static let maxTokens = V2StopReason(rawValue: "max_tokens")
    public static let maxTurnRequests = V2StopReason(rawValue: "max_turn_requests")
    public static let refusal = V2StopReason(rawValue: "refusal")
    public static let cancelled = V2StopReason(rawValue: "cancelled")
}

extension V2StopReason: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension V2StopReason: CustomStringConvertible {
    public var description: String { rawValue }
}
