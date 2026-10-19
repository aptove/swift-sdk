import Foundation

// Note: SessionConfigOption is now fully implemented in SessionConfigOption.swift

// MARK: - Cost

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Cost information for token usage.
public struct Cost: Codable, Sendable, Hashable {
    /// The cost amount
    public let amount: Double

    /// The currency code (e.g. "USD")
    public let currency: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        amount: Double,
        currency: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.amount = amount
        self.currency = currency
        self._meta = _meta
    }
}

/// Updates that can be sent during session processing.
///
/// These updates provide real-time feedback about the agent's progress.
///
/// See protocol docs: [Agent Reports Output](https://agentclientprotocol.com/protocol/prompt-turn#3-agent-reports-output)
public enum SessionUpdate: Codable, Sendable, Hashable {
    /// A chunk of the user's message being streamed
    case userMessageChunk(UserMessageChunk)

    /// A chunk of the agent's response being streamed
    case agentMessageChunk(AgentMessageChunk)

    /// A chunk of the agent's internal reasoning being streamed
    case agentThoughtChunk(AgentThoughtChunk)

    /// Notification that a new tool call has been initiated
    case toolCall(ToolCallUpdate)

    /// Update on the status or results of a tool call
    case toolCallUpdate(ToolCallUpdateData)

    /// The agent's execution plan for complex tasks
    case planUpdate(PlanUpdate)

    /// Available commands are ready or have changed
    case availableCommandsUpdate(AvailableCommandsUpdate)

    /// The current mode of the session has changed
    case currentModeUpdate(CurrentModeUpdate)

    /// Configuration options have been updated (unstable)
    case configOptionUpdate(ConfigOptionUpdate)

    /// Session information has been updated (unstable)
    case sessionInfoUpdate(SessionInfoUpdate)

    /// **UNSTABLE** - Token usage update for the session
    case usageUpdate(UsageUpdate)

    /// **UNSTABLE** - A plan update with richer format support and plan identity
    case planUpdateV2(PlanUpdateV2)

    /// **UNSTABLE** - Signals that a plan has been dismissed/removed
    case planRemoved(PlanRemovedUpdate)

    /// Unknown session update type for forward compatibility
    case unknown(UnknownSessionUpdate)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .sessionUpdate)

        switch typeString {
        case "user_message_chunk":
            self = .userMessageChunk(try UserMessageChunk(from: decoder))
        case "agent_message_chunk":
            self = .agentMessageChunk(try AgentMessageChunk(from: decoder))
        case "agent_thought_chunk":
            self = .agentThoughtChunk(try AgentThoughtChunk(from: decoder))
        case "tool_call":
            self = .toolCall(try ToolCallUpdate(from: decoder))
        case "tool_call_update":
            self = .toolCallUpdate(try ToolCallUpdateData(from: decoder))
        case "plan":
            self = .planUpdate(try PlanUpdate(from: decoder))
        case "available_commands_update":
            self = .availableCommandsUpdate(try AvailableCommandsUpdate(from: decoder))
        case "current_mode_update":
            self = .currentModeUpdate(try CurrentModeUpdate(from: decoder))
        case "config_option_update":
            self = .configOptionUpdate(try ConfigOptionUpdate(from: decoder))
        case "session_info_update":
            self = .sessionInfoUpdate(try SessionInfoUpdate(from: decoder))
        case "usage_update":
            self = .usageUpdate(try UsageUpdate(from: decoder))
        case "plan_update":
            self = .planUpdateV2(try PlanUpdateV2(from: decoder))
        case "plan_removed":
            self = .planRemoved(try PlanRemovedUpdate(from: decoder))
        default:
            self = .unknown(UnknownSessionUpdate(sessionUpdateType: typeString))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .userMessageChunk(let update):
            try update.encode(to: encoder)
        case .agentMessageChunk(let update):
            try update.encode(to: encoder)
        case .agentThoughtChunk(let update):
            try update.encode(to: encoder)
        case .toolCall(let update):
            try update.encode(to: encoder)
        case .toolCallUpdate(let update):
            try update.encode(to: encoder)
        case .planUpdate(let update):
            try update.encode(to: encoder)
        case .availableCommandsUpdate(let update):
            try update.encode(to: encoder)
        case .currentModeUpdate(let update):
            try update.encode(to: encoder)
        case .configOptionUpdate(let update):
            try update.encode(to: encoder)
        case .sessionInfoUpdate(let update):
            try update.encode(to: encoder)
        case .usageUpdate(let update):
            try update.encode(to: encoder)
        case .planUpdateV2(let update):
            try update.encode(to: encoder)
        case .planRemoved(let update):
            try update.encode(to: encoder)
        case .unknown(let update):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(update.sessionUpdateType, forKey: .sessionUpdate)
        }
    }
}

// MARK: - Update Types

/// A chunk of the user's message being streamed.
public struct UserMessageChunk: Codable, Sendable, Hashable {
    public let content: ContentBlock

    /// **UNSTABLE** - Optional message identifier for correlation
    public let messageId: MessageId?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(content: ContentBlock, messageId: MessageId? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.content = content
        self.messageId = messageId
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case content = "content"
        case messageId = "messageId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
        messageId = try container.decodeIfPresent(MessageId.self, forKey: .messageId)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("user_message_chunk", forKey: .sessionUpdate)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(messageId, forKey: .messageId)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// A chunk of the agent's response being streamed.
public struct AgentMessageChunk: Codable, Sendable, Hashable {
    public let content: ContentBlock

    /// **UNSTABLE** - Optional message identifier for correlation
    public let messageId: MessageId?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(content: ContentBlock, messageId: MessageId? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.content = content
        self.messageId = messageId
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case content = "content"
        case messageId = "messageId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
        messageId = try container.decodeIfPresent(MessageId.self, forKey: .messageId)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("agent_message_chunk", forKey: .sessionUpdate)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(messageId, forKey: .messageId)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// A chunk of the agent's internal reasoning being streamed.
public struct AgentThoughtChunk: Codable, Sendable, Hashable {
    public let content: ContentBlock

    /// **UNSTABLE** - Optional message identifier for correlation
    public let messageId: MessageId?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(content: ContentBlock, messageId: MessageId? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.content = content
        self.messageId = messageId
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case content = "content"
        case messageId = "messageId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
        messageId = try container.decodeIfPresent(MessageId.self, forKey: .messageId)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("agent_thought_chunk", forKey: .sessionUpdate)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(messageId, forKey: .messageId)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}
