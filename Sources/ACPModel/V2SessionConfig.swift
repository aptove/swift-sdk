import Foundation

// MARK: - V2SessionConfigOptionCategory

/// **UNSTABLE** - Semantic category for a session configuration option (v2 open enum).
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2SessionConfigOptionCategory: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let mode = V2SessionConfigOptionCategory(rawValue: "mode")
    public static let model = V2SessionConfigOptionCategory(rawValue: "model")
    public static let modelConfig = V2SessionConfigOptionCategory(rawValue: "model_config")
    public static let thoughtLevel = V2SessionConfigOptionCategory(rawValue: "thought_level")
}

// MARK: - V2SessionConfigSelectGroup

/// **UNSTABLE** - A group of options for a session configuration select (v2).
public struct V2SessionConfigSelectGroup: Codable, Sendable, Hashable {
    public let groupId: SessionConfigGroupId
    public let name: String
    public let options: [SessionConfigSelectOption]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        groupId: SessionConfigGroupId,
        name: String,
        options: [SessionConfigSelectOption],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.groupId = groupId
        self.name = name
        self.options = options
        self._meta = _meta
    }
}

// MARK: - V2SessionConfigSelectOptions

/// **UNSTABLE** - The options of a select-type session configuration option (v2).
///
/// Discriminated by shape: `groupId` key present → Grouped, otherwise Ungrouped.
public enum V2SessionConfigSelectOptions: Codable, Sendable, Hashable {
    case ungrouped([SessionConfigSelectOption])
    case grouped([V2SessionConfigSelectGroup])

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        // Peek at first element to determine shape
        if let firstDecoder = try? container.superDecoder() {
            let firstObj = try? firstDecoder.container(keyedBy: AnyCodingKey.self)
            if firstObj?.allKeys.contains(where: { $0.stringValue == "groupId" }) == true {
                // Re-decode as grouped
                let array = try decoder.singleValueContainer().decode([V2SessionConfigSelectGroup].self)
                self = .grouped(array)
                return
            }
        }
        let array = try decoder.singleValueContainer().decode([SessionConfigSelectOption].self)
        self = .ungrouped(array)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .ungrouped(let options):
            var c = encoder.singleValueContainer()
            try c.encode(options)
        case .grouped(let groups):
            var c = encoder.singleValueContainer()
            try c.encode(groups)
        }
    }
}

private struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int?
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.stringValue = "\(intValue)"; self.intValue = intValue }
}

// MARK: - V2SessionConfigKind

/// **UNSTABLE** - Type-specific payload of a session config option (v2).
public enum V2SessionConfigKind: Sendable, Hashable {
    case select(currentValue: SessionConfigValueId, options: V2SessionConfigSelectOptions)
    case boolean(currentValue: Bool)
    case unknown(type: String, fields: [String: JsonValue])
}

// MARK: - V2SessionConfigOption

/// **UNSTABLE** - A session configuration option selector and its current state (v2).
public struct V2SessionConfigOption: Codable, Sendable, Hashable {
    public let configId: SessionConfigId
    public let name: String
    public let description: String?
    public let category: V2SessionConfigOptionCategory?
    public let kind: V2SessionConfigKind
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        configId: SessionConfigId,
        name: String,
        description: String? = nil,
        category: V2SessionConfigOptionCategory? = nil,
        kind: V2SessionConfigKind,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.configId = configId
        self.name = name
        self.description = description
        self.category = category
        self.kind = kind
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type, configId, name, description, category, _meta // swiftlint:disable:this identifier_name
        case currentValue, options
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeStr = try container.decode(String.self, forKey: .type)
        self.configId = try container.decode(SessionConfigId.self, forKey: .configId)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.category = try container.decodeIfPresent(V2SessionConfigOptionCategory.self, forKey: .category)
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
        switch typeStr {
        case "select":
            let currentValue = try container.decode(SessionConfigValueId.self, forKey: .currentValue)
            let options = try container.decode(V2SessionConfigSelectOptions.self, forKey: .options)
            self.kind = .select(currentValue: currentValue, options: options)
        case "boolean":
            let currentValue = try container.decode(Bool.self, forKey: .currentValue)
            self.kind = .boolean(currentValue: currentValue)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            let optionKeys: Set<String> = ["type", "configId", "name", "description", "category", "_meta"]
            let fields = raw.filter { !optionKeys.contains($0.key) }
            self.kind = .unknown(type: typeStr, fields: fields)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch kind {
        case .select(let currentValue, let options):
            try container.encode("select", forKey: .type)
            try container.encode(currentValue, forKey: .currentValue)
            try container.encode(options, forKey: .options)
        case .boolean(let currentValue):
            try container.encode("boolean", forKey: .type)
            try container.encode(currentValue, forKey: .currentValue)
        case .unknown(let type, _):
            try container.encode(type, forKey: .type)
        }
        try container.encode(configId, forKey: .configId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

// MARK: - V2SessionConfigOptionValue

/// **UNSTABLE** - The value of a session configuration option (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2SessionConfigOptionValue: Codable, Sendable, Hashable {
    case id(SessionConfigValueId)
    case boolean(Bool)
    case unknown(type: String, rawJson: [String: JsonValue])

    private enum TypeKey: String, CodingKey { case type }
    private enum IdKeys: String, CodingKey { case type, value }
    private enum BooleanKeys: String, CodingKey { case type, value }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "id":
            let c = try decoder.container(keyedBy: IdKeys.self)
            let value = try c.decode(SessionConfigValueId.self, forKey: .value)
            self = .id(value)
        case "boolean":
            let c = try decoder.container(keyedBy: BooleanKeys.self)
            let value = try c.decode(Bool.self, forKey: .value)
            self = .boolean(value)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .id(let value):
            var c = encoder.container(keyedBy: IdKeys.self)
            try c.encode("id", forKey: .type)
            try c.encode(value, forKey: .value)
        case .boolean(let value):
            var c = encoder.container(keyedBy: BooleanKeys.self)
            try c.encode("boolean", forKey: .type)
            try c.encode(value, forKey: .value)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}
