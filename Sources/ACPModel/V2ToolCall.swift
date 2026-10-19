import Foundation

// MARK: - V2ToolKind

/// **UNSTABLE** - Categories of tools that can be invoked (v2 open enum).
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2ToolKind: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let read = V2ToolKind(rawValue: "read")
    public static let edit = V2ToolKind(rawValue: "edit")
    public static let delete = V2ToolKind(rawValue: "delete")
    public static let move = V2ToolKind(rawValue: "move")
    public static let search = V2ToolKind(rawValue: "search")
    public static let execute = V2ToolKind(rawValue: "execute")
    public static let think = V2ToolKind(rawValue: "think")
    public static let fetch = V2ToolKind(rawValue: "fetch")
    public static let switchMode = V2ToolKind(rawValue: "switch_mode")
    public static let other = V2ToolKind(rawValue: "other")
}

extension V2ToolKind: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - V2ToolCallStatus

/// **UNSTABLE** - Execution status of a tool call (v2 open enum).
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2ToolCallStatus: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let pending = V2ToolCallStatus(rawValue: "pending")
    public static let inProgress = V2ToolCallStatus(rawValue: "in_progress")
    public static let completed = V2ToolCallStatus(rawValue: "completed")
    public static let failed = V2ToolCallStatus(rawValue: "failed")
    public static let cancelled = V2ToolCallStatus(rawValue: "cancelled")
}

extension V2ToolCallStatus: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - V2DiffPatchFormat

/// **UNSTABLE** - Text patch format used by diff content.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2DiffPatchFormat: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let gitPatch = V2DiffPatchFormat(rawValue: "git_patch")
}

// MARK: - V2DiffFileType

/// **UNSTABLE** - Kind of file content represented by a diff change.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2DiffFileType: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let text = V2DiffFileType(rawValue: "text")
    public static let binary = V2DiffFileType(rawValue: "binary")
    public static let directory = V2DiffFileType(rawValue: "directory")
    public static let symlink = V2DiffFileType(rawValue: "symlink")
}

// MARK: - V2DiffChangeOperation

/// **UNSTABLE** - File operation for a diff change.
public enum V2DiffChangeOperation: Sendable, Hashable {
    case add(path: String)
    case delete(path: String)
    case modify(path: String)
    case move(oldPath: String, path: String)
    case copy(oldPath: String, path: String)
    case unknown(operation: String, fields: [String: JsonValue])
}

// MARK: - V2DiffPatch

/// **UNSTABLE** - Renderable patch text.
public struct V2DiffPatch: Codable, Sendable, Hashable {
    public let format: V2DiffPatchFormat
    public let diff: String

    public init(format: V2DiffPatchFormat = .gitPatch, diff: String) {
        self.format = format
        self.diff = diff
    }
}

// MARK: - V2DiffChange

/// **UNSTABLE** - One file-level change described by a diff.
public struct V2DiffChange: Codable, Sendable, Hashable {
    public let operation: V2DiffChangeOperation
    public let fileType: V2DiffFileType?
    public let mimeType: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        operation: V2DiffChangeOperation,
        fileType: V2DiffFileType? = nil,
        mimeType: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.operation = operation
        self.fileType = fileType
        self.mimeType = mimeType
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case operation, fileType, mimeType, _meta // swiftlint:disable:this identifier_name
        case path, oldPath
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let operationStr = try container.decode(String.self, forKey: .operation)
        switch operationStr {
        case "add":
            let path = try container.decode(String.self, forKey: .path)
            self.operation = .add(path: path)
        case "delete":
            let path = try container.decode(String.self, forKey: .path)
            self.operation = .delete(path: path)
        case "modify":
            let path = try container.decode(String.self, forKey: .path)
            self.operation = .modify(path: path)
        case "move":
            let oldPath = try container.decode(String.self, forKey: .oldPath)
            let path = try container.decode(String.self, forKey: .path)
            self.operation = .move(oldPath: oldPath, path: path)
        case "copy":
            let oldPath = try container.decode(String.self, forKey: .oldPath)
            let path = try container.decode(String.self, forKey: .path)
            self.operation = .copy(oldPath: oldPath, path: path)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self.operation = .unknown(operation: operationStr, fields: raw)
        }
        self.fileType = try container.decodeIfPresent(V2DiffFileType.self, forKey: .fileType)
        self.mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch operation {
        case .add(let path):
            try container.encode("add", forKey: .operation)
            try container.encode(path, forKey: .path)
        case .delete(let path):
            try container.encode("delete", forKey: .operation)
            try container.encode(path, forKey: .path)
        case .modify(let path):
            try container.encode("modify", forKey: .operation)
            try container.encode(path, forKey: .path)
        case .move(let oldPath, let path):
            try container.encode("move", forKey: .operation)
            try container.encode(oldPath, forKey: .oldPath)
            try container.encode(path, forKey: .path)
        case .copy(let oldPath, let path):
            try container.encode("copy", forKey: .operation)
            try container.encode(oldPath, forKey: .oldPath)
            try container.encode(path, forKey: .path)
        case .unknown(let op, _):
            try container.encode(op, forKey: .operation)
        }
        try container.encodeIfPresent(fileType, forKey: .fileType)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
        try container.encodeIfPresent(_meta, forKey: ._meta)
    }
}

// MARK: - V2ToolCallContent

/// **UNSTABLE** - Content produced by a tool call (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2ToolCallContent: Codable, Sendable, Hashable {
    case content(Content)
    case diff(Diff)
    case terminal(Terminal)
    case unknown(type: String, rawJson: [String: JsonValue])

    public struct Content: Codable, Sendable, Hashable {
        public let content: V2ContentBlock
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(content: V2ContentBlock, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.content = content
            self._meta = _meta
        }
    }

    public struct Diff: Codable, Sendable, Hashable {
        public let changes: [V2DiffChange]
        public let patch: V2DiffPatch?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(changes: [V2DiffChange], patch: V2DiffPatch? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.changes = changes
            self.patch = patch
            self._meta = _meta
        }
    }

    /// A display-only reference to an agent-owned terminal.
    public struct Terminal: Codable, Sendable, Hashable {
        public let terminalId: TerminalId
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(terminalId: TerminalId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.terminalId = terminalId
            self._meta = _meta
        }
    }

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "content":
            self = .content(try Content(from: decoder))
        case "diff":
            self = .diff(try Diff(from: decoder))
        case "terminal":
            self = .terminal(try Terminal(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .content(let v):
            try typeContainer.encode("content", forKey: .type)
            try v.encode(to: encoder)
        case .diff(let v):
            try typeContainer.encode("diff", forKey: .type)
            try v.encode(to: encoder)
        case .terminal(let v):
            try typeContainer.encode("terminal", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2ToolCallUpdate

/// **UNSTABLE** - An upsert for a tool call that the language model has requested.
///
/// Replaces v1's separate `tool_call` / `tool_call_update` variants: creation and update use
/// the same `tool_call_update` session update, keyed by `toolCallId`.
///
/// Only `toolCallId` is required. Other fields have patch semantics via `V2MaybeUndefined`:
/// an omitted field leaves the existing tool call value unchanged, `null` clears it, and a
/// concrete value replaces it.
public struct V2ToolCallUpdate: Sendable, Hashable {
    public let toolCallId: ToolCallId
    public let title: V2MaybeUndefined<String>
    public let kind: V2MaybeUndefined<V2ToolKind>
    public let status: V2MaybeUndefined<V2ToolCallStatus>
    public let content: V2MaybeUndefined<[V2ToolCallContent]>
    public let locations: V2MaybeUndefined<[ToolCallLocation]>
    public let rawInput: V2MaybeUndefined<JsonValue>
    public let rawOutput: V2MaybeUndefined<JsonValue>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        toolCallId: ToolCallId,
        title: V2MaybeUndefined<String> = .undefined,
        kind: V2MaybeUndefined<V2ToolKind> = .undefined,
        status: V2MaybeUndefined<V2ToolCallStatus> = .undefined,
        content: V2MaybeUndefined<[V2ToolCallContent]> = .undefined,
        locations: V2MaybeUndefined<[ToolCallLocation]> = .undefined,
        rawInput: V2MaybeUndefined<JsonValue> = .undefined,
        rawOutput: V2MaybeUndefined<JsonValue> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.toolCallId = toolCallId
        self.title = title
        self.kind = kind
        self.status = status
        self.content = content
        self.locations = locations
        self.rawInput = rawInput
        self.rawOutput = rawOutput
        self._meta = _meta
    }

    /// Applies a later tool-call patch to this stored tool-call state.
    public func applyUpdate(_ update: V2ToolCallUpdate) -> V2ToolCallUpdate {
        precondition(toolCallId == update.toolCallId,
                     "Cannot apply update for tool call '\(update.toolCallId)' to tool call '\(toolCallId)'")
        return V2ToolCallUpdate(
            toolCallId: toolCallId,
            title: update.title.orElse(title),
            kind: update.kind.orElse(kind),
            status: update.status.orElse(status),
            content: update.content.orElse(content),
            locations: update.locations.orElse(locations),
            rawInput: update.rawInput.orElse(rawInput),
            rawOutput: update.rawOutput.orElse(rawOutput),
            _meta: update._meta.orElse(_meta)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case toolCallId, title, kind, status, content, locations, rawInput, rawOutput
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2ToolCallUpdate: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let idStr) = raw["toolCallId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'toolCallId' in V2ToolCallUpdate"
            )
        }
        self.toolCallId = ToolCallId(value: idStr)
        self.title = decodeMaybeUndefined(raw, key: "title")
        self.kind = decodeMaybeUndefined(raw, key: "kind")
        self.status = decodeMaybeUndefined(raw, key: "status")
        self.content = decodeMaybeUndefinedList(raw, key: "content")
        self.locations = decodeMaybeUndefinedList(raw, key: "locations")
        self.rawInput = decodeMaybeUndefined(raw, key: "rawInput")
        self.rawOutput = decodeMaybeUndefined(raw, key: "rawOutput")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toolCallId, forKey: .toolCallId)
        try encodeMaybeUndefined(title, forKey: .title, into: &container)
        try encodeMaybeUndefined(kind, forKey: .kind, into: &container)
        try encodeMaybeUndefined(status, forKey: .status, into: &container)
        try encodeMaybeUndefined(content, forKey: .content, into: &container)
        try encodeMaybeUndefined(locations, forKey: .locations, into: &container)
        try encodeMaybeUndefined(rawInput, forKey: .rawInput, into: &container)
        try encodeMaybeUndefined(rawOutput, forKey: .rawOutput, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

// MARK: - V2ToolCallContentChunk

/// **UNSTABLE** - A streamed item of tool-call content (v2).
public struct V2ToolCallContentChunk: Codable, Sendable, Hashable {
    public let toolCallId: ToolCallId
    public let content: V2ToolCallContent
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        toolCallId: ToolCallId,
        content: V2ToolCallContent,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.toolCallId = toolCallId
        self.content = content
        self._meta = _meta
    }
}
