import Foundation

// MARK: - Permission Types

/// The type of permission option being presented to the user.
///
/// Helps clients choose appropriate icons and UI treatment.
public enum PermissionOptionKind: String, Codable, Sendable, Hashable {
    /// Allow the action this one time only
    case allowOnce = "allow_once"
    /// Allow the action always (remember the permission)
    case allowAlways = "allow_always"
    /// Reject the action this one time only
    case rejectOnce = "reject_once"
    /// Reject the action always (remember the rejection)
    case rejectAlways = "reject_always"
}

/// An option presented to the user when requesting permission.
///
/// Used by agents to present permission choices to the user for sensitive operations.
public struct PermissionOption: AcpWithMeta, Codable, Sendable, Hashable {
    /// Unique identifier for this option
    public let optionId: PermissionOptionId

    /// Human-readable name for the option
    public let name: String

    /// The kind of permission this option represents
    public let kind: PermissionOptionKind

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a permission option.
    ///
    /// - Parameters:
    ///   - optionId: Unique identifier
    ///   - name: Human-readable name
    ///   - kind: The permission kind
    ///   - meta: Optional metadata
    public init(
        optionId: PermissionOptionId,
        name: String,
        kind: PermissionOptionKind,
        meta: MetaField? = nil
    ) {
        self.optionId = optionId
        self.name = name
        self.kind = kind
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case optionId = "optionId"
        case name = "name"
        case kind = "kind"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Permission Outcome

/// The outcome of a permission request.
///
/// Indicates how the user responded to the permission request.
public enum RequestPermissionOutcome: Codable, Sendable, Hashable {
    /// The prompt turn was cancelled before the user responded
    case cancelled
    /// The user selected one of the provided options
    case selected(PermissionOptionId)

    private enum CodingKeys: String, CodingKey {
        case outcome = "outcome"
        case optionId = "optionId"
    }

    private enum OutcomeType: String, Codable {
        case cancelled = "cancelled"
        case selected = "selected"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let outcomeType = try container.decode(OutcomeType.self, forKey: .outcome)

        switch outcomeType {
        case .cancelled:
            self = .cancelled
        case .selected:
            let optionId = try container.decode(PermissionOptionId.self, forKey: .optionId)
            self = .selected(optionId)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .cancelled:
            try container.encode(OutcomeType.cancelled, forKey: .outcome)
        case .selected(let optionId):
            try container.encode(OutcomeType.selected, forKey: .outcome)
            try container.encode(optionId, forKey: .optionId)
        }
    }
}

// MARK: - Request Permission Request

/// Request for user permission to execute a tool call.
///
/// Sent when the agent needs authorization before performing a sensitive operation.
///
/// See protocol docs: [Requesting Permission](https://agentclientprotocol.com/protocol/tool-calls#requesting-permission)
public struct RequestPermissionRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session this request belongs to
    public let sessionId: SessionId

    /// The tool call that needs permission
    public let toolCall: ToolCallUpdateData

    /// The permission options to present to the user
    public let options: [PermissionOption]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a permission request.
    ///
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - toolCall: The tool call needing permission
    ///   - options: Available permission options
    ///   - meta: Optional metadata
    public init(
        sessionId: SessionId,
        toolCall: ToolCallUpdateData,
        options: [PermissionOption],
        meta: MetaField? = nil
    ) {
        self.sessionId = sessionId
        self.toolCall = toolCall
        self.options = options
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case toolCall = "toolCall"
        case options = "options"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}

// MARK: - Request Permission Response

/// Response to a permission request.
///
/// Contains the user's decision about the permission request.
public struct RequestPermissionResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The outcome of the permission request
    public let outcome: RequestPermissionOutcome

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a permission response.
    ///
    /// - Parameters:
    ///   - outcome: The user's decision
    ///   - meta: Optional metadata
    public init(outcome: RequestPermissionOutcome, meta: MetaField? = nil) {
        self.outcome = outcome
        self._meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case outcome = "outcome"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }
}
