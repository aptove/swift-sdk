import Foundation

/// Configuration option for a session (unstable API).
///
/// **STUB IMPLEMENTATION**
///
/// This is a minimal stub created during Sprint 2 to unblock compilation.
/// Full implementation tracked in Sprint 3 proposal:
/// `openspec/changes/complete-session-update-types/proposal.md`
///
/// The complete implementation should include 4 variants:
/// - Text, Number, Boolean, Select (with flat/grouped options)
/// - Polymorphic serialization with "type" discriminator
/// - All optional fields and metadata support
public struct SessionConfigOption: Codable, Sendable, Hashable {
    /// Option ID (stub)
    public let id: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a session config option.
    public init(
        id: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self._meta = _meta
    }
}

/// Updates that can be sent during session processing.
///
/// **STUB IMPLEMENTATION**
///
/// This is a minimal stub created during Sprint 2 to unblock compilation.
/// Full implementation tracked in Sprint 3 proposal:
/// `openspec/changes/complete-session-update-types/proposal.md`
///
/// The complete implementation should include 10 variants:
/// - UserMessageChunk, AgentMessageChunk, AgentThoughtChunk
/// - ToolCall, ToolCallUpdate (with 8 fields each)
/// - PlanUpdate, AvailableCommandsUpdate, CurrentModeUpdate
/// - ConfigOptionUpdate, SessionInfoUpdate (unstable)
/// - Polymorphic serialization with "sessionUpdate" discriminator
///
/// See protocol docs: [Agent Reports Output](https://agentclientprotocol.com/protocol/prompt-turn#3-agent-reports-output)
public enum SessionUpdate: Codable, Sendable, Hashable {
    /// User message chunk
    case userMessageChunk(ContentBlock)

    /// Agent message chunk
    case agentMessageChunk(ContentBlock)

    // MARK: - Codable (stub)

    public init(from decoder: Decoder) throws {
        // Stub: just decode as user message for now
        let container = try decoder.singleValueContainer()
        let content = try container.decode(ContentBlock.self)
        self = .userMessageChunk(content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .userMessageChunk(let content):
            try container.encode(content)
        case .agentMessageChunk(let content):
            try container.encode(content)
        }
    }
}
