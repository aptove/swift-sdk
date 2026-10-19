import Foundation

// MARK: - V2InitializeRequest

/// **UNSTABLE** - Request parameters for the `initialize` method (v2).
///
/// Sent by the client to establish connection and negotiate capabilities.
public struct V2InitializeRequest: Codable, Sendable, Hashable {
    public let protocolVersion: ProtocolVersion
    public let info: Implementation
    public let capabilities: V2ClientCapabilities
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        protocolVersion: ProtocolVersion,
        info: Implementation,
        capabilities: V2ClientCapabilities = V2ClientCapabilities(),
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.protocolVersion = protocolVersion
        self.info = info
        self.capabilities = capabilities
        self._meta = _meta
    }
}

// MARK: - V2InitializeResponse

/// **UNSTABLE** - Response from the `initialize` method (v2).
///
/// Contains the negotiated protocol version and agent capabilities.
///
/// A non-empty `authMethods` list means the agent implements both `auth/login` and
/// `auth/logout`. An omitted or empty list means clients must not call either.
public struct V2InitializeResponse: Codable, Sendable, Hashable {
    public let protocolVersion: ProtocolVersion
    public let info: Implementation
    public let capabilities: V2AgentCapabilities
    public let authMethods: [V2AuthMethod]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        protocolVersion: ProtocolVersion,
        info: Implementation,
        capabilities: V2AgentCapabilities = V2AgentCapabilities(),
        authMethods: [V2AuthMethod] = [],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.protocolVersion = protocolVersion
        self.info = info
        self.capabilities = capabilities
        self.authMethods = authMethods
        self._meta = _meta
    }
}

// MARK: - V2PermissionOptionKind

/// **UNSTABLE** - The type of permission option being presented to the user.
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2PermissionOptionKind: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let allowOnce = V2PermissionOptionKind(rawValue: "allow_once")
    public static let allowAlways = V2PermissionOptionKind(rawValue: "allow_always")
    public static let rejectOnce = V2PermissionOptionKind(rawValue: "reject_once")
    public static let rejectAlways = V2PermissionOptionKind(rawValue: "reject_always")
}

// MARK: - V2LlmProtocol

/// **UNSTABLE** - Well-known API protocol identifiers for LLM providers (v2 open enum).
///
/// Open string enum: unrecognized values are preserved via `rawValue`.
public struct V2LlmProtocol: Codable, Sendable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
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

    public static let anthropic = V2LlmProtocol(rawValue: "anthropic")
    public static let openai = V2LlmProtocol(rawValue: "openai")
    public static let azure = V2LlmProtocol(rawValue: "azure")
    public static let vertex = V2LlmProtocol(rawValue: "vertex")
    public static let bedrock = V2LlmProtocol(rawValue: "bedrock")
}

extension V2LlmProtocol: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - V2AuthMethod

/// **UNSTABLE** - Describes an available authentication method (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2AuthMethod: Codable, Sendable, Hashable {
    case agent(Agent)
    case envVar(EnvVar)
    case terminal(Terminal)
    case unknown(type: String, methodId: AuthMethodId, name: String, description: String?, rawJson: [String: JsonValue])

    public struct Agent: Codable, Sendable, Hashable {
        public let methodId: AuthMethodId
        public let name: String
        public let description: String?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(methodId: AuthMethodId, name: String, description: String? = nil, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.methodId = methodId
            self.name = name
            self.description = description
            self._meta = _meta
        }
    }

    public struct EnvVar: Codable, Sendable, Hashable {
        public let methodId: AuthMethodId
        public let name: String
        public let description: String?
        public let vars: [AuthEnvVar]
        public let link: String?
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(
            methodId: AuthMethodId,
            name: String,
            description: String? = nil,
            vars: [AuthEnvVar],
            link: String? = nil,
            _meta: MetaField? = nil // swiftlint:disable:this identifier_name
        ) {
            self.methodId = methodId
            self.name = name
            self.description = description
            self.vars = vars
            self.link = link
            self._meta = _meta
        }
    }

    public struct Terminal: Codable, Sendable, Hashable {
        public let methodId: AuthMethodId
        public let name: String
        public let description: String?
        public let args: [String]
        public let env: [EnvVariable]
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(
            methodId: AuthMethodId,
            name: String,
            description: String? = nil,
            args: [String] = [],
            env: [EnvVariable] = [],
            _meta: MetaField? = nil // swiftlint:disable:this identifier_name
        ) {
            self.methodId = methodId
            self.name = name
            self.description = description
            self.args = args
            self.env = env
            self._meta = _meta
        }
    }

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "agent":
            self = .agent(try Agent(from: decoder))
        case "env_var":
            self = .envVar(try EnvVar(from: decoder))
        case "terminal":
            self = .terminal(try Terminal(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            guard case .string(let methodIdStr) = raw["methodId"] else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Missing 'methodId' in unknown AuthMethod"
                )
            }
            guard case .string(let nameStr) = raw["name"] else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Missing 'name' in unknown AuthMethod"
                )
            }
            var desc: String?
            if case .string(let d) = raw["description"] { desc = d }
            self = .unknown(
                type: typeStr,
                methodId: AuthMethodId(value: methodIdStr),
                name: nameStr,
                description: desc,
                rawJson: raw
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .agent(let v):
            try typeContainer.encode("agent", forKey: .type)
            try v.encode(to: encoder)
        case .envVar(let v):
            try typeContainer.encode("env_var", forKey: .type)
            try v.encode(to: encoder)
        case .terminal(let v):
            try typeContainer.encode("terminal", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, _, _, _, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2McpServer

/// **UNSTABLE** - Configuration for connecting to an MCP server (v2).
///
/// Open tagged union discriminated by `type`. Unknown types preserve the raw JSON.
public enum V2McpServer: Codable, Sendable, Hashable {
    case http(Http)
    case stdio(Stdio)
    case unknown(type: String, rawJson: [String: JsonValue])

    public struct Http: Codable, Sendable, Hashable {
        public let name: String
        public let url: String
        public let headers: [HttpHeader]
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(name: String, url: String, headers: [HttpHeader] = [], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.name = name
            self.url = url
            self.headers = headers
            self._meta = _meta
        }
    }

    public struct Stdio: Codable, Sendable, Hashable {
        public let name: String
        public let command: String
        public let args: [String]
        public let env: [EnvVariable]
        public let _meta: MetaField? // swiftlint:disable:this identifier_name

        public init(name: String, command: String, args: [String] = [], env: [EnvVariable] = [], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
            self.name = name
            self.command = command
            self.args = args
            self.env = env
            self._meta = _meta
        }
    }

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: TypeKey.self)
        let typeStr = try typeContainer.decode(String.self, forKey: .type)
        switch typeStr {
        case "http":
            self = .http(try Http(from: decoder))
        case "stdio":
            self = .stdio(try Stdio(from: decoder))
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(type: typeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var typeContainer = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .http(let v):
            try typeContainer.encode("http", forKey: .type)
            try v.encode(to: encoder)
        case .stdio(let v):
            try typeContainer.encode("stdio", forKey: .type)
            try v.encode(to: encoder)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}

// MARK: - V2RequestPermissionOutcome

/// **UNSTABLE** - The outcome of a permission request (v2).
///
/// Open tagged union discriminated by `outcome`. Unknown types preserve the raw JSON.
public enum V2RequestPermissionOutcome: Codable, Sendable, Hashable {
    case cancelled
    case selected(optionId: PermissionOptionId, _meta: MetaField?) // swiftlint:disable:this identifier_name
    case unknown(outcome: String, rawJson: [String: JsonValue])

    private enum OutcomeKey: String, CodingKey { case outcome }
    private enum SelectedKeys: String, CodingKey { case outcome, optionId, _meta } // swiftlint:disable:this identifier_name

    public init(from decoder: Decoder) throws {
        let outcomeContainer = try decoder.container(keyedBy: OutcomeKey.self)
        let outcomeStr = try outcomeContainer.decode(String.self, forKey: .outcome)
        switch outcomeStr {
        case "cancelled":
            self = .cancelled
        case "selected":
            let container = try decoder.container(keyedBy: SelectedKeys.self)
            let optionId = try container.decode(PermissionOptionId.self, forKey: .optionId)
            let meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)
            self = .selected(optionId: optionId, _meta: meta)
        default:
            let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
            self = .unknown(outcome: outcomeStr, rawJson: raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .cancelled:
            var c = encoder.container(keyedBy: OutcomeKey.self)
            try c.encode("cancelled", forKey: .outcome)
        case .selected(let optionId, let meta):
            var c = encoder.container(keyedBy: SelectedKeys.self)
            try c.encode("selected", forKey: .outcome)
            try c.encode(optionId, forKey: .optionId)
            try c.encodeIfPresent(meta, forKey: ._meta)
        case .unknown(_, let raw):
            var c = encoder.singleValueContainer()
            try c.encode(raw)
        }
    }
}
