import Foundation

/// An environment variable to set when launching an MCP server.
public struct EnvVariable: Codable, Sendable, Hashable {
    /// Variable name
    public let name: String

    /// Variable value
    public let value: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an environment variable.
    public init(
        name: String,
        value: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.name = name
        self.value = value
        self._meta = _meta
    }
}

/// An HTTP header to set when making requests to the MCP server.
public struct HttpHeader: Codable, Sendable, Hashable {
    /// Header name
    public let name: String

    /// Header value
    public let value: String

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an HTTP header.
    public init(
        name: String,
        value: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.name = name
        self.value = value
        self._meta = _meta
    }
}

/// Configuration for connecting to an MCP (Model Context Protocol) server.
///
/// MCP servers provide tools and context that the agent can use when
/// processing prompts.
///
/// See protocol docs: [MCP Servers](https://agentclientprotocol.com/protocol/session-setup#mcp-servers)
public enum McpServer: Codable, Sendable, Hashable {
    /// Stdio transport configuration (all agents MUST support this)
    case stdio(StdioMcpServer)

    /// HTTP transport configuration (requires mcp_capabilities.http)
    case http(HttpMcpServer)

    /// SSE transport configuration (requires mcp_capabilities.sse)
    case sse(SseMcpServer)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case name = "name"
    }

    private enum ServerType: String, Codable {
        case stdio = "stdio"
        case http = "http"
        case sse = "sse"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ServerType.self, forKey: .type)

        switch type {
        case .stdio:
            self = .stdio(try StdioMcpServer(from: decoder))
        case .http:
            self = .http(try HttpMcpServer(from: decoder))
        case .sse:
            self = .sse(try SseMcpServer(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .stdio(let server):
            try server.encode(to: encoder)
        case .http(let server):
            try server.encode(to: encoder)
        case .sse(let server):
            try server.encode(to: encoder)
        }
    }
}

/// Stdio transport configuration for MCP servers.
public struct StdioMcpServer: Codable, Sendable, Hashable {
    /// Server name
    public let name: String

    /// Command to execute
    public let command: String

    /// Command arguments
    public let args: [String]

    /// Environment variables
    public let env: [EnvVariable]

    /// Creates stdio MCP server configuration.
    public init(
        name: String,
        command: String,
        args: [String],
        env: [EnvVariable]
    ) {
        self.name = name
        self.command = command
        self.args = args
        self.env = env
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case name = "name"
        case command = "command"
        case args = "args"
        case env = "env"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        command = try container.decode(String.self, forKey: .command)
        args = try container.decode([String].self, forKey: .args)
        env = try container.decode([EnvVariable].self, forKey: .env)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("stdio", forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(command, forKey: .command)
        try container.encode(args, forKey: .args)
        try container.encode(env, forKey: .env)
    }
}

/// HTTP transport configuration for MCP servers.
public struct HttpMcpServer: Codable, Sendable, Hashable {
    /// Server name
    public let name: String

    /// Server URL
    public let url: String

    /// HTTP headers
    public let headers: [HttpHeader]

    /// Creates HTTP MCP server configuration.
    public init(
        name: String,
        url: String,
        headers: [HttpHeader]
    ) {
        self.name = name
        self.url = url
        self.headers = headers
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case name = "name"
        case url = "url"
        case headers = "headers"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        headers = try container.decode([HttpHeader].self, forKey: .headers)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("http", forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(headers, forKey: .headers)
    }
}

/// SSE transport configuration for MCP servers.
public struct SseMcpServer: Codable, Sendable, Hashable {
    /// Server name
    public let name: String

    /// Server URL
    public let url: String

    /// HTTP headers
    public let headers: [HttpHeader]

    /// Creates SSE MCP server configuration.
    public init(
        name: String,
        url: String,
        headers: [HttpHeader]
    ) {
        self.name = name
        self.url = url
        self.headers = headers
    }

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case name = "name"
        case url = "url"
        case headers = "headers"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        headers = try container.decode([HttpHeader].self, forKey: .headers)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("sse", forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(headers, forKey: .headers)
    }
}

/// A mode the agent can operate in.
///
/// See protocol docs: [Session Modes](https://agentclientprotocol.com/protocol/session-modes)
public struct SessionMode: Codable, Sendable, Hashable {
    /// Mode ID
    public let id: SessionModeId

    /// Human-readable mode name
    public let name: String

    /// Optional description
    public let description: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a session mode.
    public init(
        id: SessionModeId,
        name: String,
        description: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self._meta = _meta
    }
}

/// The set of modes and the one currently active.
public struct SessionModeState: Codable, Sendable, Hashable {
    /// Currently active mode ID
    public let currentModeId: SessionModeId

    /// Available modes
    public let availableModes: [SessionMode]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session mode state.
    public init(
        currentModeId: SessionModeId,
        availableModes: [SessionMode],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.currentModeId = currentModeId
        self.availableModes = availableModes
        self._meta = _meta
    }
}

/// Information about a selectable model (unstable API).
public struct ModelInfo: Codable, Sendable, Hashable {
    /// Model ID
    public let modelId: ModelId

    /// Human-readable name
    public let name: String

    /// Optional description
    public let description: String?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates model info.
    public init(
        modelId: ModelId,
        name: String,
        description: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.modelId = modelId
        self.name = name
        self.description = description
        self._meta = _meta
    }
}

/// The set of models and the one currently active (unstable API).
public struct SessionModelState: Codable, Sendable, Hashable {
    /// Currently active model ID
    public let currentModelId: ModelId

    /// Available models
    public let availableModels: [ModelInfo]

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates session model state.
    public init(
        currentModelId: ModelId,
        availableModels: [ModelInfo],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.currentModelId = currentModelId
        self.availableModels = availableModels
        self._meta = _meta
    }
}
