import Foundation

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
