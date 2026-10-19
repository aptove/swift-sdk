import Foundation

// MARK: - PlanVariant

/// **UNSTABLE** - A plan variant that supports multiple formats and plan identity.
///
/// Used with the `plan_update` session update type to provide richer plan
/// representations including structured items, file references, and markdown.
/// Each variant carries a required `id` for tracking multiple concurrent plans.
public enum PlanVariant: Codable, Sendable, Hashable {
    case items(id: String, entries: [PlanEntry], _meta: MetaField?)
    case file(id: String, uri: String, _meta: MetaField?)
    case markdown(id: String, content: String, _meta: MetaField?)
    case unknown(JsonValue)

    private enum CodingKeys: String, CodingKey {
        case type, id, entries, uri, content, _meta
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeStr = try container.decode(String.self, forKey: .type)
        switch typeStr {
        case "items":
            let id = try container.decode(String.self, forKey: .id)
            let entries = try container.decode([PlanEntry].self, forKey: .entries)
            let meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .items(id: id, entries: entries, _meta: meta)
        case "file":
            let id = try container.decode(String.self, forKey: .id)
            let uri = try container.decode(String.self, forKey: .uri)
            let meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .file(id: id, uri: uri, _meta: meta)
        case "markdown":
            let id = try container.decode(String.self, forKey: .id)
            let content = try container.decode(String.self, forKey: .content)
            let meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .markdown(id: id, content: content, _meta: meta)
        default:
            let value = try decoder.singleValueContainer().decode(JsonValue.self)
            self = .unknown(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .items(let id, let entries, let meta):
            try container.encode("items", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(entries, forKey: .entries)
            try container.encodeIfPresent(meta, forKey: ._meta)
        case .file(let id, let uri, let meta):
            try container.encode("file", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(uri, forKey: .uri)
            try container.encodeIfPresent(meta, forKey: ._meta)
        case .markdown(let id, let content, let meta):
            try container.encode("markdown", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(content, forKey: .content)
            try container.encodeIfPresent(meta, forKey: ._meta)
        case .unknown(let value):
            var singleContainer = encoder.singleValueContainer()
            try singleContainer.encode(value)
        }
    }
}

/// Priority levels for plan entries.
///
/// Used to indicate the relative importance or urgency of different
/// tasks in the execution plan.
///
/// See protocol docs: [Plan Entries](https://agentclientprotocol.com/protocol/agent-plan#plan-entries)
public enum PlanEntryPriority: String, Codable, Sendable, Hashable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

/// Status of a plan entry in the execution flow.
///
/// Tracks the lifecycle of each task from planning through completion.
///
/// See protocol docs: [Plan Entries](https://agentclientprotocol.com/protocol/agent-plan#plan-entries)
public enum PlanEntryStatus: String, Codable, Sendable, Hashable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
}

/// A single entry in the execution plan.
///
/// Represents a task or goal that the assistant intends to accomplish
/// as part of fulfilling the user's request.
///
/// See protocol docs: [Plan Entries](https://agentclientprotocol.com/protocol/agent-plan#plan-entries)
public struct PlanEntry: Codable, Sendable, Hashable {
    /// Description of the task or goal
    public let content: String

    /// Priority level
    public let priority: PlanEntryPriority

    /// Current status
    public let status: PlanEntryStatus

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a plan entry.
    public init(
        content: String,
        priority: PlanEntryPriority,
        status: PlanEntryStatus,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.content = content
        self.priority = priority
        self.status = status
        self._meta = _meta
    }
}
