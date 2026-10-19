import Foundation

// MARK: - V2UserMessage

/// **UNSTABLE** - An upsert for a message the user sent (v2).
///
/// Messages are keyed by `messageId`: repeated updates with the same ID patch the stored
/// message. A `content` value replaces everything accumulated for the message so far.
public struct V2UserMessage: Sendable, Hashable {
    public let messageId: MessageId
    public let content: V2MaybeUndefined<[V2ContentBlock]>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        messageId: MessageId,
        content: V2MaybeUndefined<[V2ContentBlock]> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.messageId = messageId
        self.content = content
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case messageId, content
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2UserMessage: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let idStr) = raw["messageId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'messageId' in V2UserMessage"
            )
        }
        self.messageId = MessageId(rawValue: idStr)
        self.content = decodeMaybeUndefinedList(raw, key: "content")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageId, forKey: .messageId)
        try encodeMaybeUndefined(content, forKey: .content, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

// MARK: - V2AgentMessage

/// **UNSTABLE** - An upsert for a message the agent sent (v2).
///
/// Same patch semantics as `V2UserMessage`.
public struct V2AgentMessage: Sendable, Hashable {
    public let messageId: MessageId
    public let content: V2MaybeUndefined<[V2ContentBlock]>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        messageId: MessageId,
        content: V2MaybeUndefined<[V2ContentBlock]> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.messageId = messageId
        self.content = content
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case messageId, content
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2AgentMessage: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let idStr) = raw["messageId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'messageId' in V2AgentMessage"
            )
        }
        self.messageId = MessageId(rawValue: idStr)
        self.content = decodeMaybeUndefinedList(raw, key: "content")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageId, forKey: .messageId)
        try encodeMaybeUndefined(content, forKey: .content, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

// MARK: - V2AgentThought

/// **UNSTABLE** - An upsert for the agent's internal reasoning (v2).
///
/// Same patch semantics as `V2UserMessage`.
public struct V2AgentThought: Sendable, Hashable {
    public let messageId: MessageId
    public let content: V2MaybeUndefined<[V2ContentBlock]>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        messageId: MessageId,
        content: V2MaybeUndefined<[V2ContentBlock]> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.messageId = messageId
        self.content = content
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case messageId, content
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2AgentThought: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let idStr) = raw["messageId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'messageId' in V2AgentThought"
            )
        }
        self.messageId = MessageId(rawValue: idStr)
        self.content = decodeMaybeUndefinedList(raw, key: "content")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageId, forKey: .messageId)
        try encodeMaybeUndefined(content, forKey: .content, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

// MARK: - V2SessionInfoUpdate

/// **UNSTABLE** - Update to session metadata (v2).
///
/// All fields have patch semantics: an omitted field leaves the existing session info
/// unchanged, and `null` clears the corresponding value.
public struct V2SessionInfoUpdate: Sendable, Hashable {
    public let title: V2MaybeUndefined<String>
    public let updatedAt: V2MaybeUndefined<String>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        title: V2MaybeUndefined<String> = .undefined,
        updatedAt: V2MaybeUndefined<String> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.title = title
        self.updatedAt = updatedAt
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case title, updatedAt
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2SessionInfoUpdate: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        self.title = decodeMaybeUndefined(raw, key: "title")
        self.updatedAt = decodeMaybeUndefined(raw, key: "updatedAt")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeMaybeUndefined(title, forKey: .title, into: &container)
        try encodeMaybeUndefined(updatedAt, forKey: .updatedAt, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

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

// MARK: - V2NoticeSeverity

/// **UNSTABLE** - Severity of a session notice (v2).
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2NoticeSeverity: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.rawValue = try c.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    public static let info = V2NoticeSeverity(rawValue: "info")
    public static let warning = V2NoticeSeverity(rawValue: "warning")
    public static let error = V2NoticeSeverity(rawValue: "error")
}

// MARK: - V2Notice

/// **UNSTABLE** - A live advisory notice from the agent (v2).
///
/// Notices are informational only: they MUST NOT carry information required for protocol
/// correctness, authorization, user action, task completion, or fatal-error reporting.
/// Clients may ignore them.
public struct V2Notice: Codable, Sendable, Hashable {
    public let severity: V2NoticeSeverity
    public let title: String
    public let description: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        severity: V2NoticeSeverity,
        title: String,
        description: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.severity = severity
        self.title = title
        self.description = description
        self._meta = _meta
    }
}

// MARK: - V2CompactionStatus

/// **UNSTABLE** - Status of a context compaction operation (v2).
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2CompactionStatus: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.rawValue = try c.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    public static let inProgress = V2CompactionStatus(rawValue: "in_progress")
    public static let completed = V2CompactionStatus(rawValue: "completed")
    public static let failed = V2CompactionStatus(rawValue: "failed")
    public static let cancelled = V2CompactionStatus(rawValue: "cancelled")
}

// MARK: - V2CompactionUpdate

/// **UNSTABLE** - A context compaction event (v2).
///
/// The first update for a `compactionId` fixes its timeline position. `summary`, `error`, and
/// `_meta` have patch semantics: omission leaves the existing value unchanged, `null` clears
/// it, and a concrete value replaces it.
public struct V2CompactionUpdate: Sendable, Hashable {
    public let compactionId: String
    public let status: V2CompactionStatus
    public let summary: V2MaybeUndefined<[V2ContentBlock]>
    public let error: V2MaybeUndefined<String>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        compactionId: String,
        status: V2CompactionStatus,
        summary: V2MaybeUndefined<[V2ContentBlock]> = .undefined,
        error: V2MaybeUndefined<String> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.compactionId = compactionId
        self.status = status
        self.summary = summary
        self.error = error
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case compactionId, status, summary, error
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2CompactionUpdate: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let cid) = raw["compactionId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'compactionId' in V2CompactionUpdate"
            )
        }
        guard case .string(let statusStr) = raw["status"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'status' in V2CompactionUpdate"
            )
        }
        self.compactionId = cid
        self.status = V2CompactionStatus(rawValue: statusStr)
        self.summary = decodeMaybeUndefinedList(raw, key: "summary")
        self.error = decodeMaybeUndefined(raw, key: "error")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(compactionId, forKey: .compactionId)
        try container.encode(status, forKey: .status)
        try encodeMaybeUndefined(summary, forKey: .summary, into: &container)
        try encodeMaybeUndefined(error, forKey: .error, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

// MARK: - V2CompactionSummaryChunk

/// **UNSTABLE** - One content block appended to a compaction's retained summary (v2).
///
/// Chunks are only valid between the initial `in_progress` update and the terminal update
/// for the same `compactionId`.
public struct V2CompactionSummaryChunk: Codable, Sendable, Hashable {
    public let compactionId: String
    public let content: V2ContentBlock
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        compactionId: String,
        content: V2ContentBlock,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.compactionId = compactionId
        self.content = content
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
    case userMessage(V2UserMessage)
    case agentMessageChunk(V2ContentChunk)
    case agentMessage(V2AgentMessage)
    case agentThoughtChunk(V2ContentChunk)
    case agentThought(V2AgentThought)
    case stateUpdate(V2StateUpdate)
    case toolCallContentChunk(V2ToolCallContentChunk)
    case toolCallUpdate(V2ToolCallUpdate)
    case planUpdate(V2PlanUpdate)
    case planRemoved(V2PlanRemoved)
    case availableCommandsUpdate(V2AvailableCommandsUpdate)
    case configOptionUpdate(V2ConfigOptionUpdate)
    case sessionInfoUpdate(V2SessionInfoUpdate)
    case usageUpdate(V2UsageUpdate)
    case notice(V2Notice)
    case compactionUpdate(V2CompactionUpdate)
    case compactionSummaryChunk(V2CompactionSummaryChunk)
    case unknown(sessionUpdate: String, rawJson: [String: JsonValue])

    private enum DiscKey: String, CodingKey { case sessionUpdate }

    public init(from decoder: Decoder) throws {
        let discContainer = try decoder.container(keyedBy: DiscKey.self)
        let typeStr = try discContainer.decode(String.self, forKey: .sessionUpdate)
        switch typeStr {
        case "user_message_chunk":
            self = .userMessageChunk(try V2ContentChunk(from: decoder))
        case "user_message":
            self = .userMessage(try V2UserMessage(from: decoder))
        case "agent_message_chunk":
            self = .agentMessageChunk(try V2ContentChunk(from: decoder))
        case "agent_message":
            self = .agentMessage(try V2AgentMessage(from: decoder))
        case "agent_thought_chunk":
            self = .agentThoughtChunk(try V2ContentChunk(from: decoder))
        case "agent_thought":
            self = .agentThought(try V2AgentThought(from: decoder))
        case "state_update":
            self = .stateUpdate(try V2StateUpdate(from: decoder))
        case "tool_call_content_chunk":
            self = .toolCallContentChunk(try V2ToolCallContentChunk(from: decoder))
        case "tool_call_update":
            self = .toolCallUpdate(try V2ToolCallUpdate(from: decoder))
        case "plan_update":
            self = .planUpdate(try V2PlanUpdate(from: decoder))
        case "plan_removed":
            self = .planRemoved(try V2PlanRemoved(from: decoder))
        case "available_commands_update":
            self = .availableCommandsUpdate(try V2AvailableCommandsUpdate(from: decoder))
        case "config_option_update":
            self = .configOptionUpdate(try V2ConfigOptionUpdate(from: decoder))
        case "session_info_update":
            self = .sessionInfoUpdate(try V2SessionInfoUpdate(from: decoder))
        case "usage_update":
            self = .usageUpdate(try V2UsageUpdate(from: decoder))
        case "notice":
            self = .notice(try V2Notice(from: decoder))
        case "compaction_update":
            self = .compactionUpdate(try V2CompactionUpdate(from: decoder))
        case "compaction_summary_chunk":
            self = .compactionSummaryChunk(try V2CompactionSummaryChunk(from: decoder))
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
        case .userMessage(let v):
            try discContainer.encode("user_message", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .agentMessageChunk(let v):
            try discContainer.encode("agent_message_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .agentMessage(let v):
            try discContainer.encode("agent_message", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .agentThoughtChunk(let v):
            try discContainer.encode("agent_thought_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .agentThought(let v):
            try discContainer.encode("agent_thought", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .stateUpdate(let v):
            try discContainer.encode("state_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .toolCallContentChunk(let v):
            try discContainer.encode("tool_call_content_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .toolCallUpdate(let v):
            try discContainer.encode("tool_call_update", forKey: .sessionUpdate)
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
        case .sessionInfoUpdate(let v):
            try discContainer.encode("session_info_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .usageUpdate(let v):
            try discContainer.encode("usage_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .notice(let v):
            try discContainer.encode("notice", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .compactionUpdate(let v):
            try discContainer.encode("compaction_update", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .compactionSummaryChunk(let v):
            try discContainer.encode("compaction_summary_chunk", forKey: .sessionUpdate)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}
