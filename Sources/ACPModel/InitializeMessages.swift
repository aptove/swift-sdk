import Foundation

/// Request parameters for the initialize method.
///
/// Sent by the client to establish connection and negotiate capabilities.
///
/// See protocol docs: [Initialization](https://agentclientprotocol.com/protocol/initialization)
public struct InitializeRequest: AcpRequest, Codable, Sendable, Hashable {
    /// Protocol version supported by the client
    public let protocolVersion: ProtocolVersion

    /// Capabilities advertised by the client
    public let clientCapabilities: ClientCapabilities

    /// Client implementation information
    public let clientInfo: Implementation?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an initialize request.
    ///
    /// - Parameters:
    ///   - protocolVersion: Protocol version
    ///   - clientCapabilities: Client capabilities
    ///   - clientInfo: Client implementation info
    ///   - _meta: Optional metadata
    public init(
        protocolVersion: ProtocolVersion,
        clientCapabilities: ClientCapabilities = ClientCapabilities(),
        clientInfo: Implementation? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.protocolVersion = protocolVersion
        self.clientCapabilities = clientCapabilities
        self.clientInfo = clientInfo
        self._meta = _meta
    }
}

/// Response from the initialize method.
///
/// Contains the negotiated protocol version and agent capabilities.
///
/// See protocol docs: [Initialization](https://agentclientprotocol.com/protocol/initialization)
public struct InitializeResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Negotiated protocol version
    public let protocolVersion: ProtocolVersion

    /// Capabilities advertised by the agent
    public let agentCapabilities: AgentCapabilities

    /// Available authentication methods
    public let authMethods: [String]

    /// Agent implementation information
    public let agentInfo: Implementation?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates an initialize response.
    ///
    /// - Parameters:
    ///   - protocolVersion: Negotiated protocol version
    ///   - agentCapabilities: Agent capabilities
    ///   - authMethods: Authentication methods
    ///   - agentInfo: Agent implementation info
    ///   - _meta: Optional metadata
    public init(
        protocolVersion: ProtocolVersion,
        agentCapabilities: AgentCapabilities = AgentCapabilities(),
        authMethods: [String] = [],
        agentInfo: Implementation? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.protocolVersion = protocolVersion
        self.agentCapabilities = agentCapabilities
        self.authMethods = authMethods
        self.agentInfo = agentInfo
        self._meta = _meta
    }
}

/// Client information for initialization.
///
/// Contains client metadata and capabilities sent during initialization.
public struct ClientInfo: Codable, Sendable, Hashable {
    /// Protocol version supported by the client
    public let protocolVersion: ProtocolVersion

    /// Capabilities advertised by the client
    public let capabilities: ClientCapabilities

    /// Client implementation information
    public let implementation: Implementation?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates client info.
    ///
    /// - Parameters:
    ///   - protocolVersion: Protocol version
    ///   - capabilities: Client capabilities
    ///   - implementation: Implementation info
    ///   - _meta: Optional metadata
    public init(
        protocolVersion: ProtocolVersion = .current,
        capabilities: ClientCapabilities = ClientCapabilities(),
        implementation: Implementation? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.implementation = implementation
        self._meta = _meta
    }
}

/// Agent information from initialization.
///
/// Contains agent metadata and capabilities received during initialization.
public struct AgentInfo: Codable, Sendable, Hashable {
    /// Protocol version supported by the agent
    public let protocolVersion: ProtocolVersion

    /// Capabilities advertised by the agent
    public let capabilities: AgentCapabilities

    /// Available authentication methods
    public let authMethods: [String]

    /// Agent implementation information
    public let implementation: Implementation?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates agent info.
    ///
    /// - Parameters:
    ///   - protocolVersion: Protocol version
    ///   - capabilities: Agent capabilities
    ///   - authMethods: Authentication methods
    ///   - implementation: Implementation info
    ///   - _meta: Optional metadata
    public init(
        protocolVersion: ProtocolVersion = .current,
        capabilities: AgentCapabilities = AgentCapabilities(),
        authMethods: [String] = [],
        implementation: Implementation? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.authMethods = authMethods
        self.implementation = implementation
        self._meta = _meta
    }
}
