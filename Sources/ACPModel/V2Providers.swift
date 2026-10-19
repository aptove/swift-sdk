import Foundation

// MARK: - V2ProviderId

/// **UNSTABLE** - Identifier of a configurable LLM provider.
///
/// A distinct type in v2, where v1 passes the same thing around as a bare `String`.
public struct V2ProviderId: Codable, Sendable, Hashable, ExpressibleByStringLiteral {
    public let value: String

    public init(value: String) { self.value = value }
    public init(stringLiteral value: String) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension V2ProviderId: CustomStringConvertible {
    public var description: String { value }
}

// MARK: - V2ProviderCurrentConfig

/// **UNSTABLE** - The routing a provider is currently using. Secrets are never part of this.
public struct V2ProviderCurrentConfig: Codable, Sendable, Hashable {
    public let apiType: V2LlmProtocol
    public let baseUrl: String
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        apiType: V2LlmProtocol,
        baseUrl: String,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.apiType = apiType
        self.baseUrl = baseUrl
        self._meta = _meta
    }
}

// MARK: - V2ProviderInfo

/// **UNSTABLE** - One configurable provider as reported by `providers/list`.
///
/// `current` absent or `null` means the provider is disabled. `required: true` means it cannot
/// be disabled — a client must not call `providers/disable` for it.
public struct V2ProviderInfo: Codable, Sendable, Hashable {
    public let providerId: V2ProviderId
    public let supported: [V2LlmProtocol]
    public let required: Bool
    public let current: V2ProviderCurrentConfig?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        providerId: V2ProviderId,
        supported: [V2LlmProtocol],
        required: Bool,
        current: V2ProviderCurrentConfig? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.providerId = providerId
        self.supported = supported
        self.required = required
        self.current = current
        self._meta = _meta
    }
}

// MARK: - V2ListProvidersRequest

/// **UNSTABLE** - Request parameters for the v2 `providers/list` method.
public struct V2ListProvidersRequest: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2ListProvidersResponse

/// **UNSTABLE** - Response to the v2 `providers/list` method.
public struct V2ListProvidersResponse: Codable, Sendable, Hashable {
    public let providers: [V2ProviderInfo]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(providers: [V2ProviderInfo], _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.providers = providers
        self._meta = _meta
    }
}

// MARK: - V2SetProviderRequest

/// **UNSTABLE** - Request parameters for the v2 `providers/set` method.
///
/// Unlike v1's `SetProvidersRequest`, this replaces one provider's whole configuration.
/// `headers` is the complete map.
public struct V2SetProviderRequest: Codable, Sendable, Hashable {
    public let providerId: V2ProviderId
    public let apiType: V2LlmProtocol
    public let baseUrl: String
    public let headers: [String: String]
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        providerId: V2ProviderId,
        apiType: V2LlmProtocol,
        baseUrl: String,
        headers: [String: String] = [:],
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.providerId = providerId
        self.apiType = apiType
        self.baseUrl = baseUrl
        self.headers = headers
        self._meta = _meta
    }
}

// MARK: - V2SetProviderResponse

/// **UNSTABLE** - Response to the v2 `providers/set` method.
public struct V2SetProviderResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2DisableProviderRequest

/// **UNSTABLE** - Request parameters for the v2 `providers/disable` method.
public struct V2DisableProviderRequest: Codable, Sendable, Hashable {
    public let providerId: V2ProviderId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(providerId: V2ProviderId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.providerId = providerId
        self._meta = _meta
    }
}

// MARK: - V2DisableProviderResponse

/// **UNSTABLE** - Response to the v2 `providers/disable` method.
public struct V2DisableProviderResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}
