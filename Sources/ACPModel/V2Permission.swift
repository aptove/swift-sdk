import Foundation

// MARK: - V2PermissionOption

/// **UNSTABLE** - One choice offered to the user in a permission request (v2).
public struct V2PermissionOption: Codable, Sendable, Hashable {
    public let optionId: PermissionOptionId
    public let name: String
    public let kind: V2PermissionOptionKind
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        optionId: PermissionOptionId,
        name: String,
        kind: V2PermissionOptionKind,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.optionId = optionId
        self.name = name
        self.kind = kind
        self._meta = _meta
    }
}

// MARK: - V2RequestPermissionSubject

/// **UNSTABLE** - What a permission request is being asked about (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2RequestPermissionSubject: Codable, Sendable, Hashable {
    case toolCall(V2ToolCallUpdate, _meta: MetaField?) // swiftlint:disable:this identifier_name
    case command(Command)
    case unknown(type: String, rawJson: [String: JsonValue])

    /// **UNSTABLE** - Permission to execute `command` in `cwd` (must be an absolute path).
    ///
    /// `toolCallId` and `terminalId` only associate the permission with displayed state
    /// and may be unavailable before execution starts. Selecting an allow option authorizes
    /// the agent to execute the command; it does not ask the client to execute it.
    public struct Command: Codable, Sendable, Hashable {
        public let command: String
        public let cwd: String
        public let toolCallId: ToolCallId?
        public let terminalId: TerminalId?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(
            command: String,
            cwd: String,
            toolCallId: ToolCallId? = nil,
            terminalId: TerminalId? = nil,
            _meta: MetaField? = nil // swiftlint:disable:this identifier_name
        ) {
            self.command = command
            self.cwd = cwd
            self.toolCallId = toolCallId
            self.terminalId = terminalId
            self._meta = _meta
        }
    }

    private enum TypeKey: String, CodingKey { case type }
    private enum ToolCallKeys: String, CodingKey {
        case type, toolCall
        case _meta // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "tool_call":
            let c = try decoder.container(keyedBy: ToolCallKeys.self)
            let toolCall = try c.decode(V2ToolCallUpdate.self, forKey: .toolCall)
            let meta = try c.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .toolCall(toolCall, _meta: meta)
        case "command":
            self = .command(try Command(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .toolCall(let toolCall, let meta):
            var c = encoder.container(keyedBy: ToolCallKeys.self)
            try c.encode("tool_call", forKey: .type)
            try c.encode(toolCall, forKey: .toolCall)
            try c.encodeIfPresent(meta, forKey: ._meta)
        case .command(let v):
            var c = encoder.container(keyedBy: TypeKey.self)
            try c.encode("command", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2RequestPermissionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/request_permission` method.
///
/// Sent by the agent while a turn is running. A client that cancels active work MUST
/// answer every pending request of this kind with `V2RequestPermissionOutcome.cancelled`.
public struct V2RequestPermissionRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let title: String
    public let options: [V2PermissionOption]
    public let description: String?
    public let subject: V2RequestPermissionSubject?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        title: String,
        options: [V2PermissionOption],
        description: String? = nil,
        subject: V2RequestPermissionSubject? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.title = title
        self.options = options
        self.description = description
        self.subject = subject
        self._meta = _meta
    }
}

// MARK: - V2RequestPermissionResponse

/// **UNSTABLE** - Response to the v2 `session/request_permission` method.
public struct V2RequestPermissionResponse: Codable, Sendable, Hashable {
    public let outcome: V2RequestPermissionOutcome
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(outcome: V2RequestPermissionOutcome, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.outcome = outcome
        self._meta = _meta
    }
}
