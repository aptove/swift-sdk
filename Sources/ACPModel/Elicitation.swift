import Foundation

// MARK: - Error Code

/// Error code for URL elicitation required errors.
public let urlElicitationRequiredErrorCode: Int = -32042

// MARK: - ElicitationId

/// **UNSTABLE** - Unique identifier for an elicitation.
public struct ElicitationId: Codable, Sendable, Hashable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ElicitationId: CustomStringConvertible {
    public var description: String { rawValue }
}

extension ElicitationId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

// MARK: - Enums

/// String format types for string properties in elicitation schemas.
public enum StringFormat: String, Codable, Sendable, Hashable {
    case email
    case uri
    case date
    case dateTime = "date-time"
}

/// Type discriminator for URL-only elicitation error items.
public enum ElicitationUrlOnlyMode: String, Codable, Sendable, Hashable {
    case url
}

// MARK: - EnumOption

/// A titled enum option with a const value and human-readable title.
public struct EnumOption: Codable, Sendable, Hashable {
    /// The const value
    public let value: String

    /// Human-readable title
    public let title: String

    public init(value: String, title: String) {
        self.value = value
        self.title = title
    }

    private enum CodingKeys: String, CodingKey {
        case value = "const"
        case title
    }
}

// MARK: - Property Schemas

/// Schema for string properties in an elicitation form.
public struct StringPropertySchema: Codable, Sendable, Hashable {
    public let title: String?
    public let description: String?
    public let minLength: Int?
    public let maxLength: Int?
    public let pattern: String?
    public let format: StringFormat?
    public let `default`: String?
    public let enumValues: [String]?
    public let oneOf: [EnumOption]?

    public init(
        title: String? = nil,
        description: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        format: StringFormat? = nil,
        default defaultValue: String? = nil,
        enumValues: [String]? = nil,
        oneOf: [EnumOption]? = nil
    ) {
        self.title = title
        self.description = description
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.format = format
        self.default = defaultValue
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

/// Schema for number (floating-point) properties in an elicitation form.
public struct NumberPropertySchema: Codable, Sendable, Hashable {
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
        default defaultValue: Double? = nil
    ) {
        self.title = title
        self.description = description
        self.minimum = minimum
        self.maximum = maximum
        self.default = defaultValue
    }

    private enum CodingKeys: String, CodingKey {
        case title, description, minimum, maximum, `default`
    }
}

/// Schema for integer properties in an elicitation form.
public struct IntegerPropertySchema: Codable, Sendable, Hashable {
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
        default defaultValue: Int64? = nil
    ) {
        self.title = title
        self.description = description
        self.minimum = minimum
        self.maximum = maximum
        self.default = defaultValue
    }

    private enum CodingKeys: String, CodingKey {
        case title, description, minimum, maximum, `default`
    }
}

/// Schema for boolean properties in an elicitation form.
public struct BooleanPropertySchema: Codable, Sendable, Hashable {
    public let title: String?
    public let description: String?
    public let `default`: Bool?

    public init(
        title: String? = nil,
        description: String? = nil,
        default defaultValue: Bool? = nil
    ) {
        self.title = title
        self.description = description
        self.default = defaultValue
    }

    private enum CodingKeys: String, CodingKey {
        case title, description, `default`
    }
}

// MARK: - Multi-Select Items

/// Items definition for untitled multi-select enum properties.
public struct UntitledMultiSelectItems: Codable, Sendable, Hashable {
    public let values: [String]

    public init(values: [String]) {
        self.values = values
    }

    private enum CodingKeys: String, CodingKey {
        case values = "enum"
    }
}

/// Items definition for titled multi-select enum properties.
public struct TitledMultiSelectItems: Codable, Sendable, Hashable {
    public let options: [EnumOption]

    public init(options: [EnumOption]) {
        self.options = options
    }

    private enum CodingKeys: String, CodingKey {
        case options = "anyOf"
    }
}

/// Items for a multi-select (array) property schema.
///
/// Discriminated by field presence: `anyOf` → Titled, `enum` → Untitled.
public enum MultiSelectItems: Codable, Sendable, Hashable {
    case untitled(UntitledMultiSelectItems)
    case titled(TitledMultiSelectItems)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        if container.allKeys.contains(where: { $0.stringValue == "anyOf" }) {
            self = .titled(try TitledMultiSelectItems(from: decoder))
        } else {
            self = .untitled(try UntitledMultiSelectItems(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .untitled(let items): try items.encode(to: encoder)
        case .titled(let items): try items.encode(to: encoder)
        }
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { self.stringValue = "\(intValue)"; self.intValue = intValue }
    }
}

/// Schema for multi-select (array) properties in an elicitation form.
public struct MultiSelectPropertySchema: Codable, Sendable, Hashable {
    public let title: String?
    public let description: String?
    public let minItems: Int64?
    public let maxItems: Int64?
    public let items: MultiSelectItems
    public let `default`: [String]?

    public init(
        title: String? = nil,
        description: String? = nil,
        minItems: Int64? = nil,
        maxItems: Int64? = nil,
        items: MultiSelectItems,
        default defaultValue: [String]? = nil
    ) {
        self.title = title
        self.description = description
        self.minItems = minItems
        self.maxItems = maxItems
        self.items = items
        self.default = defaultValue
    }

    private enum CodingKeys: String, CodingKey {
        case title, description, minItems, maxItems, items, `default`
    }
}

// MARK: - ElicitationPropertySchema

/// Property schema for elicitation form fields.
///
/// Each variant corresponds to a JSON Schema "type" value.
public enum ElicitationPropertySchema: Codable, Sendable, Hashable {
    case string(StringPropertySchema)
    case number(NumberPropertySchema)
    case integer(IntegerPropertySchema)
    case boolean(BooleanPropertySchema)
    case array(MultiSelectPropertySchema)
    case unknown(JsonValue)

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decodeIfPresent(String.self, forKey: .type) ?? ""
        switch typeStr {
        case "string":
            self = .string(try StringPropertySchema(from: decoder))
        case "number":
            self = .number(try NumberPropertySchema(from: decoder))
        case "integer":
            self = .integer(try IntegerPropertySchema(from: decoder))
        case "boolean":
            self = .boolean(try BooleanPropertySchema(from: decoder))
        case "array":
            self = .array(try MultiSelectPropertySchema(from: decoder))
        default:
            let value = try decoder.singleValueContainer().decode(JsonValue.self)
            self = .unknown(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .string(let schema):
            try typeContainer.encode("string", forKey: .type)
            try schema.encode(to: encoder)
        case .number(let schema):
            try typeContainer.encode("number", forKey: .type)
            try schema.encode(to: encoder)
        case .integer(let schema):
            try typeContainer.encode("integer", forKey: .type)
            try schema.encode(to: encoder)
        case .boolean(let schema):
            try typeContainer.encode("boolean", forKey: .type)
            try schema.encode(to: encoder)
        case .array(let schema):
            try typeContainer.encode("array", forKey: .type)
            try schema.encode(to: encoder)
        case .unknown(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
}

// MARK: - ElicitationSchema

/// Type-safe elicitation schema for requesting structured user input.
public struct ElicitationSchema: Codable, Sendable, Hashable {
    public let title: String?
    public let properties: [String: ElicitationPropertySchema]
    public let required: [String]?
    public let description: String?

    public init(
        title: String? = nil,
        properties: [String: ElicitationPropertySchema] = [:],
        required: [String]? = nil,
        description: String? = nil
    ) {
        self.title = title
        self.properties = properties
        self.required = required
        self.description = description
    }

    private enum CodingKeys: String, CodingKey {
        case title, properties, required, description
        case type // consumed but not stored
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.properties = try container.decodeIfPresent([String: ElicitationPropertySchema].self, forKey: .properties) ?? [:]
        self.required = try container.decodeIfPresent([String].self, forKey: .required)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("object", forKey: .type)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(properties, forKey: .properties)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(description, forKey: .description)
    }
}

// MARK: - ElicitationScope

/// The scope of an elicitation request, determining what context it's tied to.
public enum ElicitationScope: Codable, Sendable, Hashable {
    case session(sessionId: SessionId, toolCallId: ToolCallId?)
    case request(requestId: RequestId)

    private enum CodingKeys: String, CodingKey {
        case sessionId, toolCallId, requestId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.sessionId) {
            let sessionId = try container.decode(SessionId.self, forKey: .sessionId)
            let toolCallId = try container.decodeIfPresent(ToolCallId.self, forKey: .toolCallId)
            self = .session(sessionId: sessionId, toolCallId: toolCallId)
        } else if container.contains(.requestId) {
            let requestId = try container.decode(RequestId.self, forKey: .requestId)
            self = .request(requestId: requestId)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .sessionId, in: container,
                debugDescription: "ElicitationScope must have either 'sessionId' or 'requestId'")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .session(let sessionId, let toolCallId):
            try container.encode(sessionId, forKey: .sessionId)
            try container.encodeIfPresent(toolCallId, forKey: .toolCallId)
        case .request(let requestId):
            try container.encode(requestId, forKey: .requestId)
        }
    }
}

// MARK: - ElicitationMode

/// The mode of elicitation, determining how user input is collected.
public enum ElicitationMode: Codable, Sendable, Hashable {
    case form(requestedSchema: ElicitationSchema)
    case url(elicitationId: ElicitationId, url: String)

    private enum CodingKeys: String, CodingKey {
        case mode, requestedSchema, elicitationId, url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modeStr = try container.decode(String.self, forKey: .mode)
        switch modeStr {
        case "form":
            let schema = try container.decode(ElicitationSchema.self, forKey: .requestedSchema)
            self = .form(requestedSchema: schema)
        case "url":
            let id = try container.decode(ElicitationId.self, forKey: .elicitationId)
            let url = try container.decode(String.self, forKey: .url)
            self = .url(elicitationId: id, url: url)
        default:
            throw DecodingError.dataCorruptedError(forKey: .mode, in: container,
                debugDescription: "Unknown elicitation mode: \(modeStr)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .form(let schema):
            try container.encode("form", forKey: .mode)
            try container.encode(schema, forKey: .requestedSchema)
        case .url(let id, let url):
            try container.encode("url", forKey: .mode)
            try container.encode(id, forKey: .elicitationId)
            try container.encode(url, forKey: .url)
        }
    }
}

// MARK: - CreateElicitationRequest

/// **UNSTABLE** - Request from the agent to elicit structured user input.
///
/// The scope and mode fields are flattened into the top-level JSON object.
public struct CreateElicitationRequest: AcpRequest, Sendable, Hashable {
    /// The scope determining what context this elicitation is tied to
    public let scope: ElicitationScope

    /// The mode determining how user input is collected
    public let mode: ElicitationMode

    /// Message to show to the user
    public let message: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        scope: ElicitationScope,
        mode: ElicitationMode,
        message: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.scope = scope
        self.mode = mode
        self.message = message
        self._meta = _meta
    }
}

extension CreateElicitationRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case sessionId, toolCallId, requestId  // scope fields
        case mode, requestedSchema, elicitationId, url  // mode fields
        case message, _meta
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode scope
        if container.contains(.sessionId) {
            let sessionId = try container.decode(SessionId.self, forKey: .sessionId)
            let toolCallId = try container.decodeIfPresent(ToolCallId.self, forKey: .toolCallId)
            self.scope = .session(sessionId: sessionId, toolCallId: toolCallId)
        } else if container.contains(.requestId) {
            let requestId = try container.decode(RequestId.self, forKey: .requestId)
            self.scope = .request(requestId: requestId)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .sessionId, in: container,
                debugDescription: "CreateElicitationRequest must have either 'sessionId' or 'requestId'")
        }

        // Decode mode
        let modeStr = try container.decode(String.self, forKey: .mode)
        switch modeStr {
        case "form":
            let schema = try container.decode(ElicitationSchema.self, forKey: .requestedSchema)
            self.mode = .form(requestedSchema: schema)
        case "url":
            let id = try container.decode(ElicitationId.self, forKey: .elicitationId)
            let url = try container.decode(String.self, forKey: .url)
            self.mode = .url(elicitationId: id, url: url)
        default:
            throw DecodingError.dataCorruptedError(forKey: .mode, in: container,
                debugDescription: "Unknown elicitation mode: \(modeStr)")
        }

        self.message = try container.decode(String.self, forKey: .message)
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Flatten scope
        switch scope {
        case .session(let sessionId, let toolCallId):
            try container.encode(sessionId, forKey: .sessionId)
            try container.encodeIfPresent(toolCallId, forKey: .toolCallId)
        case .request(let requestId):
            try container.encode(requestId, forKey: .requestId)
        }

        // Flatten mode
        switch mode {
        case .form(let schema):
            try container.encode("form", forKey: .mode)
            try container.encode(schema, forKey: .requestedSchema)
        case .url(let id, let url):
            try container.encode("url", forKey: .mode)
            try container.encode(id, forKey: .elicitationId)
            try container.encode(url, forKey: .url)
        }

        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

// MARK: - ElicitationContentValue

/// **UNSTABLE** - A value in elicitation response content.
///
/// Can be string, integer, number, boolean, or string array.
public enum ElicitationContentValue: Codable, Sendable, Hashable {
    case string(String)
    case integer(Int64)
    case number(Double)
    case boolean(Bool)
    case stringArray([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self = .boolean(boolVal)
        } else if let intVal = try? container.decode(Int64.self) {
            self = .integer(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .number(doubleVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else if let arrVal = try? container.decode([String].self) {
            self = .stringArray(arrVal)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "ElicitationContentValue: unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .integer(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .boolean(let v): try container.encode(v)
        case .stringArray(let v): try container.encode(v)
        }
    }
}

// MARK: - ElicitationAction

/// **UNSTABLE** - The user's action in response to an elicitation.
public enum ElicitationAction: Codable, Sendable, Hashable {
    case accept(content: [String: ElicitationContentValue]?)
    case decline
    case cancel

    private enum CodingKeys: String, CodingKey {
        case action, content
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decode(String.self, forKey: .action)
        switch action {
        case "accept":
            let content = try container.decodeIfPresent([String: ElicitationContentValue].self, forKey: .content)
            self = .accept(content: content)
        case "decline":
            self = .decline
        case "cancel":
            self = .cancel
        default:
            throw DecodingError.dataCorruptedError(forKey: .action, in: container,
                debugDescription: "Unknown elicitation action: \(action)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .accept(let content):
            try container.encode("accept", forKey: .action)
            try container.encodeIfPresent(content, forKey: .content)
        case .decline:
            try container.encode("decline", forKey: .action)
        case .cancel:
            try container.encode("cancel", forKey: .action)
        }
    }
}

// MARK: - CreateElicitationResponse

/// **UNSTABLE** - Response from the client to an elicitation request.
///
/// The action fields are flattened into the top-level JSON object.
public struct CreateElicitationResponse: AcpResponse, Sendable, Hashable {
    /// The user's action
    public let action: ElicitationAction

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        action: ElicitationAction,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.action = action
        self._meta = _meta
    }
}

extension CreateElicitationResponse: Codable {
    private enum CodingKeys: String, CodingKey {
        case action, content, _meta
    }

    public init(from decoder: Decoder) throws {
        self.action = try ElicitationAction(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        try action.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

// MARK: - CompleteElicitationNotification

/// **UNSTABLE** - Notification sent by the agent when a URL-based elicitation is complete.
public struct CompleteElicitationNotification: AcpNotification, Codable, Sendable, Hashable {
    /// The elicitation ID being completed
    public let elicitationId: ElicitationId

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        elicitationId: ElicitationId,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.elicitationId = elicitationId
        self._meta = _meta
    }
}

// MARK: - Elicitation Capabilities

/// **UNSTABLE** - Elicitation capabilities supported by the client.
public struct ElicitationCapabilities: Codable, Sendable, Hashable {
    /// Form-based elicitation capability
    public let form: ElicitationFormCapabilities?

    /// URL-based elicitation capability
    public let url: ElicitationUrlCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        form: ElicitationFormCapabilities? = nil,
        url: ElicitationUrlCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.form = form
        self.url = url
        self._meta = _meta
    }

    /// Whether form-based elicitation is supported.
    ///
    /// Returns true when `form` is explicitly set, or when neither mode is declared
    /// (i.e., the capability object is empty, implying form-only support).
    public var supportsForm: Bool { form != nil || (form == nil && url == nil) }

    /// Whether URL-based elicitation is supported.
    public var supportsUrl: Bool { url != nil }
}

/// **UNSTABLE** - Form-based elicitation capabilities.
public struct ElicitationFormCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE** - URL-based elicitation capabilities.
public struct ElicitationUrlCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - URL Elicitation Required Error Data

/// **UNSTABLE** - Data payload for the UrlElicitationRequired error.
public struct UrlElicitationRequiredData: Codable, Sendable, Hashable {
    public let elicitations: [UrlElicitationRequiredItem]

    public init(elicitations: [UrlElicitationRequiredItem]) {
        self.elicitations = elicitations
    }
}

/// **UNSTABLE** - A single URL elicitation item within the UrlElicitationRequired error data.
public struct UrlElicitationRequiredItem: Codable, Sendable, Hashable {
    public let mode: ElicitationUrlOnlyMode
    public let elicitationId: ElicitationId
    public let url: String
    public let message: String

    public init(
        elicitationId: ElicitationId,
        url: String,
        message: String
    ) {
        self.mode = .url
        self.elicitationId = elicitationId
        self.url = url
        self.message = message
    }
}
