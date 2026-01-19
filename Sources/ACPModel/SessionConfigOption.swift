import Foundation

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
    public let name: String

    /// Options within this group
    public let options: [SessionConfigSelectOption]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a session config select group.
    ///
    /// - Parameters:
    ///   - group: The group identifier
    ///   - name: Display name
    ///   - options: Options in this group
    ///   - _meta: Optional metadata
    public init(
        group: SessionConfigGroupId,
        name: String,
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

// MARK: - Session Config Option

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Configuration option types for sessions.
///
/// Currently only supports select-type options with discriminator-based serialization.
public enum SessionConfigOption: Sendable, Hashable {
    /// A select-type configuration option
    case select(SessionConfigOptionSelect)
}

/// Data for a select-type configuration option.
public struct SessionConfigOptionSelect: Codable, Sendable, Hashable {
    /// The configuration option identifier
    public let id: SessionConfigId

    /// Display name for the option
    public let name: String

    /// Optional description
    public let description: String?

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
    ///   - currentValue: Currently selected value
    ///   - options: Available options
    ///   - _meta: Optional metadata
    public init(
        id: SessionConfigId,
        name: String,
        description: String? = nil,
        currentValue: SessionConfigValueId,
        options: SessionConfigSelectOptions,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
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

    private enum TypeValue: String, Codable {
        case select = "select"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(TypeValue.self, forKey: .type)

        switch type {
        case .select:
            let data = try SessionConfigOptionSelect(from: decoder)
            self = .select(data)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .select(let data):
            try container.encode(TypeValue.select, forKey: .type)
            try data.encode(to: encoder)
        }
    }
}
