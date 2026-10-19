import Foundation

// MARK: - V2PromptImageCapabilities

/// **UNSTABLE** - Capabilities for image content in prompt requests.
///
/// Supplying `{}` means the agent supports image content blocks in prompts.
public struct V2PromptImageCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2PromptAudioCapabilities

/// **UNSTABLE** - Capabilities for audio content in prompt requests.
///
/// Supplying `{}` means the agent supports audio content blocks in prompts.
public struct V2PromptAudioCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2PromptEmbeddedContextCapabilities

/// **UNSTABLE** - Capabilities for embedded context in prompt requests.
///
/// Supplying `{}` means the agent supports resource content blocks in prompts.
public struct V2PromptEmbeddedContextCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2PromptCapabilities

/// **UNSTABLE** - Prompt capabilities supported by the agent in session/prompt requests.
///
/// A `null` (or omitted) value means unsupported; `{}` means supported. Test with `!= nil`,
/// never with truthiness — an explicit `null` on the wire is a legal "unsupported" encoding.
public struct V2PromptCapabilities: Codable, Sendable, Hashable {
    public let image: V2PromptImageCapabilities?
    public let audio: V2PromptAudioCapabilities?
    public let embeddedContext: V2PromptEmbeddedContextCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        image: V2PromptImageCapabilities? = nil,
        audio: V2PromptAudioCapabilities? = nil,
        embeddedContext: V2PromptEmbeddedContextCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.image = image
        self.audio = audio
        self.embeddedContext = embeddedContext
        self._meta = _meta
    }
}

// MARK: - V2McpStdioCapabilities

/// **UNSTABLE** - Capabilities for stdio MCP server transports.
///
/// Supplying `{}` means the agent supports stdio MCP servers.
public struct V2McpStdioCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2McpHttpCapabilities

/// **UNSTABLE** - Capabilities for HTTP MCP server transports.
///
/// Supplying `{}` means the agent supports HTTP MCP servers.
public struct V2McpHttpCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2McpAcpCapabilities

/// **UNSTABLE** - Capabilities for ACP MCP server transports.
///
/// Supplying `{}` means the agent supports MCP-over-ACP server transports.
public struct V2McpAcpCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2McpCapabilities

/// **UNSTABLE** - MCP capabilities supported by the agent.
public struct V2McpCapabilities: Codable, Sendable, Hashable {
    public let stdio: V2McpStdioCapabilities?
    public let http: V2McpHttpCapabilities?
    public let acp: V2McpAcpCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        stdio: V2McpStdioCapabilities? = nil,
        http: V2McpHttpCapabilities? = nil,
        acp: V2McpAcpCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.stdio = stdio
        self.http = http
        self.acp = acp
        self._meta = _meta
    }
}

// MARK: - V2SessionDeleteCapabilities

/// **UNSTABLE** - Capabilities for the `session/delete` method.
///
/// Supplying `{}` means the agent supports deleting sessions returned by `session/list`.
public struct V2SessionDeleteCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2SessionCapabilities

/// **UNSTABLE** - Session capabilities supported by the agent.
///
/// Supplying `{}` commits the agent to the baseline session methods.
public struct V2SessionCapabilities: Codable, Sendable, Hashable {
    public let prompt: V2PromptCapabilities?
    public let mcp: V2McpCapabilities?
    public let delete: V2SessionDeleteCapabilities?
    public let additionalDirectories: SessionAdditionalDirectoriesCapabilities?
    public let fork: SessionForkCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        prompt: V2PromptCapabilities? = nil,
        mcp: V2McpCapabilities? = nil,
        delete: V2SessionDeleteCapabilities? = nil,
        additionalDirectories: SessionAdditionalDirectoriesCapabilities? = nil,
        fork: SessionForkCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.prompt = prompt
        self.mcp = mcp
        self.delete = delete
        self.additionalDirectories = additionalDirectories
        self.fork = fork
        self._meta = _meta
    }
}

// MARK: - V2AgentAuthCapabilities

/// **UNSTABLE** - Authentication-related extension capabilities supported by the agent.
///
/// Unlike v1, this object does not advertise support for `auth/login` or `auth/logout`
/// — those methods are advertised by a non-empty `authMethods` list in the initialize
/// response instead.
public struct V2AgentAuthCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2AgentCapabilities

/// **UNSTABLE** - Capabilities supported by the agent.
///
/// Unlike v1, everything session-scoped is nested under `session`, and `session` itself is
/// optional: omitted or `null` means the agent does not support the session method surface
/// at all.
public struct V2AgentCapabilities: Codable, Sendable, Hashable {
    public let session: V2SessionCapabilities?
    public let auth: V2AgentAuthCapabilities?
    public let providers: ProvidersCapabilities?
    public let nes: NesCapabilities?
    public let positionEncoding: NesPositionEncodingKind?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        session: V2SessionCapabilities? = nil,
        auth: V2AgentAuthCapabilities? = nil,
        providers: ProvidersCapabilities? = nil,
        nes: NesCapabilities? = nil,
        positionEncoding: NesPositionEncodingKind? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.session = session
        self.auth = auth
        self.providers = providers
        self.nes = nes
        self.positionEncoding = positionEncoding
        self._meta = _meta
    }
}

// MARK: - V2TerminalAuthCapabilities

/// **UNSTABLE** - Capabilities for terminal authentication methods.
///
/// Supplying `{}` means the client can reproduce the configured agent invocation in an
/// interactive terminal, and so the agent may offer terminal auth methods.
public struct V2TerminalAuthCapabilities: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2AuthCapabilities

/// **UNSTABLE** - Authentication capabilities supported by the client.
///
/// Determines which authentication method types the agent may include in its initialize response.
public struct V2AuthCapabilities: Codable, Sendable, Hashable {
    public let terminal: V2TerminalAuthCapabilities?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        terminal: V2TerminalAuthCapabilities? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.terminal = terminal
        self._meta = _meta
    }
}

// MARK: - V2ClientCapabilities

/// **UNSTABLE** - Capabilities supported by the client.
///
/// Advertised during initialization to inform the agent about available features and methods.
public struct V2ClientCapabilities: Codable, Sendable, Hashable {
    public let auth: V2AuthCapabilities?
    public let elicitation: ElicitationCapabilities?
    public let nes: ClientNesCapabilities?
    public let positionEncodings: [NesPositionEncodingKind]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        auth: V2AuthCapabilities? = nil,
        elicitation: ElicitationCapabilities? = nil,
        nes: ClientNesCapabilities? = nil,
        positionEncodings: [NesPositionEncodingKind] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.auth = auth
        self.elicitation = elicitation
        self.nes = nes
        self.positionEncodings = positionEncodings
        self._meta = _meta
    }
}
