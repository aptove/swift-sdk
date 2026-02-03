import Foundation

/// File system capabilities that a client may support.
///
/// See protocol docs: [FileSystem](https://agentclientprotocol.com/protocol/initialization#filesystem)
public struct FileSystemCapability: Codable, Sendable, Hashable {
    /// Whether the client supports reading text files
    public let readTextFile: Bool

    /// Whether the client supports writing text files
    public let writeTextFile: Bool

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates file system capabilities.
    ///
    /// - Parameters:
    ///   - readTextFile: Read text file support
    ///   - writeTextFile: Write text file support
    ///   - _meta: Optional metadata
    public init(
        readTextFile: Bool = false,
        writeTextFile: Bool = false,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.readTextFile = readTextFile
        self.writeTextFile = writeTextFile
        self._meta = _meta
    }
}

/// Prompt capabilities supported by the agent in `session/prompt` requests.
///
/// Baseline agent functionality requires support for text and resource links in prompt requests.
/// Other variants must be explicitly opted in to.
///
/// See protocol docs: [Prompt Capabilities](https://agentclientprotocol.com/protocol/initialization#prompt-capabilities)
public struct PromptCapabilities: Codable, Sendable, Hashable {
    /// Whether the agent supports audio in prompts
    public let audio: Bool

    /// Whether the agent supports images in prompts
    public let image: Bool

    /// Whether the agent supports embedded context resources
    public let embeddedContext: Bool

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates prompt capabilities.
    ///
    /// - Parameters:
    ///   - audio: Audio support
    ///   - image: Image support
    ///   - embeddedContext: Embedded context support
    ///   - _meta: Optional metadata
    public init(
        audio: Bool = false,
        image: Bool = false,
        embeddedContext: Bool = false,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.audio = audio
        self.image = image
        self.embeddedContext = embeddedContext
        self._meta = _meta
    }

    // Custom decoder to provide defaults for missing fields
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.audio = try container.decodeIfPresent(Bool.self, forKey: .audio) ?? false
        self.image = try container.decodeIfPresent(Bool.self, forKey: .image) ?? false
        self.embeddedContext = try container.decodeIfPresent(Bool.self, forKey: .embeddedContext) ?? false
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    private enum CodingKeys: String, CodingKey {
        case audio, image, embeddedContext, _meta
    }
}

/// MCP capabilities supported by the agent
public struct McpCapabilities: Codable, Sendable, Hashable {
    /// Whether HTTP MCP transport is supported
    public let http: Bool

    /// Whether SSE MCP transport is supported
    public let sse: Bool

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates MCP capabilities.
    ///
    /// - Parameters:
    ///   - http: HTTP transport support
    ///   - sse: SSE transport support
    ///   - _meta: Optional metadata
    public init(
        http: Bool = false,
        sse: Bool = false,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.http = http
        self.sse = sse
        self._meta = _meta
    }
}

/// **UNSTABLE**: Capabilities for forking sessions.
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
public struct SessionForkCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session fork capabilities.
    ///
    /// - Parameter _meta: Optional metadata
    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE**: Capabilities for listing sessions.
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
public struct SessionListCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session list capabilities.
    ///
    /// - Parameter _meta: Optional metadata
    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE**: Capabilities for resuming sessions.
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
public struct SessionResumeCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session resume capabilities.
    ///
    /// - Parameter _meta: Optional metadata
    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// Session capabilities supported by the agent.
public struct SessionCapabilities: Codable, Sendable, Hashable {
    /// Fork session capability (unstable)
    public let fork: SessionForkCapabilities?

    /// List sessions capability (unstable)
    public let list: SessionListCapabilities?

    /// Resume session capability (unstable)
    public let resume: SessionResumeCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session capabilities.
    ///
    /// - Parameters:
    ///   - fork: Fork capability
    ///   - list: List capability
    ///   - resume: Resume capability
    ///   - _meta: Optional metadata
    public init(
        fork: SessionForkCapabilities? = nil,
        list: SessionListCapabilities? = nil,
        resume: SessionResumeCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.fork = fork
        self.list = list
        self.resume = resume
        self._meta = _meta
    }
}

/// Capabilities supported by the client.
///
/// Advertised during initialization to inform the agent about
/// available features and methods.
///
/// See protocol docs: [Client Capabilities](https://agentclientprotocol.com/protocol/initialization#client-capabilities)
public struct ClientCapabilities: Codable, Sendable, Hashable {
    /// File system capabilities
    public let fs: FileSystemCapability?

    /// Whether terminal operations are supported
    public let terminal: Bool

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates client capabilities.
    ///
    /// - Parameters:
    ///   - fs: File system capabilities
    ///   - terminal: Terminal support
    ///   - _meta: Optional metadata
    public init(
        fs: FileSystemCapability? = nil,
        terminal: Bool = false,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.fs = fs
        self.terminal = terminal
        self._meta = _meta
    }
}

/// Capabilities supported by the agent.
///
/// Advertised during initialization to inform the client about
/// available features and content types.
///
/// See protocol docs: [Agent Capabilities](https://agentclientprotocol.com/protocol/initialization#agent-capabilities)
public struct AgentCapabilities: Codable, Sendable, Hashable {
    /// Whether the agent supports loading existing sessions
    public let loadSession: Bool

    /// Prompt content type capabilities
    public let promptCapabilities: PromptCapabilities

    /// MCP transport capabilities
    public let mcpCapabilities: McpCapabilities?

    /// Session management capabilities
    public let sessionCapabilities: SessionCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates agent capabilities.
    ///
    /// - Parameters:
    ///   - loadSession: Load session support
    ///   - promptCapabilities: Prompt capabilities
    ///   - mcpCapabilities: MCP capabilities
    ///   - sessionCapabilities: Session capabilities
    ///   - _meta: Optional metadata
    public init(
        loadSession: Bool = false,
        promptCapabilities: PromptCapabilities = PromptCapabilities(),
        mcpCapabilities: McpCapabilities? = nil,
        sessionCapabilities: SessionCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.loadSession = loadSession
        self.promptCapabilities = promptCapabilities
        self.mcpCapabilities = mcpCapabilities
        self.sessionCapabilities = sessionCapabilities
        self._meta = _meta
    }

    // Custom decoder to provide defaults for missing fields (protocol compatibility)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.loadSession = try container.decodeIfPresent(Bool.self, forKey: .loadSession) ?? false
        self.promptCapabilities = try container.decodeIfPresent(PromptCapabilities.self, forKey: .promptCapabilities) ?? PromptCapabilities()
        self.mcpCapabilities = try container.decodeIfPresent(McpCapabilities.self, forKey: .mcpCapabilities)
        self.sessionCapabilities = try container.decodeIfPresent(SessionCapabilities.self, forKey: .sessionCapabilities)
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    private enum CodingKeys: String, CodingKey {
        case loadSession, promptCapabilities, mcpCapabilities, sessionCapabilities, _meta
    }
}
