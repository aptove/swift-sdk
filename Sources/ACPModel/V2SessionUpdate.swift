import Foundation

// MARK: - V2AvailableCommandInput

/// **UNSTABLE** - The input specification for a command (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2AvailableCommandInput: Codable, Sendable, Hashable {
    case text(Text)
    case unknown(type: String, rawJson: [String: JsonValue])

    public struct Text: Codable, Sendable, Hashable {
        public let hint: String
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(hint: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.hint = hint
            self._meta = _meta
        }
    }

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "text":
            self = .text(try Text(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .text(let v):
            try typeContainer.encode("text", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2AvailableCommand

/// **UNSTABLE** - Information about a command (v2).
public struct V2AvailableCommand: Codable, Sendable, Hashable {
    public let name: String
    public let description: String
    public let input: V2AvailableCommandInput?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        name: String,
        description: String,
        input: V2AvailableCommandInput? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.name = name
        self.description = description
        self.input = input
        self._meta = _meta
    }
}

// MARK: - V2ContentChunk

/// **UNSTABLE** - A streamed item of message content (v2).
public struct V2ContentChunk: Codable, Sendable, Hashable {
    public let messageId: MessageId
    public let content: V2ContentBlock
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        messageId: MessageId,
        content: V2ContentBlock,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.messageId = messageId
        self.content = content
        self._meta = _meta
    }
}

// MARK: - V2AvailableCommandsUpdate

/// **UNSTABLE** - Available commands are ready or have changed (v2).
public struct V2AvailableCommandsUpdate: Codable, Sendable, Hashable {
    public let availableCommands: [V2AvailableCommand]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(availableCommands: [V2AvailableCommand], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.availableCommands = availableCommands
        self._meta = _meta
    }
}

// MARK: - V2ConfigOptionUpdate

/// **UNSTABLE** - Session configuration options have been updated (v2).
public struct V2ConfigOptionUpdate: Codable, Sendable, Hashable {
    public let configOptions: [V2SessionConfigOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(configOptions: [V2SessionConfigOption], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.configOptions = configOptions
        self._meta = _meta
    }
}

// MARK: - V2UsageUpdate

/// **UNSTABLE** - Context window and cost update for a session (v2).
public struct V2UsageUpdate: Codable, Sendable, Hashable {
    public let used: Int64
    public let size: Int64
    public let cost: Cost?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        used: Int64,
        size: Int64,
        cost: Cost? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.used = used
        self.size = size
        self.cost = cost
        self._meta = _meta
    }
}

// MARK: - V2StateUpdate

/// **UNSTABLE** - The agent's session state has changed (v2).
///
/// Open tagged union discriminated by `state`. Unknown types preserve the raw JSON.
public enum V2StateUpdate: Codable, Sendable, Hashable {
    case running(_meta: MetaField?) // swiftlint:disable:this identifier_name
    case idle(stopReason: V2StopReason?, usage: Usage?, _meta: MetaField?) // swiftlint:disable:this identifier_name
    case requiresAction(_meta: MetaField?) // swiftlint:disable:this identifier_name
    case unknown(state: String, rawJson: [String: JsonValue])

    private enum StateKey: String, CodingKey { case state }
    private enum IdleKeys: String, CodingKey { case state, stopReason, usage, _meta } // swiftlint:disable:this identifier_name
    private enum MetaKey: String, CodingKey { case state, _meta } // swiftlint:disable:this identifier_name

    public init(from decoder: Decoder) throws {
        let stateContainer = try decoder.container(keyedBy: StateKey.self)
        let stateStr = try stateContainer.decode(String.self, forKey: .state)
        switch stateStr {
        case "running":
            let c = try decoder.container(keyedBy: MetaKey.self)
            let meta = try c.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .running(_meta: meta)
        case "idle":
            let c = try decoder.container(keyedBy: IdleKeys.self)
            let stopReason = try c.decodeIfPresent(V2StopReason.self, forKey: .stopReason)
            let usage = try c.decodeIfPresent(Usage.self, forKey: .usage)
            let meta = try c.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .idle(stopReason: stopReason, usage: usage, _meta: meta)
        case "requires_action":
            let c = try decoder.container(keyedBy: MetaKey.self)
            let meta = try c.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .requiresAction(_meta: meta)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(state: stateStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .running(let meta):
            var c = encoder.container(keyedBy: MetaKey.self)
            try c.encode("running", forKey: .state)
            try c.encodeIfPresent(meta, forKey: ._meta)
        case .idle(let stopReason, let usage, let meta):
            var c = encoder.container(keyedBy: IdleKeys.self)
            try c.encode("idle", forKey: .state)
            try c.encodeIfPresent(stopReason, forKey: .stopReason)
            try c.encodeIfPresent(usage, forKey: .usage)
            try c.encodeIfPresent(meta, forKey: ._meta)
        case .requiresAction(let meta):
            var c = encoder.container(keyedBy: MetaKey.self)
            try c.encode("requires_action", forKey: .state)
            try c.encodeIfPresent(meta, forKey: ._meta)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2SessionUpdate

/// **UNSTABLE** - Session update types for the v2 protocol.
///
/// Open tagged union discriminated by `sessionUpdate`. Unknown types preserve the raw JSON.
public enum V2SessionUpdate: Codable, Sendable, Hashable {
    case userMessageChunk(V2ContentChunk)
    case agentMessageChunk(V2ContentChunk)
    case agentThoughtChunk(V2ContentChunk)
    case stateUpdate(V2StateUpdate)
    case toolCallContentChunk(V2ToolCallContentChunk)
    case planUpdate(V2PlanUpdate)
    case planRemoved(V2PlanRemoved)
    case availableCommandsUpdate(V2AvailableCommandsUpdate)
    case configOptionUpdate(V2ConfigOptionUpdate)
    case usageUpdate(V2UsageUpdate)
    case unknown(sessionUpdate: String, rawJson: [String: JsonValue])

    private enum DiscKey: String, CodingKey { case sessionUpdate }

    public init(from decoder: Decoder) throws {
        let discContainer = try decoder.container(keyedBy: DiscKey.self)
        let typeStr = try discContainer.decode(String.self, forKey: .sessionUpdate)
        switch typeStr {
        case "user_message_chunk":
            self = .userMessageChunk(try V2ContentChunk(from: decoder))
        case "agent_message_chunk":
            self = .agentMessageChunk(try V2ContentChunk(from: decoder))
        case "agent_thought_chunk":
            self = .agentThoughtChunk(try V2ContentChunk(from: decoder))
        case "state_update":
            self = .stateUpdate(try V2StateUpdate(from: decoder))
        case "tool_call_content_chunk":
            self = .toolCallContentChunk(try V2ToolCallContentChunk(from: decoder))
        case "plan_update":
            self = .planUpdate(try V2PlanUpdate(from: decoder))
        case "plan_removed":
            self = .planRemoved(try V2PlanRemoved(from: decoder))
        case "available_commands_update":
            self = .availableCommandsUpdate(try V2AvailableCommandsUpdate(from: decoder))
        case "config_option_update":
            self = .configOptionUpdate(try V2ConfigOptionUpdate(from: decoder))
        case "usage_update":
            self = .usageUpdate(try V2UsageUpdate(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(sessionUpdate: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var discContainer = encoder.container(keyedBy: DiscKey.self)
        switch self {
        case .userMessageChunk(let v):
            try discContainer.encode("user_message_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .agentMessageChunk(let v):
            try discContainer.encode("agent_message_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .agentThoughtChunk(let v):
            try discContainer.encode("agent_thought_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .stateUpdate(let v):
            try discContainer.encode("state_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .toolCallContentChunk(let v):
            try discContainer.encode("tool_call_content_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .planUpdate(let v):
            try discContainer.encode("plan_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .planRemoved(let v):
            try discContainer.encode("plan_removed", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .availableCommandsUpdate(let v):
            try discContainer.encode("available_commands_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .configOptionUpdate(let v):
            try discContainer.encode("config_option_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .usageUpdate(let v):
            try discContainer.encode("usage_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}
