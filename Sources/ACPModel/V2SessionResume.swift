import Foundation

// MARK: - V2ReplayFrom

/// **UNSTABLE** - Where replayed session history should begin (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2ReplayFrom: Codable, Sendable, Hashable {
    /// Replay the whole conversation from its first replayable entry.
    case start(_meta: MetaField?) // swiftlint:disable:this identifier_name
    /// Custom or future replay cursor.
    case unknown(type: String, rawJson: [String: JsonValue])

    private enum TypeKey: String, CodingKey { case type }
    private enum StartKeys: String, CodingKey {
        case type
        case _meta // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "start":
            let c = try decoder.container(keyedBy: StartKeys.self)
            let meta = try c.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .start(_meta: meta)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .start(let meta):
            var c = encoder.container(keyedBy: StartKeys.self)
            try c.encode("start", forKey: .type)
            try c.encodeIfPresent(meta, forKey: ._meta)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2ResumeSessionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/resume` method.
///
/// v2 has no `session/load`: resuming replaces it, and `replayFrom` says how much
/// history to replay.
public struct V2ResumeSessionRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let cwd: String
    public let additionalDirectories: [String]
    public let mcpServers: [V2McpServer]
    public let replayFrom: V2ReplayFrom?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        cwd: String,
        additionalDirectories: [String] = [],
        mcpServers: [V2McpServer] = [],
        replayFrom: V2ReplayFrom? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.additionalDirectories = additionalDirectories
        self.mcpServers = mcpServers
        self.replayFrom = replayFrom
        self._meta = _meta
    }
}

// MARK: - V2ResumeSessionResponse

/// **UNSTABLE** - Response to the v2 `session/resume` method.
public struct V2ResumeSessionResponse: Codable, Sendable, Hashable {
    public let configOptions: [V2SessionConfigOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        configOptions: [V2SessionConfigOption] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.configOptions = configOptions
        self._meta = _meta
    }
}

// MARK: - V2SetSessionConfigOptionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/set_config_option` method.
///
/// The chosen value is flattened into this object as `type` and `value` rather than nested.
public struct V2SetSessionConfigOptionRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let configId: SessionConfigId
    public let value: V2SessionConfigOptionValue
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        configId: SessionConfigId,
        value: V2SessionConfigOptionValue,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.configId = configId
        self.value = value
        self._meta = _meta
    }

    private enum OwnKeys: String, CodingKey {
        case sessionId, configId
        case _meta // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let sid) = raw["sessionId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'sessionId' in V2SetSessionConfigOptionRequest"
            )
        }
        guard case .string(let cid) = raw["configId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'configId' in V2SetSessionConfigOptionRequest"
            )
        }
        self.sessionId = SessionId(value: sid)
        self.configId = SessionConfigId(value: cid)
        // Decode value from the fields excluding own keys
        let ownKeys: Set<String> = ["sessionId", "configId", "_meta"]
        let valueDict = JsonValue.object(raw.filter { !ownKeys.contains($0.key) })
        guard let valueData = try? JSONEncoder().encode(valueDict),
              let v = try? JSONDecoder().decode(V2SessionConfigOptionValue.self, from: valueData) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Failed to decode V2SessionConfigOptionValue in V2SetSessionConfigOptionRequest"
            )
        }
        self.value = v
        if let metaRaw = raw["_meta"],
           let metaData = try? JSONEncoder().encode(metaRaw),
           let meta = try? JSONDecoder().decode(MetaField.self, from: metaData) {
            self._meta = meta
        } else {
            self._meta = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        // Encode value to intermediate dict, then merge own fields
        let valueData = try JSONEncoder().encode(value)
        guard let valueJsonValue = try? JSONDecoder().decode(JsonValue.self, from: valueData),
              case .object(var fields) = valueJsonValue else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "V2SessionConfigOptionValue must encode as object")
            )
        }
        fields["sessionId"] = .string(sessionId.value)
        fields["configId"] = .string(configId.value)
        if let meta = _meta,
           let metaData = try? JSONEncoder().encode(meta),
           let metaJsonValue = try? JSONDecoder().decode(JsonValue.self, from: metaData) {
            fields["_meta"] = metaJsonValue
        }
        var c = encoder.singleValueContainer()
        try c.encode(JsonValue.object(fields))
    }
}

// MARK: - V2SetSessionConfigOptionResponse

/// **UNSTABLE** - Response to the v2 `session/set_config_option` method.
public struct V2SetSessionConfigOptionResponse: Codable, Sendable, Hashable {
    public let configOptions: [V2SessionConfigOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        configOptions: [V2SessionConfigOption],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.configOptions = configOptions
        self._meta = _meta
    }
}

// MARK: - V2ForkSessionRequest

/// **UNSTABLE** - Request parameters for the v2 `session/fork` method.
public struct V2ForkSessionRequest: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let cwd: String
    public let additionalDirectories: [String]
    public let mcpServers: [V2McpServer]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        cwd: String,
        additionalDirectories: [String] = [],
        mcpServers: [V2McpServer] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.additionalDirectories = additionalDirectories
        self.mcpServers = mcpServers
        self._meta = _meta
    }
}

// MARK: - V2ForkSessionResponse

/// **UNSTABLE** - Response to the v2 `session/fork` method.
///
/// The `sessionId` is the new session's, not the one that was forked.
public struct V2ForkSessionResponse: Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let configOptions: [V2SessionConfigOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        configOptions: [V2SessionConfigOption] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.configOptions = configOptions
        self._meta = _meta
    }
}
