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

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Plan capabilities supported by the client.
///
/// When present, signals that the client supports `plan_update` and `plan_removed`
/// session update types. When absent, the agent must fall back to the existing
/// `plan` session update type.
public struct PlanCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Authentication capabilities supported by the client or agent.
///
/// Advertised during initialization to inform the other side which authentication
/// method types can be handled.
public struct AuthCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
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

/// Capabilities for deleting sessions from history.
///
/// By supplying `{}` it means that the agent supports the `session/delete` method.
public struct SessionDeleteCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE**: Capabilities for closing sessions.
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
public struct SessionCloseCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session close capabilities.
    ///
    /// - Parameter _meta: Optional metadata
    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE**: Capabilities for additional directories in sessions.
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
public struct SessionAdditionalDirectoriesCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session additional directories capabilities.
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

    /// Delete session capability
    public let delete: SessionDeleteCapabilities?

    /// Close session capability (unstable)
    public let close: SessionCloseCapabilities?

    /// Additional directories capability (unstable)
    public let additionalDirectories: SessionAdditionalDirectoriesCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session capabilities.
    public init(
        fork: SessionForkCapabilities? = nil,
        list: SessionListCapabilities? = nil,
        resume: SessionResumeCapabilities? = nil,
        delete: SessionDeleteCapabilities? = nil,
        close: SessionCloseCapabilities? = nil,
        additionalDirectories: SessionAdditionalDirectoriesCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.fork = fork
        self.list = list
        self.resume = resume
        self.delete = delete
        self.close = close
        self.additionalDirectories = additionalDirectories
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

    /// **UNSTABLE** - Authentication capabilities
    public let auth: AuthCapabilities?

    /// **UNSTABLE** - Plan capabilities
    public let planCapabilities: PlanCapabilities?

    /// **UNSTABLE** - NES (Next Edit Suggestions) capabilities
    public let nes: ClientNesCapabilities?

    /// **UNSTABLE** - Position encodings supported by the client
    public let positionEncodings: [NesPositionEncodingKind]?

    /// **UNSTABLE** - Elicitation capabilities
    public let elicitation: ElicitationCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates client capabilities.
    ///
    /// - Parameters:
    ///   - fs: File system capabilities
    ///   - terminal: Terminal support
    ///   - auth: Authentication capabilities (unstable)
    ///   - planCapabilities: Plan capabilities (unstable)
    ///   - nes: NES capabilities (unstable)
    ///   - positionEncodings: Position encodings supported (unstable)
    ///   - elicitation: Elicitation capabilities (unstable)
    ///   - _meta: Optional metadata
    public init(
        fs: FileSystemCapability? = nil,
        terminal: Bool = false,
        auth: AuthCapabilities? = nil,
        planCapabilities: PlanCapabilities? = nil,
        nes: ClientNesCapabilities? = nil,
        positionEncodings: [NesPositionEncodingKind]? = nil,
        elicitation: ElicitationCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.fs = fs
        self.terminal = terminal
        self.auth = auth
        self.planCapabilities = planCapabilities
        self.nes = nes
        self.positionEncodings = positionEncodings
        self.elicitation = elicitation
        self._meta = _meta
    }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Logout capabilities supported by the agent.
///
/// Supplying an instance means the agent supports the logout method.
public struct LogoutCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Authentication-related capabilities supported by the agent.
public struct AgentAuthCapabilities: Codable, Sendable, Hashable {
    /// Whether the agent supports the logout method
    public let logout: LogoutCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        logout: LogoutCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.logout = logout
        self._meta = _meta
    }
}

/// **UNSTABLE** - Provider configuration capabilities supported by the agent.
///
/// By supplying `{}` it means that the agent supports provider configuration methods.
public struct ProvidersCapabilities: Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
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

    /// **UNSTABLE** - Authentication-related capabilities
    public let auth: AgentAuthCapabilities?

    /// **UNSTABLE** - NES (Next Edit Suggestions) capabilities
    public let nes: NesCapabilities?

    /// **UNSTABLE** - Position encoding preferred by the agent
    public let positionEncoding: NesPositionEncodingKind?

    /// **UNSTABLE** - Provider configuration capabilities
    public let providers: ProvidersCapabilities?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates agent capabilities.
    ///
    /// - Parameters:
    ///   - loadSession: Load session support
    ///   - promptCapabilities: Prompt capabilities
    ///   - mcpCapabilities: MCP capabilities
    ///   - sessionCapabilities: Session capabilities
    ///   - auth: Authentication capabilities (unstable)
    ///   - nes: NES capabilities (unstable)
    ///   - positionEncoding: Position encoding (unstable)
    ///   - providers: Provider configuration capabilities (unstable)
    ///   - _meta: Optional metadata
    public init(
        loadSession: Bool = false,
        promptCapabilities: PromptCapabilities = PromptCapabilities(),
        mcpCapabilities: McpCapabilities? = nil,
        sessionCapabilities: SessionCapabilities? = nil,
        auth: AgentAuthCapabilities? = nil,
        nes: NesCapabilities? = nil,
        positionEncoding: NesPositionEncodingKind? = nil,
        providers: ProvidersCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.loadSession = loadSession
        self.promptCapabilities = promptCapabilities
        self.mcpCapabilities = mcpCapabilities
        self.sessionCapabilities = sessionCapabilities
        self.auth = auth
        self.nes = nes
        self.positionEncoding = positionEncoding
        self.providers = providers
        self._meta = _meta
    }

    // Custom decoder to provide defaults for missing fields (protocol compatibility)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.loadSession = try container.decodeIfPresent(Bool.self, forKey: .loadSession) ?? false
        self.promptCapabilities = try container.decodeIfPresent(PromptCapabilities.self, forKey: .promptCapabilities) ?? PromptCapabilities()
        self.mcpCapabilities = try container.decodeIfPresent(McpCapabilities.self, forKey: .mcpCapabilities)
        self.sessionCapabilities = try container.decodeIfPresent(SessionCapabilities.self, forKey: .sessionCapabilities)
        self.auth = try container.decodeIfPresent(AgentAuthCapabilities.self, forKey: .auth)
        self.nes = try container.decodeIfPresent(NesCapabilities.self, forKey: .nes)
        self.positionEncoding = try container.decodeIfPresent(NesPositionEncodingKind.self, forKey: .positionEncoding)
        self.providers = try container.decodeIfPresent(ProvidersCapabilities.self, forKey: .providers)
        self._meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
    }

    private enum CodingKeys: String, CodingKey {
        case loadSession, promptCapabilities, mcpCapabilities, sessionCapabilities, auth, nes, positionEncoding, providers, _meta
    }
}
