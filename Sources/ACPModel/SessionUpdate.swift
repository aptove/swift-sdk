import Foundation

// Note: SessionConfigOption is now fully implemented in SessionConfigOption.swift

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

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
    }

    private enum UpdateType: String, Codable {
        case userMessageChunk = "user_message_chunk"
        case agentMessageChunk = "agent_message_chunk"
        case agentThoughtChunk = "agent_thought_chunk"
        case toolCall = "tool_call"
        case toolCallUpdate = "tool_call_update"
        case planUpdate = "plan"
        case availableCommandsUpdate = "available_commands_update"
        case currentModeUpdate = "current_mode_update"
        case configOptionUpdate = "config_option_update"
        case sessionInfoUpdate = "session_info_update"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(UpdateType.self, forKey: .sessionUpdate)

        switch type {
        case .userMessageChunk:
            self = .userMessageChunk(try UserMessageChunk(from: decoder))
        case .agentMessageChunk:
            self = .agentMessageChunk(try AgentMessageChunk(from: decoder))
        case .agentThoughtChunk:
            self = .agentThoughtChunk(try AgentThoughtChunk(from: decoder))
        case .toolCall:
            self = .toolCall(try ToolCallUpdate(from: decoder))
        case .toolCallUpdate:
            self = .toolCallUpdate(try ToolCallUpdateData(from: decoder))
        case .planUpdate:
            self = .planUpdate(try PlanUpdate(from: decoder))
        case .availableCommandsUpdate:
            self = .availableCommandsUpdate(try AvailableCommandsUpdate(from: decoder))
        case .currentModeUpdate:
            self = .currentModeUpdate(try CurrentModeUpdate(from: decoder))
        case .configOptionUpdate:
            self = .configOptionUpdate(try ConfigOptionUpdate(from: decoder))
        case .sessionInfoUpdate:
            self = .sessionInfoUpdate(try SessionInfoUpdate(from: decoder))
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
        }
    }
}

// MARK: - Update Types

/// A chunk of the user's message being streamed.
public struct UserMessageChunk: Codable, Sendable, Hashable {
    public let content: ContentBlock

    public init(content: ContentBlock) {
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case content = "content"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("user_message_chunk", forKey: .sessionUpdate)
        try container.encode(content, forKey: .content)
    }
}

/// A chunk of the agent's response being streamed.
public struct AgentMessageChunk: Codable, Sendable, Hashable {
    public let content: ContentBlock

    public init(content: ContentBlock) {
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case content = "content"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("agent_message_chunk", forKey: .sessionUpdate)
        try container.encode(content, forKey: .content)
    }
}

/// A chunk of the agent's internal reasoning being streamed.
public struct AgentThoughtChunk: Codable, Sendable, Hashable {
    public let content: ContentBlock

    public init(content: ContentBlock) {
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case content = "content"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("agent_thought_chunk", forKey: .sessionUpdate)
        try container.encode(content, forKey: .content)
    }
}
