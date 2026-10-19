import Foundation

// MARK: - LlmProtocol

/// **UNSTABLE** - Well-known API protocol identifiers for LLM providers.
///
/// Agents and clients MUST handle unknown protocol identifiers gracefully.
public struct LlmProtocol: Codable, Sendable, Hashable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let anthropic = LlmProtocol(rawValue: "anthropic")
    public static let openai = LlmProtocol(rawValue: "openai")
    public static let azure = LlmProtocol(rawValue: "azure")
    public static let vertex = LlmProtocol(rawValue: "vertex")
    public static let bedrock = LlmProtocol(rawValue: "bedrock")

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension LlmProtocol: CustomStringConvertible {
    public var description: String { rawValue }
}

extension LlmProtocol: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

// MARK: - Provider Types

/// **UNSTABLE** - Current effective non-secret routing configuration for a provider.
public struct ProviderCurrentConfig: Codable, Sendable, Hashable {
    public let apiType: LlmProtocol
    public let baseUrl: String

    public init(apiType: LlmProtocol, baseUrl: String) {
        self.apiType = apiType
        self.baseUrl = baseUrl
    }
}

/// **UNSTABLE** - Information about a configurable LLM provider.
public struct ProviderInfo: Codable, Sendable, Hashable {
    public let id: String
    public let supported: [LlmProtocol]
    public let required: Bool
    public let current: ProviderCurrentConfig?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: String,
        supported: [LlmProtocol],
        required: Bool,
        current: ProviderCurrentConfig? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.supported = supported
        self.required = required
        self.current = current
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case id = "providerId"
        case supported, required, current, _meta
    }
}

// MARK: - Providers Requests

/// **UNSTABLE** - Request parameters for `providers/list`.
public struct ListProvidersRequest: AcpRequest, Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE** - Request parameters for `providers/set`.
public struct SetProvidersRequest: AcpRequest, Codable, Sendable, Hashable {
    public let id: String
    public let apiType: LlmProtocol
    public let baseUrl: String
    public let headers: [String: String]?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: String,
        apiType: LlmProtocol,
        baseUrl: String,
        headers: [String: String]? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self.apiType = apiType
        self.baseUrl = baseUrl
        self.headers = headers
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case id = "providerId"
        case apiType, baseUrl, headers, _meta
    }
}

/// **UNSTABLE** - Request parameters for `providers/disable`.
public struct DisableProvidersRequest: AcpRequest, Codable, Sendable, Hashable {
    public let id: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        id: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.id = id
        self._meta = _meta
    }

    private enum CodingKeys: String, CodingKey {
        case id = "providerId"
        case _meta
    }
}

// MARK: - Providers Responses

/// **UNSTABLE** - Response to `providers/list`.
public struct ListProvidersResponse: AcpResponse, Codable, Sendable, Hashable {
    public let providers: [ProviderInfo]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        providers: [ProviderInfo],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.providers = providers
        self._meta = _meta
    }
}

/// **UNSTABLE** - Response to `providers/set`.
public struct SetProvidersResponse: AcpResponse, Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

/// **UNSTABLE** - Response to `providers/disable`.
public struct DisableProvidersResponse: AcpResponse, Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}
