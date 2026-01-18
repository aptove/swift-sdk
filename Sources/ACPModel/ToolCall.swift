import Foundation

/// Categories of tools that can be invoked.
///
/// Tool kinds help clients choose appropriate icons and optimize how they
/// display tool execution progress.
///
/// See protocol docs: [Creating](https://agentclientprotocol.com/protocol/tool-calls#creating)
public enum ToolKind: String, Codable, Sendable, Hashable {
    case read = "read"
    case edit = "edit"
    case delete = "delete"
    case move = "move"
    case search = "search"
    case execute = "execute"
    case think = "think"
    case fetch = "fetch"
    case switchMode = "switch_mode"
    case other = "other"
}

/// Execution status of a tool call.
///
/// Tool calls progress through different statuses during their lifecycle.
///
/// See protocol docs: [Status](https://agentclientprotocol.com/protocol/tool-calls#status)
public enum ToolCallStatus: String, Codable, Sendable, Hashable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
}

/// A file location being accessed or modified by a tool.
///
/// Enables clients to implement "follow-along" features that track
/// which files the agent is working with in real-time.
///
/// See protocol docs: [Following the Agent](https://agentclientprotocol.com/protocol/tool-calls#following-the-agent)
public struct ToolCallLocation: Codable, Sendable, Hashable {
    /// File path
    public let path: String

    /// Optional line number
    public let line: UInt?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a tool call location.
    public init(
        path: String,
        line: UInt? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.path = path
        self.line = line
        self._meta = _meta
    }
}

/// Content produced by a tool call.
///
/// Tool calls can produce different types of content including
/// standard content blocks (text, images) or file diffs.
///
/// See protocol docs: [Content](https://agentclientprotocol.com/protocol/tool-calls#content)
public enum ToolCallContent: Codable, Sendable, Hashable {
    /// Standard content block (text, images, resources)
    case content(ContentContent)

    /// File modification shown as a diff
    case diff(DiffContent)

    /// Terminal output reference
    case terminal(TerminalContent)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "type"
    }

    private enum ContentType: String, Codable {
        case content = "content"
        case diff = "diff"
        case terminal = "terminal"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .content:
            self = .content(try ContentContent(from: decoder))
        case .diff:
            self = .diff(try DiffContent(from: decoder))
        case .terminal:
            self = .terminal(try TerminalContent(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .content(let content):
            try content.encode(to: encoder)
        case .diff(let diff):
            try diff.encode(to: encoder)
        case .terminal(let terminal):
            try terminal.encode(to: encoder)
        }
    }
}

/// Standard content block in a tool call.
public struct ContentContent: Codable, Sendable, Hashable {
    /// The content block
    public let content: ContentBlock

    /// Creates content content.
    public init(content: ContentBlock) {
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case content = "content"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(ContentBlock.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("content", forKey: .type)
        try container.encode(content, forKey: .content)
    }
}

/// File modification shown as a diff.
public struct DiffContent: Codable, Sendable, Hashable {
    /// File path
    public let path: String

    /// New file content
    public let newText: String

    /// Original file content (if any)
    public let oldText: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates diff content.
    public init(
        path: String,
        newText: String,
        oldText: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.path = path
        self.newText = newText
        self.oldText = oldText
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case path = "path"
        case newText = "newText"
        case oldText = "oldText"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        newText = try container.decode(String.self, forKey: .newText)
        oldText = try container.decodeIfPresent(String.self, forKey: .oldText)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("diff", forKey: .type)
        try container.encode(path, forKey: .path)
        try container.encode(newText, forKey: .newText)
        try container.encodeIfPresent(oldText, forKey: .oldText)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

/// Terminal output reference.
public struct TerminalContent: Codable, Sendable, Hashable {
    /// Terminal ID
    public let terminalId: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates terminal content.
    public init(
        terminalId: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.terminalId = terminalId
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case terminalId = "terminalId"
        case _meta = "_meta" // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        terminalId = try container.decode(String.self, forKey: .terminalId)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("terminal", forKey: .type)
        try container.encode(terminalId, forKey: .terminalId)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}
