import Foundation

// MARK: - SessionConfigOptionCategory

/// Category for a session configuration option.
///
/// Well-known categories are provided as constants. Custom categories are supported
/// via the constructor, matching the protocol's open string-based design.
public struct SessionConfigOptionCategory: Codable, Sendable, Hashable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let mode = SessionConfigOptionCategory(rawValue: "mode")
    public static let model = SessionConfigOptionCategory(rawValue: "model")
    public static let thoughtLevel = SessionConfigOptionCategory(rawValue: "thought_level")

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension SessionConfigOptionCategory: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension SessionConfigOptionCategory: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - Session Config Select Option

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// A single option for a session configuration select.
public struct SessionConfigSelectOption: Codable, Sendable, Hashable {
    /// The value identifier for this option
    public let value: SessionConfigValueId

    /// Display name for the option
    public let name: String

    /// Optional description of what this option does
    public let description: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a session config select option.
    ///
    /// - Parameters:
    ///   - value: The value identifier
    ///   - name: Display name
    ///   - description: Optional description
    ///   - _meta: Optional metadata
    public init(
        value: SessionConfigValueId,
        name: String,
        description: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.value = value
        self.name = name
        self.description = description
        self._meta = _meta
    }
}

// MARK: - Session Config Select Group

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// A group of options for a session configuration select.
public struct SessionConfigSelectGroup: Codable, Sendable, Hashable {
    /// The group identifier
    public let group: SessionConfigGroupId

    /// Display name for the group
    public let name: String?

    /// Options within this group
    public let options: [SessionConfigSelectOption]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a session config select group.
    ///
    /// - Parameters:
    ///   - group: The group identifier
    ///   - name: Optional display name
    ///   - options: Options in this group
    ///   - _meta: Optional metadata
    public init(
        group: SessionConfigGroupId,
        name: String? = nil,
        options: [SessionConfigSelectOption],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.group = group
        self.name = name
        self.options = options
        self._meta = _meta
    }
}

// MARK: - Session Config Select Options

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Options for a session configuration select, either as a flat list or grouped.
///
/// The serialization format is determined by the content:
/// - Flat: `[{value, name, ...}, ...]`
/// - Grouped: `[{group, name, options: [...]}, ...]`
public enum SessionConfigSelectOptions: Sendable, Hashable {
    /// A flat list of options
    case flat([SessionConfigSelectOption])

    /// Options organized into groups
    case grouped([SessionConfigSelectGroup])
}

// MARK: - Codable

extension SessionConfigSelectOptions: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as array and inspect first element
        // If first element has "group" key, it's grouped; otherwise flat
        let jsonArray = try container.decode([JsonValue].self)

        if jsonArray.isEmpty {
            self = .flat([])
            return
        }

        // Check if first element has a "group" key
        if case .object(let dict) = jsonArray[0], dict["group"] != nil {
            // Re-decode as grouped
            let data = try JSONEncoder().encode(jsonArray)
            let groups = try JSONDecoder().decode([SessionConfigSelectGroup].self, from: data)
            self = .grouped(groups)
        } else {
            // Re-decode as flat
            let data = try JSONEncoder().encode(jsonArray)
            let options = try JSONDecoder().decode([SessionConfigSelectOption].self, from: data)
            self = .flat(options)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .flat(let options):
            try container.encode(options)
        case .grouped(let groups):
            try container.encode(groups)
        }
    }
}

// MARK: - Session Config Option Value

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Represents a value that can be either a string (for select options) or a boolean (for boolean options).
public enum SessionConfigOptionValue: Sendable, Hashable {
    /// A string value, used for select-type configuration options
    case string(String)

    /// A boolean value, used for boolean-type configuration options
    case bool(Bool)

    /// An unknown value type for forward compatibility
    case unknown(JsonValue)
}

extension SessionConfigOptionValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            let raw = try container.decode(JsonValue.self)
            self = .unknown(raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .unknown(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Session Config Option

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Configuration option types for sessions.
public enum SessionConfigOption: Sendable, Hashable {
    /// A select-type configuration option
    case select(SessionConfigOptionSelect)

    /// A boolean-type configuration option
    case boolean(SessionConfigOptionBoolean)
}

/// Data for a boolean-type configuration option.
public struct SessionConfigOptionBoolean: Codable, Sendable, Hashable {
    /// The configuration option identifier
    public let id: SessionConfigId

    /// Display name for the option
    public let name: String

    /// Optional description
    public let description: String?

    /// Optional category for grouping
    public let category: SessionConfigOptionCategory?

    /// The current boolean value
    public let currentValue: Bool

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: SessionConfigId,
        name: String,
        description: String? = nil,
        category: SessionConfigOptionCategory? = nil,
        currentValue: Bool,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.currentValue = currentValue
        self._meta = _meta
    }
}

/// Data for a select-type configuration option.
public struct SessionConfigOptionSelect: Codable, Sendable, Hashable {
    /// The configuration option identifier
    public let id: SessionConfigId

    /// Display name for the option
    public let name: String

    /// Optional description
    public let description: String?

    /// Optional category for grouping
    public let category: SessionConfigOptionCategory?

    /// The currently selected value
    public let currentValue: SessionConfigValueId

    /// Available options to select from
    public let options: SessionConfigSelectOptions

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a select configuration option.
    ///
    /// - Parameters:
    ///   - id: The configuration option identifier
    ///   - name: Display name
    ///   - description: Optional description
    ///   - category: Optional category
    ///   - currentValue: Currently selected value
    ///   - options: Available options
    ///   - _meta: Optional metadata
    public init(
        id: SessionConfigId,
        name: String,
        description: String? = nil,
        category: SessionConfigOptionCategory? = nil,
        currentValue: SessionConfigValueId,
        options: SessionConfigSelectOptions,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.currentValue = currentValue
        self.options = options
        self._meta = _meta
    }
}

// MARK: - Codable

extension SessionConfigOption: Codable {
    private enum CodingKeys: String, CodingKey {
        case type = "type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)

        switch typeString {
        case "select":
            self = .select(try SessionConfigOptionSelect(from: decoder))
        case "boolean":
            self = .boolean(try SessionConfigOptionBoolean(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown SessionConfigOption type: \(typeString)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .select(let data):
            try container.encode("select", forKey: .type)
            try data.encode(to: encoder)
        case .boolean(let data):
            try container.encode("boolean", forKey: .type)
            try data.encode(to: encoder)
        }
    }
}
