import Foundation

/// Notification that a new tool call has been initiated.
public struct ToolCallUpdate: Codable, Sendable, Hashable {
    public let toolCallId: ToolCallId
    public let title: String
    public let kind: ToolKind?
    public let status: ToolCallStatus?
    public let content: [ToolCallContent]
    public let locations: [ToolCallLocation]
    public let rawInput: JsonValue?
    public let rawOutput: JsonValue?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        toolCallId: ToolCallId,
        title: String,
        kind: ToolKind? = nil,
        status: ToolCallStatus? = nil,
        content: [ToolCallContent] = [],
        locations: [ToolCallLocation] = [],
        rawInput: JsonValue? = nil,
        rawOutput: JsonValue? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.toolCallId = toolCallId
        self.title = title
        self.kind = kind
        self.status = status
        self.content = content
        self.locations = locations
        self.rawInput = rawInput
        self.rawOutput = rawOutput
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case toolCallId = "toolCallId"
        case title = "title"
        case kind = "kind"
        case status = "status"
        case content = "content"
        case locations = "locations"
        case rawInput = "rawInput"
        case rawOutput = "rawOutput"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toolCallId = try container.decode(ToolCallId.self, forKey: .toolCallId)
        title = try container.decode(String.self, forKey: .title)
        kind = try container.decodeIfPresent(ToolKind.self, forKey: .kind)
        status = try container.decodeIfPresent(ToolCallStatus.self, forKey: .status)
        content = try container.decodeIfPresent([ToolCallContent].self, forKey: .content) ?? []
        locations = try container.decodeIfPresent([ToolCallLocation].self, forKey: .locations) ?? []
        rawInput = try container.decodeIfPresent(JsonValue.self, forKey: .rawInput)
        rawOutput = try container.decodeIfPresent(JsonValue.self, forKey: .rawOutput)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("tool_call", forKey: .sessionUpdate)
        try container.encode(toolCallId, forKey: .toolCallId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(status, forKey: .status)
        if !content.isEmpty {
            try container.encode(content, forKey: .content)
        }
        if !locations.isEmpty {
            try container.encode(locations, forKey: .locations)
        }
        try container.encodeIfPresent(rawInput, forKey: .rawInput)
        try container.encodeIfPresent(rawOutput, forKey: .rawOutput)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Update on the status or results of a tool call.
public struct ToolCallUpdateData: Codable, Sendable, Hashable {
    public let toolCallId: ToolCallId
    public let title: String?
    public let kind: ToolKind?
    public let status: ToolCallStatus?
    public let content: [ToolCallContent]?
    public let locations: [ToolCallLocation]?
    public let rawInput: JsonValue?
    public let rawOutput: JsonValue?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        toolCallId: ToolCallId,
        title: String? = nil,
        kind: ToolKind? = nil,
        status: ToolCallStatus? = nil,
        content: [ToolCallContent]? = nil,
        locations: [ToolCallLocation]? = nil,
        rawInput: JsonValue? = nil,
        rawOutput: JsonValue? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.toolCallId = toolCallId
        self.title = title
        self.kind = kind
        self.status = status
        self.content = content
        self.locations = locations
        self.rawInput = rawInput
        self.rawOutput = rawOutput
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case toolCallId = "toolCallId"
        case title = "title"
        case kind = "kind"
        case status = "status"
        case content = "content"
        case locations = "locations"
        case rawInput = "rawInput"
        case rawOutput = "rawOutput"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toolCallId = try container.decode(ToolCallId.self, forKey: .toolCallId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        kind = try container.decodeIfPresent(ToolKind.self, forKey: .kind)
        status = try container.decodeIfPresent(ToolCallStatus.self, forKey: .status)
        content = try container.decodeIfPresent([ToolCallContent].self, forKey: .content)
        locations = try container.decodeIfPresent([ToolCallLocation].self, forKey: .locations)
        rawInput = try container.decodeIfPresent(JsonValue.self, forKey: .rawInput)
        rawOutput = try container.decodeIfPresent(JsonValue.self, forKey: .rawOutput)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("tool_call_update", forKey: .sessionUpdate)
        try container.encode(toolCallId, forKey: .toolCallId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(locations, forKey: .locations)
        try container.encodeIfPresent(rawInput, forKey: .rawInput)
        try container.encodeIfPresent(rawOutput, forKey: .rawOutput)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// The agent's execution plan for complex tasks.
public struct PlanUpdate: Codable, Sendable, Hashable {
    public let entries: [PlanEntry]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        entries: [PlanEntry],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.entries = entries
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case entries = "entries"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decode([PlanEntry].self, forKey: .entries)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("plan", forKey: .sessionUpdate)
        try container.encode(entries, forKey: .entries)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Available commands are ready or have changed.
public struct AvailableCommandsUpdate: Codable, Sendable, Hashable {
    public let availableCommands: [AvailableCommand]

    public init(availableCommands: [AvailableCommand]) {
        self.availableCommands = availableCommands
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case availableCommands = "availableCommands"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        availableCommands = try container.decode([AvailableCommand].self, forKey: .availableCommands)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("available_commands_update", forKey: .sessionUpdate)
        try container.encode(availableCommands, forKey: .availableCommands)
    }
}

/// The current mode of the session has changed.
public struct CurrentModeUpdate: Codable, Sendable, Hashable {
    public let currentModeId: SessionModeId

    public init(currentModeId: SessionModeId) {
        self.currentModeId = currentModeId
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case currentModeId = "currentModeId"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentModeId = try container.decode(SessionModeId.self, forKey: .currentModeId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("current_mode_update", forKey: .sessionUpdate)
        try container.encode(currentModeId, forKey: .currentModeId)
    }
}

/// Configuration options have been updated (unstable API).
public struct ConfigOptionUpdate: Codable, Sendable, Hashable {
    public let configOptions: [SessionConfigOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        configOptions: [SessionConfigOption],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.configOptions = configOptions
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case configOptions = "configOptions"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configOptions = try container.decode([SessionConfigOption].self, forKey: .configOptions)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("config_option_update", forKey: .sessionUpdate)
        try container.encode(configOptions, forKey: .configOptions)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Session information has been updated (unstable API).
public struct SessionInfoUpdate: Codable, Sendable, Hashable {
    public let title: String?
    public let updatedAt: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        title: String? = nil,
        updatedAt: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.title = title
        self.updatedAt = updatedAt
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionUpdate = "sessionUpdate"
        case title = "title"
        case updatedAt = "updatedAt"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("session_info_update", forKey: .sessionUpdate)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}
