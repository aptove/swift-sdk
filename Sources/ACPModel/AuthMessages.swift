import Foundation

// MARK: - Auth Method Types

/// Known authentication method types
public enum AuthMethodType: String, Codable, Sendable {
    case agent
    case envVar = "env_var"
    case terminal
}

// MARK: - Auth Method

/// Describes an available authentication method.
///
/// Authentication methods can be in various formats:
/// - Dictionary format with type, id, name, description
/// - Legacy string format (for backward compatibility)
public enum AuthMethod: Codable, Sendable, Hashable {
    /// Agent-based authentication (default).
    /// Agent handles the auth itself.
    case agent(AgentAuthMethod)

    /// Environment variable-based authentication.
    /// A user can enter a key and a client will pass it to the agent as an env variable.
    case envVar(EnvVarAuthMethod)

    /// Terminal-based authentication.
    /// The client runs an interactive terminal for the user to login via a TUI.
    case terminal(TerminalAuthMethod)

    /// Unknown authentication method for forward compatibility.
    /// Captures any auth method type not recognized by this SDK version.
    case unknown(UnknownAuthMethod)

    /// Legacy string format for backward compatibility
    case legacy(String)

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        // Try to decode as a dictionary first
        if let container = try? decoder.container(keyedBy: AuthMethodCodingKeys.self) {
            let typeString = try? container.decode(String.self, forKey: .type)
            let type = typeString.flatMap { AuthMethodType(rawValue: $0) }

            switch type {
            case .agent, .none:
                // Default to agent if no type specified
                self = .agent(try AgentAuthMethod(from: decoder))
            case .envVar:
                self = .envVar(try EnvVarAuthMethod(from: decoder))
            case .terminal:
                self = .terminal(try TerminalAuthMethod(from: decoder))
            }
        } else {
            // Try to decode as a string (legacy format)
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)
            self = .legacy(stringValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .agent(let method):
            try method.encode(to: encoder)
        case .envVar(let method):
            try method.encode(to: encoder)
        case .terminal(let method):
            try method.encode(to: encoder)
        case .unknown(let method):
            try method.encode(to: encoder)
        case .legacy(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }

    private enum AuthMethodCodingKeys: String, CodingKey {
        case type
        case id
        case name
        case description
    }

    // MARK: - Convenience Properties

    /// The ID of the auth method
    public var id: AuthMethodId? {
        switch self {
        case .agent(let m): return m.id
        case .envVar(let m): return m.id
        case .terminal(let m): return m.id
        case .unknown(let m): return m.id
        case .legacy(let s): return AuthMethodId(value: s)
        }
    }

    /// The name of the auth method
    public var name: String? {
        switch self {
        case .agent(let m): return m.name
        case .envVar(let m): return m.name
        case .terminal(let m): return m.name
        case .unknown(let m): return m.name
        case .legacy(let s): return s
        }
    }
}

// MARK: - Agent Auth Method

/// Agent-based authentication method.
public struct AgentAuthMethod: Codable, Sendable, Hashable {
    public let id: AuthMethodId
    public let name: String
    public let description: String?
    public let type: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: AuthMethodId,
        name: String,
        description: String? = nil,
        type: String? = AuthMethodType.agent.rawValue,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self._meta = _meta
    }
}

// MARK: - EnvVar Auth Method

/// Environment variable-based authentication method.
public struct EnvVarAuthMethod: Codable, Sendable, Hashable {
    public let id: AuthMethodId
    public let name: String
    public let description: String?
    public let type: String
    public let varName: String
    public let link: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: AuthMethodId,
        name: String,
        description: String? = nil,
        varName: String,
        link: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = AuthMethodType.envVar.rawValue
        self.varName = varName
        self.link = link
        self._meta = _meta
    }
}

// MARK: - Terminal Auth Method

/// Terminal-based authentication method.
public struct TerminalAuthMethod: Codable, Sendable, Hashable {
    public let id: AuthMethodId
    public let name: String
    public let description: String?
    public let type: String
    public let args: [String]?
    public let env: [String: String]?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: AuthMethodId,
        name: String,
        description: String? = nil,
        args: [String]? = nil,
        env: [String: String]? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = AuthMethodType.terminal.rawValue
        self.args = args
        self.env = env
        self._meta = _meta
    }
}

// MARK: - Unknown Auth Method

/// Unknown authentication method for forward compatibility.
public struct UnknownAuthMethod: Codable, Sendable, Hashable {
    public let id: AuthMethodId
    public let name: String
    public let description: String?
    public let type: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: AuthMethodId,
        name: String,
        description: String? = nil,
        type: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self._meta = _meta
    }
}

// MARK: - Authenticate Request

/// Request to authenticate with the agent using a specific method.
///
/// Authentication allows clients to prove their identity to the agent
/// using various authentication methods.
public struct AuthenticateRequest: AcpRequest, Codable, Sendable, Hashable {
    /// The authentication method to use
    public let methodId: AuthMethodId

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an authenticate request.
    ///
    /// - Parameters:
    ///   - methodId: The authentication method ID
    ///   - _meta: Optional metadata
    public init(
        methodId: AuthMethodId,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.methodId = methodId
        self._meta = _meta
    }
}

// MARK: - Authenticate Response

/// Response to an authentication request.
///
/// Indicates whether authentication was successful.
public struct AuthenticateResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an authenticate response.
    ///
    /// - Parameter _meta: Optional metadata
    public init(
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self._meta = _meta
    }
}

// MARK: - Auth Method ID

/// A unique identifier for an authentication method.
///
/// Authentication method IDs identify specific authentication
/// mechanisms supported by the agent.
public struct AuthMethodId: Hashable, Codable, Sendable {
    public let value: String

    /// Creates an auth method ID from a string value.
    ///
    /// - Parameter value: The auth method ID string
    public init(value: String) {
        self.value = value
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - CustomStringConvertible

extension AuthMethodId: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - ExpressibleByStringLiteral

extension AuthMethodId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
