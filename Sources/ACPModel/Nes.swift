// MARK: - NES (Next Edit Suggestions) Types

// MARK: - Enums

/// **UNSTABLE** - Position encoding kind for NES document events.
public enum NesPositionEncodingKind: String, Codable, Sendable, Hashable {
    case utf16 = "utf-16"
    case utf32 = "utf-32"
    case utf8 = "utf-8"
}

/// **UNSTABLE** - How document content changes are synchronized.
public enum TextDocumentSyncKind: String, Codable, Sendable, Hashable {
    case full = "full"
    case incremental = "incremental"
}

/// **UNSTABLE** - What triggered a NES suggestion.
public enum NesTriggerKind: String, Codable, Sendable, Hashable {
    case automatic = "automatic"
    case diagnostic = "diagnostic"
    case manual = "manual"
}

/// **UNSTABLE** - Reason a NES suggestion was rejected.
public enum NesRejectReason: String, Codable, Sendable, Hashable {
    case rejected = "rejected"
    case ignored = "ignored"
    case replaced = "replaced"
    case cancelled = "cancelled"
}

/// **UNSTABLE** - Severity of a NES diagnostic.
public enum NesDiagnosticSeverity: String, Codable, Sendable, Hashable {
    case error = "error"
    case warning = "warning"
    case information = "information"
    case hint = "hint"
}

// MARK: - Position Primitives

/// **UNSTABLE** - A position in a text document.
public struct NesPosition: Codable, Sendable, Hashable {
    public let line: UInt32
    public let character: UInt32

    public init(line: UInt32, character: UInt32) {
        self.line = line
        self.character = character
    }
}

/// **UNSTABLE** - A range in a text document.
public struct NesRange: Codable, Sendable, Hashable {
    public let start: NesPosition
    public let end: NesPosition

    public init(start: NesPosition, end: NesPosition) {
        self.start = start
        self.end = end
    }
}

// MARK: - Agent NES Capabilities

/// **UNSTABLE** - NES capabilities supported by the agent.
public struct NesCapabilities: Codable, Sendable, Hashable {
    public let events: NesEventCapabilities?
    public let context: NesContextCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        events: NesEventCapabilities? = nil,
        context: NesContextCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.events = events
        self.context = context
        self._meta = _meta
    }
}

/// **UNSTABLE** - NES event capabilities supported by the agent.
public struct NesEventCapabilities: Codable, Sendable, Hashable {
    public let document: NesDocumentEventCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        document: NesDocumentEventCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.document = document
        self._meta = _meta
    }
}

/// **UNSTABLE** - NES document event capabilities.
public struct NesDocumentEventCapabilities: Codable, Sendable, Hashable {
    public let didOpen: NesDocumentDidOpenCapabilities?
    public let didChange: NesDocumentDidChangeCapabilities?
    public let didClose: NesDocumentDidCloseCapabilities?
    public let didSave: NesDocumentDidSaveCapabilities?
    public let didFocus: NesDocumentDidFocusCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        didOpen: NesDocumentDidOpenCapabilities? = nil,
        didChange: NesDocumentDidChangeCapabilities? = nil,
        didClose: NesDocumentDidCloseCapabilities? = nil,
        didSave: NesDocumentDidSaveCapabilities? = nil,
        didFocus: NesDocumentDidFocusCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.didOpen = didOpen
        self.didChange = didChange
        self.didClose = didClose
        self.didSave = didSave
        self.didFocus = didFocus
        self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesDocumentDidOpenCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesDocumentDidChangeCapabilities: Codable, Sendable, Hashable {
    public let syncKind: TextDocumentSyncKind
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(syncKind: TextDocumentSyncKind, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.syncKind = syncKind; self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesDocumentDidCloseCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesDocumentDidSaveCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesDocumentDidFocusCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE** - NES context capabilities.
public struct NesContextCapabilities: Codable, Sendable, Hashable {
    public let recentFiles: NesRecentFilesCapabilities?
    public let relatedSnippets: NesRelatedSnippetsCapabilities?
    public let editHistory: NesEditHistoryCapabilities?
    public let userActions: NesUserActionsCapabilities?
    public let openFiles: NesOpenFilesCapabilities?
    public let diagnostics: NesDiagnosticsCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        recentFiles: NesRecentFilesCapabilities? = nil,
        relatedSnippets: NesRelatedSnippetsCapabilities? = nil,
        editHistory: NesEditHistoryCapabilities? = nil,
        userActions: NesUserActionsCapabilities? = nil,
        openFiles: NesOpenFilesCapabilities? = nil,
        diagnostics: NesDiagnosticsCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.recentFiles = recentFiles
        self.relatedSnippets = relatedSnippets
        self.editHistory = editHistory
        self.userActions = userActions
        self.openFiles = openFiles
        self.diagnostics = diagnostics
        self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesRecentFilesCapabilities: Codable, Sendable, Hashable {
    public let maxCount: Int?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(maxCount: Int? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.maxCount = maxCount; self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesRelatedSnippetsCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesEditHistoryCapabilities: Codable, Sendable, Hashable {
    public let maxCount: Int?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(maxCount: Int? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.maxCount = maxCount; self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesUserActionsCapabilities: Codable, Sendable, Hashable {
    public let maxCount: Int?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(maxCount: Int? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.maxCount = maxCount; self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesOpenFilesCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesDiagnosticsCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

// MARK: - Client NES Capabilities

/// **UNSTABLE** - NES capabilities supported by the client.
public struct ClientNesCapabilities: Codable, Sendable, Hashable {
    public let jump: NesJumpCapabilities?
    public let rename: NesRenameCapabilities?
    public let searchAndReplace: NesSearchAndReplaceCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        jump: NesJumpCapabilities? = nil,
        rename: NesRenameCapabilities? = nil,
        searchAndReplace: NesSearchAndReplaceCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.jump = jump
        self.rename = rename
        self.searchAndReplace = searchAndReplace
        self._meta = _meta
    }
}

/// **UNSTABLE**
public struct NesJumpCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesRenameCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

/// **UNSTABLE**
public struct NesSearchAndReplaceCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

// MARK: - NES Session Lifecycle

/// **UNSTABLE** - A workspace folder for NES sessions.
public struct WorkspaceFolder: Codable, Sendable, Hashable {
    public let uri: String
    public let name: String

    public init(uri: String, name: String) {
        self.uri = uri
        self.name = name
    }
}

/// **UNSTABLE** - Repository information for NES sessions.
public struct NesRepository: Codable, Sendable, Hashable {
    public let name: String
    public let owner: String
    public let remoteUrl: String

    public init(name: String, owner: String, remoteUrl: String) {
        self.name = name
        self.owner = owner
        self.remoteUrl = remoteUrl
    }
}

/// **UNSTABLE** - Request to start a NES session.
public struct StartNesRequest: AcpRequest, Codable, Sendable, Hashable {
    public let workspaceUri: String?
    public let workspaceFolders: [WorkspaceFolder]?
    public let repository: NesRepository?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        workspaceUri: String? = nil,
        workspaceFolders: [WorkspaceFolder]? = nil,
        repository: NesRepository? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.workspaceUri = workspaceUri
        self.workspaceFolders = workspaceFolders
        self.repository = repository
        self._meta = _meta
    }
}

/// **UNSTABLE** - Response from starting a NES session.
public struct StartNesResponse: AcpResponse, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self._meta = _meta
    }
}

/// **UNSTABLE** - Request to close a NES session.
public struct CloseNesRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self._meta = _meta
    }
}

/// **UNSTABLE** - Response from closing a NES session.
public struct CloseNesResponse: AcpResponse, Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name
    public init(_meta: MetaField? = nil) { self._meta = _meta } // swiftlint:disable:this identifier_name
}

// MARK: - NES Suggest

/// **UNSTABLE** - Request to get NES suggestions at a position.
public struct SuggestNesRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let uri: String
    public let version: Int64
    public let position: NesPosition
    public let selection: NesRange?
    public let triggerKind: NesTriggerKind
    public let context: NesSuggestContext?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        sessionId: SessionId,
        uri: String,
        version: Int64,
        position: NesPosition,
        selection: NesRange? = nil,
        triggerKind: NesTriggerKind,
        context: NesSuggestContext? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.uri = uri
        self.version = version
        self.position = position
        self.selection = selection
        self.triggerKind = triggerKind
        self.context = context
        self._meta = _meta
    }
}

/// **UNSTABLE** - Response containing NES suggestions.
public struct SuggestNesResponse: AcpResponse, Codable, Sendable, Hashable {
    public let suggestions: [NesSuggestion]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(suggestions: [NesSuggestion], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.suggestions = suggestions; self._meta = _meta
    }
}

/// **UNSTABLE** - Context provided to NES suggest requests.
public struct NesSuggestContext: Codable, Sendable, Hashable {
    public let recentFiles: [NesRecentFile]?
    public let relatedSnippets: [NesRelatedSnippet]?
    public let editHistory: [NesEditHistoryEntry]?
    public let userActions: [NesUserAction]?
    public let openFiles: [NesOpenFile]?
    public let diagnostics: [NesDiagnostic]?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        recentFiles: [NesRecentFile]? = nil,
        relatedSnippets: [NesRelatedSnippet]? = nil,
        editHistory: [NesEditHistoryEntry]? = nil,
        userActions: [NesUserAction]? = nil,
        openFiles: [NesOpenFile]? = nil,
        diagnostics: [NesDiagnostic]? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.recentFiles = recentFiles
        self.relatedSnippets = relatedSnippets
        self.editHistory = editHistory
        self.userActions = userActions
        self.openFiles = openFiles
        self.diagnostics = diagnostics
        self._meta = _meta
    }
}

// MARK: - NES Context Detail Types

/// **UNSTABLE**
public struct NesRecentFile: Codable, Sendable, Hashable {
    public let uri: String
    public let languageId: String
    public let text: String

    public init(uri: String, languageId: String, text: String) {
        self.uri = uri; self.languageId = languageId; self.text = text
    }
}

/// **UNSTABLE**
public struct NesRelatedSnippet: Codable, Sendable, Hashable {
    public let uri: String
    public let excerpts: [NesExcerpt]

    public init(uri: String, excerpts: [NesExcerpt]) {
        self.uri = uri; self.excerpts = excerpts
    }
}

/// **UNSTABLE**
public struct NesExcerpt: Codable, Sendable, Hashable {
    public let startLine: UInt32
    public let endLine: UInt32
    public let text: String

    public init(startLine: UInt32, endLine: UInt32, text: String) {
        self.startLine = startLine; self.endLine = endLine; self.text = text
    }
}

/// **UNSTABLE**
public struct NesEditHistoryEntry: Codable, Sendable, Hashable {
    public let uri: String
    public let diff: String

    public init(uri: String, diff: String) {
        self.uri = uri; self.diff = diff
    }
}

/// **UNSTABLE**
public struct NesUserAction: Codable, Sendable, Hashable {
    public let action: String
    public let uri: String
    public let position: NesPosition
    public let timestampMs: UInt64

    public init(action: String, uri: String, position: NesPosition, timestampMs: UInt64) {
        self.action = action; self.uri = uri; self.position = position; self.timestampMs = timestampMs
    }
}

/// **UNSTABLE**
public struct NesOpenFile: Codable, Sendable, Hashable {
    public let uri: String
    public let languageId: String
    public let visibleRange: NesRange?
    public let lastFocusedMs: UInt64?

    public init(uri: String, languageId: String, visibleRange: NesRange? = nil, lastFocusedMs: UInt64? = nil) {
        self.uri = uri; self.languageId = languageId
        self.visibleRange = visibleRange; self.lastFocusedMs = lastFocusedMs
    }
}

/// **UNSTABLE**
public struct NesDiagnostic: Codable, Sendable, Hashable {
    public let uri: String
    public let range: NesRange
    public let severity: NesDiagnosticSeverity
    public let message: String

    public init(uri: String, range: NesRange, severity: NesDiagnosticSeverity, message: String) {
        self.uri = uri; self.range = range; self.severity = severity; self.message = message
    }
}

// MARK: - NES Suggestion Types

/// **UNSTABLE** - A suggestion returned by a NES suggest request.
public enum NesSuggestion: Sendable, Hashable {
    case edit(NesEditSuggestion)
    case jump(NesJumpSuggestion)
    case rename(NesRenameSuggestion)
    case searchAndReplace(NesSearchAndReplaceSuggestion)
}

extension NesSuggestion: Codable {
    private enum CodingKeys: String, CodingKey { case kind }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "edit": self = .edit(try NesEditSuggestion(from: decoder))
        case "jump": self = .jump(try NesJumpSuggestion(from: decoder))
        case "rename": self = .rename(try NesRenameSuggestion(from: decoder))
        case "searchAndReplace": self = .searchAndReplace(try NesSearchAndReplaceSuggestion(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container,
                debugDescription: "Unknown NesSuggestion kind: \(kind)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .edit(let s): try s.encode(to: encoder)
        case .jump(let s): try s.encode(to: encoder)
        case .rename(let s): try s.encode(to: encoder)
        case .searchAndReplace(let s): try s.encode(to: encoder)
        }
    }
}

/// **UNSTABLE**
public struct NesTextEdit: Codable, Sendable, Hashable {
    public let range: NesRange
    public let newText: String

    public init(range: NesRange, newText: String) {
        self.range = range; self.newText = newText
    }
}

/// **UNSTABLE**
public struct NesEditSuggestion: Codable, Sendable, Hashable {
    public let id: String
    public let uri: String
    public let edits: [NesTextEdit]
    public let cursorPosition: NesPosition?

    private enum CodingKeys: String, CodingKey { case kind, id, uri, edits, cursorPosition }

    public init(id: String, uri: String, edits: [NesTextEdit], cursorPosition: NesPosition? = nil) {
        self.id = id; self.uri = uri; self.edits = edits; self.cursorPosition = cursorPosition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.uri = try container.decode(String.self, forKey: .uri)
        self.edits = try container.decode([NesTextEdit].self, forKey: .edits)
        self.cursorPosition = try container.decodeIfPresent(NesPosition.self, forKey: .cursorPosition)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("edit", forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(uri, forKey: .uri)
        try container.encode(edits, forKey: .edits)
        try container.encodeIfPresent(cursorPosition, forKey: .cursorPosition)
    }
}

/// **UNSTABLE**
public struct NesJumpSuggestion: Codable, Sendable, Hashable {
    public let id: String
    public let uri: String
    public let position: NesPosition

    private enum CodingKeys: String, CodingKey { case kind, id, uri, position }

    public init(id: String, uri: String, position: NesPosition) {
        self.id = id; self.uri = uri; self.position = position
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.uri = try container.decode(String.self, forKey: .uri)
        self.position = try container.decode(NesPosition.self, forKey: .position)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("jump", forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(uri, forKey: .uri)
        try container.encode(position, forKey: .position)
    }
}

/// **UNSTABLE**
public struct NesRenameSuggestion: Codable, Sendable, Hashable {
    public let id: String
    public let uri: String
    public let position: NesPosition
    public let newName: String

    private enum CodingKeys: String, CodingKey { case kind, id, uri, position, newName }

    public init(id: String, uri: String, position: NesPosition, newName: String) {
        self.id = id; self.uri = uri; self.position = position; self.newName = newName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.uri = try container.decode(String.self, forKey: .uri)
        self.position = try container.decode(NesPosition.self, forKey: .position)
        self.newName = try container.decode(String.self, forKey: .newName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("rename", forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(uri, forKey: .uri)
        try container.encode(position, forKey: .position)
        try container.encode(newName, forKey: .newName)
    }
}

/// **UNSTABLE**
public struct NesSearchAndReplaceSuggestion: Codable, Sendable, Hashable {
    public let id: String
    public let uri: String
    public let search: String
    public let replace: String
    public let isRegex: Bool

    private enum CodingKeys: String, CodingKey { case kind, id, uri, search, replace, isRegex }

    public init(id: String, uri: String, search: String, replace: String, isRegex: Bool = false) {
        self.id = id; self.uri = uri; self.search = search; self.replace = replace; self.isRegex = isRegex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.uri = try container.decode(String.self, forKey: .uri)
        self.search = try container.decode(String.self, forKey: .search)
        self.replace = try container.decode(String.self, forKey: .replace)
        self.isRegex = try container.decodeIfPresent(Bool.self, forKey: .isRegex) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("searchAndReplace", forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(uri, forKey: .uri)
        try container.encode(search, forKey: .search)
        try container.encode(replace, forKey: .replace)
        try container.encode(isRegex, forKey: .isRegex)
    }
}

// MARK: - NES Accept/Reject Notifications

/// **UNSTABLE** - Notification that a NES suggestion was accepted.
public struct AcceptNesNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let id: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, id: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.id = id; self._meta = _meta
    }
}

/// **UNSTABLE** - Notification that a NES suggestion was rejected.
public struct RejectNesNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let id: String
    public let reason: NesRejectReason?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, id: String, reason: NesRejectReason? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.id = id; self.reason = reason; self._meta = _meta
    }
}

// MARK: - NES Document Event Notifications

/// **UNSTABLE** - Notification that a document was opened.
public struct DidOpenDocumentNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let uri: String
    public let languageId: String
    public let version: Int64
    public let text: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, uri: String, languageId: String, version: Int64, text: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.uri = uri; self.languageId = languageId
        self.version = version; self.text = text; self._meta = _meta
    }
}

/// **UNSTABLE** - Notification that a document's content changed.
public struct DidChangeDocumentNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let uri: String
    public let version: Int64
    public let contentChanges: [TextDocumentContentChangeEvent]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, uri: String, version: Int64, contentChanges: [TextDocumentContentChangeEvent], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.uri = uri; self.version = version
        self.contentChanges = contentChanges; self._meta = _meta
    }
}

/// **UNSTABLE** - A content change event for a text document.
public struct TextDocumentContentChangeEvent: Codable, Sendable, Hashable {
    public let range: NesRange?
    public let text: String

    public init(range: NesRange? = nil, text: String) {
        self.range = range; self.text = text
    }
}

/// **UNSTABLE** - Notification that a document was closed.
public struct DidCloseDocumentNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let uri: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, uri: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.uri = uri; self._meta = _meta
    }
}

/// **UNSTABLE** - Notification that a document was saved.
public struct DidSaveDocumentNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let uri: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, uri: String, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.uri = uri; self._meta = _meta
    }
}

/// **UNSTABLE** - Notification that a document was focused.
public struct DidFocusDocumentNotification: AcpNotification, AcpWithSessionId, Codable, Sendable, Hashable {
    public let sessionId: SessionId
    public let uri: String
    public let version: Int64
    public let position: NesPosition
    public let visibleRange: NesRange
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(sessionId: SessionId, uri: String, version: Int64, position: NesPosition, visibleRange: NesRange, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.sessionId = sessionId; self.uri = uri; self.version = version
        self.position = position; self.visibleRange = visibleRange; self._meta = _meta
    }
}
