import Foundation

// MARK: - V2PlanEntryPriority

/// **UNSTABLE** - Priority levels for plan entries.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2PlanEntryPriority: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let high = V2PlanEntryPriority(rawValue: "high")
    public static let medium = V2PlanEntryPriority(rawValue: "medium")
    public static let low = V2PlanEntryPriority(rawValue: "low")
}

// MARK: - V2PlanEntryStatus

/// **UNSTABLE** - Status of a plan entry in the execution flow.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2PlanEntryStatus: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let pending = V2PlanEntryStatus(rawValue: "pending")
    public static let inProgress = V2PlanEntryStatus(rawValue: "in_progress")
    public static let completed = V2PlanEntryStatus(rawValue: "completed")
}

// MARK: - V2PlanId

/// **UNSTABLE** - Unique identifier for a plan within a session.
public struct V2PlanId: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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
}

extension V2PlanId: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - V2PlanEntry

/// **UNSTABLE** - A single entry in the execution plan.
public struct V2PlanEntry: Codable, Sendable, Hashable {
    public let content: String
    public let priority: V2PlanEntryPriority
    public let status: V2PlanEntryStatus
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        content: String,
        priority: V2PlanEntryPriority,
        status: V2PlanEntryStatus,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.content = content
        self.priority = priority
        self.status = status
        self._meta = _meta
    }
}

// MARK: - V2PlanUpdateContent

/// **UNSTABLE** - Updated content for a plan.
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON and planId.
public enum V2PlanUpdateContent: Codable, Sendable, Hashable {
    case items(Items)
    case file(File)
    case markdown(Markdown)
    case unknown(type: String, planId: V2PlanId, rawJson: [String: JsonValue])

    public struct Items: Codable, Sendable, Hashable {
        public let planId: V2PlanId
        public let entries: [V2PlanEntry]
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(planId: V2PlanId, entries: [V2PlanEntry], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.planId = planId
            self.entries = entries
            self._meta = _meta
        }
    }

    public struct File: Codable, Sendable, Hashable {
        public let planId: V2PlanId
        public let uri: String
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(planId: V2PlanId, uri: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.planId = planId
            self.uri = uri
            self._meta = _meta
        }
    }

    public struct Markdown: Codable, Sendable, Hashable {
        public let planId: V2PlanId
        public let content: String
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(planId: V2PlanId, content: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.planId = planId
            self.content = content
            self._meta = _meta
        }
    }

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "items":
            self = .items(try Items(from: decoder))
        case "file":
            self = .file(try File(from: decoder))
        case "markdown":
            self = .markdown(try Markdown(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            guard case .string(let planIdStr) = raw["planId"] else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Missing 'planId' in unknown PlanUpdateContent"
                )
            }
            self = .unknown(type: typeStr, planId: V2PlanId(rawValue: planIdStr), rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .items(let v):
            try typeContainer.encode("items", forKey: .type)
            try v.encode(to: encoder)
        case .file(let v):
            try typeContainer.encode("file", forKey: .type)
            try v.encode(to: encoder)
        case .markdown(let v):
            try typeContainer.encode("markdown", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, _, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2PlanUpdate

/// **UNSTABLE** - A content update for a plan identified by ID.
public struct V2PlanUpdate: Codable, Sendable, Hashable {
    public let plan: V2PlanUpdateContent
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(plan: V2PlanUpdateContent, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.plan = plan
        self._meta = _meta
    }
}

// MARK: - V2PlanRemoved

/// **UNSTABLE** - Removal notice for a plan identified by ID.
public struct V2PlanRemoved: Codable, Sendable, Hashable {
    public let planId: V2PlanId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(planId: V2PlanId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.planId = planId
        self._meta = _meta
    }
}
