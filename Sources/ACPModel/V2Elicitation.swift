import Foundation

// MARK: - V2StringFormat

/// **UNSTABLE** - String format types for string properties in v2 elicitation schemas.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2StringFormat: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let email = V2StringFormat(rawValue: "email")
    public static let uri = V2StringFormat(rawValue: "uri")
    public static let date = V2StringFormat(rawValue: "date")
    public static let dateTime = V2StringFormat(rawValue: "date-time")
}

// MARK: - V2MultiSelectItems

/// **UNSTABLE** - Items for a multi-select array property in a v2 elicitation schema.
///
/// Discriminated by shape: `type: "string"` → `stringItems`, `anyOf` key → `titled`.
public enum V2MultiSelectItems: Codable, Sendable, Hashable {
    case stringItems([String])
    case titled([EnumOption])
    case unknown(type: String, rawJson: [String: JsonValue])

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        if case .string(let typeStr) = raw["type"] {
            if typeStr == "string" {
                let items: [String]
                if case .array(let arr) = raw["enum"] {
                    items = arr.compactMap { if case .string(let s) = $0 { return s } else { return nil } }
                } else {
                    items = []
                }
                self = .stringItems(items)
                return
            } else {
                self = .unknown(type: typeStr, rawJson: raw)
                return
            }
        }
        if raw["anyOf"] != nil {
            let data = try? JSONEncoder().encode(JsonValue.object(raw))
            let container = data.flatMap { try? JSONDecoder().decode(TitledContainer.self, from: $0) }
            if let options = container?.anyOf {
                self = .titled(options)
                return
            }
        }
        throw DecodingError.dataCorruptedError(
            in: try decoder.singleValueContainer(),
            debugDescription: "Cannot determine V2MultiSelectItems shape; expected 'type' or 'anyOf'"
        )
    }

    private struct TitledContainer: Codable {
        let anyOf: [EnumOption]
    }

    private struct StringItemsContainer: Codable {
        let `enum`: [String]
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .stringItems(let values):
            var c = encoder.container(keyedBy: StringItemsCodingKeys.self)
            try c.encode("string", forKey: .type)
            try c.encode(values, forKey: .enum)
        case .titled(let options):
            var c = encoder.container(keyedBy: TitledCodingKeys.self)
            try c.encode(options, forKey: .anyOf)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }

    private enum StringItemsCodingKeys: String, CodingKey { case type, `enum` }
    private enum TitledCodingKeys: String, CodingKey { case anyOf }
}

// MARK: - V2ElicitationPropertySchema

/// **UNSTABLE** - Property schema for elicitation form fields (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2ElicitationPropertySchema: Codable, Sendable, Hashable {
    case stringProperty(StringProperty)
    case numberProperty(NumberProperty)
    case integerProperty(IntegerProperty)
    case booleanProperty(BooleanProperty)
    case arrayProperty(ArrayProperty)
    case unknown(type: String, rawJson: [String: JsonValue])

    public struct StringProperty: Codable, Sendable, Hashable {
        public let title: String?
        public let description: String?
        public let minLength: Int?
        public let maxLength: Int?
        public let pattern: String?
        public let format: V2StringFormat?
        public let `default`: String?
        public let enumValues: [String]?
        public let oneOf: [EnumOption]?

        public init(
            title: String? = nil,
            description: String? = nil,
            minLength: Int? = nil,
            maxLength: Int? = nil,
            pattern: String? = nil,
            format: V2StringFormat? = nil,
            default: String? = nil,
            enumValues: [String]? = nil,
            oneOf: [EnumOption]? = nil
        ) {
            self.title = title
            self.description = description
            self.minLength = minLength
            self.maxLength = maxLength
            self.pattern = pattern
            self.format = format
            self.default = `default`
            self.enumValues = enumValues
            self.oneOf = oneOf
        }

        private enum CodingKeys: String, CodingKey {
            case title, description, minLength, maxLength, pattern, format
            case `default`
            case enumValues = "enum"
            case oneOf
        }
    }

    public struct NumberProperty: Codable, Sendable, Hashable {
        public let title: String?
        public let description: String?
        public let minimum: Double?
        public let maximum: Double?
        public let `default`: Double?

        public init(
            title: String? = nil,
            description: String? = nil,
            minimum: Double? = nil,
            maximum: Double? = nil,
            default: Double? = nil
        ) {
            self.title = title
            self.description = description
            self.minimum = minimum
            self.maximum = maximum
            self.default = `default`
        }
    }

    public struct IntegerProperty: Codable, Sendable, Hashable {
        public let title: String?
        public let description: String?
        public let minimum: Int64?
        public let maximum: Int64?
        public let `default`: Int64?

        public init(
            title: String? = nil,
            description: String? = nil,
            minimum: Int64? = nil,
            maximum: Int64? = nil,
            default: Int64? = nil
        ) {
            self.title = title
            self.description = description
            self.minimum = minimum
            self.maximum = maximum
            self.default = `default`
        }
    }

    public struct BooleanProperty: Codable, Sendable, Hashable {
        public let title: String?
        public let description: String?
        public let `default`: Bool?

        public init(title: String? = nil, description: String? = nil, default: Bool? = nil) {
            self.title = title
            self.description = description
            self.default = `default`
        }
    }

    public struct ArrayProperty: Codable, Sendable, Hashable {
        public let title: String?
        public let description: String?
        public let minItems: Int64?
        public let maxItems: Int64?
        public let items: V2MultiSelectItems
        public let `default`: [String]?

        public init(
            title: String? = nil,
            description: String? = nil,
            minItems: Int64? = nil,
            maxItems: Int64? = nil,
            items: V2MultiSelectItems,
            default: [String]? = nil
        ) {
            self.title = title
            self.description = description
            self.minItems = minItems
            self.maxItems = maxItems
            self.items = items
            self.default = `default`
        }
    }

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "string":
            self = .stringProperty(try StringProperty(from: decoder))
        case "number":
            self = .numberProperty(try NumberProperty(from: decoder))
        case "integer":
            self = .integerProperty(try IntegerProperty(from: decoder))
        case "boolean":
            self = .booleanProperty(try BooleanProperty(from: decoder))
        case "array":
            self = .arrayProperty(try ArrayProperty(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .stringProperty(let v):
            try typeContainer.encode("string", forKey: .type)
            try v.encode(to: encoder)
        case .numberProperty(let v):
            try typeContainer.encode("number", forKey: .type)
            try v.encode(to: encoder)
        case .integerProperty(let v):
            try typeContainer.encode("integer", forKey: .type)
            try v.encode(to: encoder)
        case .booleanProperty(let v):
            try typeContainer.encode("boolean", forKey: .type)
            try v.encode(to: encoder)
        case .arrayProperty(let v):
            try typeContainer.encode("array", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2ElicitationSchema

/// **UNSTABLE** - Type-safe elicitation schema for requesting structured user input (v2).
public struct V2ElicitationSchema: Codable, Sendable, Hashable {
    public let title: String?
    public let properties: [String: V2ElicitationPropertySchema]
    public let required: [String]?
    public let description: String?

    public init(
        title: String? = nil,
        properties: [String: V2ElicitationPropertySchema] = [:],
        required: [String]? = nil,
        description: String? = nil
    ) {
        self.title = title
        self.properties = properties
        self.required = required
        self.description = description
    }

    private enum CodingKeys: String, CodingKey {
        case type, title, properties, required, description
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try c.decodeIfPresent(String.self, forKey: .title)
        self.properties = try c.decodeIfPresent([String: V2ElicitationPropertySchema].self, forKey: .properties) ?? [:]
        self.required = try c.decodeIfPresent([String].self, forKey: .required)
        self.description = try c.decodeIfPresent(String.self, forKey: .description)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("object", forKey: .type)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encode(properties, forKey: .properties)
        try c.encodeIfPresent(required, forKey: .required)
        try c.encodeIfPresent(description, forKey: .description)
    }
}

// MARK: - V2ElicitationAction

/// **UNSTABLE** - The user's action in response to a v2 elicitation.
///
/// Open tagged union discriminated by `action`. Unknown types preserve the raw JSON.
public enum V2ElicitationAction: Codable, Sendable, Hashable {
    case accept(content: [String: ElicitationContentValue]?)
    case decline
    case cancel
    case unknown(action: String, rawJson: [String: JsonValue])

    private enum ActionKey: String, CodingKey { case action }
    private enum AcceptKeys: String, CodingKey { case action, content }

    public init(from decoder: Decoder) throws {
        let actionContainer = try decoder.container(keyedBy: ActionKey.self)
        let actionStr = try actionContainer.decode(String.self, forKey: .action)
        switch actionStr {
        case "accept":
            let c = try decoder.container(keyedBy: AcceptKeys.self)
            let content = try c.decodeIfPresent([String: ElicitationContentValue].self, forKey: .content)
            self = .accept(content: content)
        case "decline":
            self = .decline
        case "cancel":
            self = .cancel
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(action: actionStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .accept(let content):
            var c = encoder.container(keyedBy: AcceptKeys.self)
            try c.encode("accept", forKey: .action)
            try c.encodeIfPresent(content, forKey: .content)
        case .decline:
            var c = encoder.container(keyedBy: ActionKey.self)
            try c.encode("decline", forKey: .action)
        case .cancel:
            var c = encoder.container(keyedBy: ActionKey.self)
            try c.encode("cancel", forKey: .action)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2ElicitationMode

/// **UNSTABLE** - The mode of elicitation for v2, determining how user input is collected.
///
/// Unlike the v1 mode, every v2 mode carries its scope (flattened on the wire beside `mode`).
///
/// Open tagged union discriminated by `mode`. Unknown types preserve the raw JSON.
public enum V2ElicitationMode: Codable, Sendable, Hashable {
    case form(scope: ElicitationScope, requestedSchema: V2ElicitationSchema)
    case url(scope: ElicitationScope, elicitationId: ElicitationId, url: String)
    case unknown(mode: String, scope: ElicitationScope, rawJson: [String: JsonValue])

    public var scope: ElicitationScope {
        switch self {
        case .form(let scope, _): return scope
        case .url(let scope, _, _): return scope
        case .unknown(_, let scope, _): return scope
        }
    }

    private struct FlatKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: FlatKey.self)
        guard let modeStr = try? c.decode(String.self, forKey: FlatKey(stringValue: "mode")) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'mode' discriminator in V2ElicitationMode"
            )
        }
        let scope = try ElicitationScope(from: decoder)
        switch modeStr {
        case "form":
            let schema = try c.decode(V2ElicitationSchema.self, forKey: FlatKey(stringValue: "requestedSchema"))
            self = .form(scope: scope, requestedSchema: schema)
        case "url":
            let elicitationId = try c.decode(ElicitationId.self, forKey: FlatKey(stringValue: "elicitationId"))
            let url = try c.decode(String.self, forKey: FlatKey(stringValue: "url"))
            self = .url(scope: scope, elicitationId: elicitationId, url: url)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(mode: modeStr, scope: scope, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if case .unknown(_, _, let raw) = self {
            var c = encoder.singleValueContainer()
            try c.encode(raw)
            return
        }
        var c = encoder.container(keyedBy: FlatKey.self)
        // Encode scope fields (flat)
        switch scope {
        case .session(let sessionId, let toolCallId):
            try c.encode(sessionId, forKey: FlatKey(stringValue: "sessionId"))
            if let toolCallId = toolCallId {
                try c.encode(toolCallId, forKey: FlatKey(stringValue: "toolCallId"))
            }
        case .request(let requestId):
            try c.encode(requestId, forKey: FlatKey(stringValue: "requestId"))
        }
        // Encode mode discriminator and mode-specific fields
        switch self {
        case .form(_, let schema):
            try c.encode("form", forKey: FlatKey(stringValue: "mode"))
            try c.encode(schema, forKey: FlatKey(stringValue: "requestedSchema"))
        case .url(_, let elicitationId, let url):
            try c.encode("url", forKey: FlatKey(stringValue: "mode"))
            try c.encode(elicitationId, forKey: FlatKey(stringValue: "elicitationId"))
            try c.encode(url, forKey: FlatKey(stringValue: "url"))
        case .unknown: break // handled above
        }
    }
}
