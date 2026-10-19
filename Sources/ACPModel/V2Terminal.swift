import Foundation

// MARK: - TerminalId

/// **UNSTABLE** - Unique identifier for an agent-owned terminal within a session.
///
/// The agent generates the ID. It is unique within a session, stable for the terminal's
/// lifetime, and MUST NOT be reused for another terminal in that session.
///
/// Terminal IDs and `ToolCallId`s are separate domains: an agent may happen to use the
/// same string for both, but clients MUST NOT rely on that.
public struct TerminalId: Codable, Sendable, Hashable, ExpressibleByStringLiteral {
    public let value: String

    public init(value: String) { self.value = value }
    public init(stringLiteral value: String) { self.value = value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.value = try c.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}

extension TerminalId: CustomStringConvertible {
    public var description: String { value }
}

// MARK: - V2TerminalOutput

/// **UNSTABLE** - An authoritative replacement snapshot of terminal output bytes.
///
/// Replaces all previously stored bytes; clients MUST NOT merge or splice bytes from
/// the previous snapshot into it.
///
/// `data` is base64-encoded (RFC 4648) terminal output bytes.
public struct V2TerminalOutput: Codable, Sendable, Hashable {
    public let data: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(data: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.data = data
        self._meta = _meta
    }
}

// MARK: - V2TerminalExitStatus

/// **UNSTABLE** - Exit information for an agent-owned terminal.
///
/// The presence of this object marks the terminal as exited, even when neither an exit
/// code nor a signal is known.
public struct V2TerminalExitStatus: Codable, Sendable, Hashable {
    public let exitCode: UInt?
    public let signal: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        exitCode: UInt? = nil,
        signal: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.exitCode = exitCode
        self.signal = signal
        self._meta = _meta
    }
}

// MARK: - V2TerminalUpdate

/// **UNSTABLE** - An upsert for the stored state of an agent-owned terminal (v2).
///
/// Only `terminalId` is required. Other fields have patch semantics via `V2MaybeUndefined`:
/// an omitted field leaves the stored value unchanged, `null` clears it, and a concrete
/// value replaces it. On a first-seen terminal, omitted fields start unknown or empty.
///
/// A concrete `output` is a replacement snapshot rather than an append, which is what
/// makes session replay possible without resending every historical chunk.
public struct V2TerminalUpdate: Sendable, Hashable {
    public let terminalId: TerminalId
    public let command: V2MaybeUndefined<String>
    public let cwd: V2MaybeUndefined<String>
    public let output: V2MaybeUndefined<V2TerminalOutput>
    public let exitStatus: V2MaybeUndefined<V2TerminalExitStatus>
    public let _meta: V2MaybeUndefined<JsonValue> // swiftlint:disable:this identifier_name

    public init(
        terminalId: TerminalId,
        command: V2MaybeUndefined<String> = .undefined,
        cwd: V2MaybeUndefined<String> = .undefined,
        output: V2MaybeUndefined<V2TerminalOutput> = .undefined,
        exitStatus: V2MaybeUndefined<V2TerminalExitStatus> = .undefined,
        _meta: V2MaybeUndefined<JsonValue> = .undefined // swiftlint:disable:this identifier_name
    ) {
        self.terminalId = terminalId
        self.command = command
        self.cwd = cwd
        self.output = output
        self.exitStatus = exitStatus
        self._meta = _meta
    }

    /// Applies a later terminal patch to this stored terminal state.
    public func applyUpdate(_ update: V2TerminalUpdate) -> V2TerminalUpdate {
        V2TerminalUpdate(
            terminalId: terminalId,
            command: update.command.orElse(command),
            cwd: update.cwd.orElse(cwd),
            output: update.output.orElse(output),
            exitStatus: update.exitStatus.orElse(exitStatus),
            _meta: update._meta.orElse(_meta)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case terminalId, command, cwd, output, exitStatus
        case _meta // swiftlint:disable:this identifier_name
    }
}

extension V2TerminalUpdate: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let tid) = raw["terminalId"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'terminalId' in V2TerminalUpdate"
            )
        }
        self.terminalId = TerminalId(value: tid)
        self.command = decodeMaybeUndefined(raw, key: "command")
        self.cwd = decodeMaybeUndefined(raw, key: "cwd")
        self.output = decodeMaybeUndefined(raw, key: "output")
        self.exitStatus = decodeMaybeUndefined(raw, key: "exitStatus")
        self._meta = decodeMaybeUndefined(raw, key: "_meta")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(terminalId, forKey: .terminalId)
        try encodeMaybeUndefined(command, forKey: .command, into: &container)
        try encodeMaybeUndefined(cwd, forKey: .cwd, into: &container)
        try encodeMaybeUndefined(output, forKey: .output, into: &container)
        try encodeMaybeUndefined(exitStatus, forKey: .exitStatus, into: &container)
        try encodeMaybeUndefined(_meta, forKey: ._meta, into: &container)
    }
}

// MARK: - V2TerminalOutputChunk

/// **UNSTABLE** - A chunk of bytes appended to an agent-owned terminal's output (v2).
///
/// Each chunk's `data` is independently base64-encoded: decode every chunk separately,
/// then append the resulting bytes in received order. Do not concatenate encoded strings
/// before decoding.
public struct V2TerminalOutputChunk: Codable, Sendable, Hashable {
    public let terminalId: TerminalId
    public let data: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        terminalId: TerminalId,
        data: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.terminalId = terminalId
        self.data = data
        self._meta = _meta
    }
}
