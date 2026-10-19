import Foundation

// MARK: - V2LoginAuthRequest

/// **UNSTABLE** - Request parameters for the v2 `auth/login` method.
///
/// v2 splits v1's single `authenticate` into `auth/login` and `auth/logout`.
/// Populating `authMethods` in the initialize response obliges an agent to implement both.
public struct V2LoginAuthRequest: Codable, Sendable, Hashable {
    public let methodId: AuthMethodId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(methodId: AuthMethodId, _meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self.methodId = methodId
        self._meta = _meta
    }
}

// MARK: - V2LoginAuthResponse

/// **UNSTABLE** - Response to the v2 `auth/login` method.
public struct V2LoginAuthResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2LogoutAuthRequest

/// **UNSTABLE** - Request parameters for the v2 `auth/logout` method.
public struct V2LogoutAuthRequest: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2LogoutAuthResponse

/// **UNSTABLE** - Response to the v2 `auth/logout` method.
public struct V2LogoutAuthResponse: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2StatusAuthRequest

/// **UNSTABLE** - Request parameters for the v2 `auth/status` method.
public struct V2StatusAuthRequest: Codable, Sendable, Hashable {
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(_meta: MetaField? = nil) { // swiftlint:disable:this identifier_name
        self._meta = _meta
    }
}

// MARK: - V2StatusAuthResponse

/// **UNSTABLE** - Response to the v2 `auth/status` method.
///
/// Status of configured credentials, which does not guarantee that they are valid.
/// - `message`: optional human-readable explanation of the authentication state.
public struct V2StatusAuthResponse: Codable, Sendable, Hashable {
    public let authenticated: Bool
    public let message: String?
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        authenticated: Bool,
        message: String? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.authenticated = authenticated
        self.message = message
        self._meta = _meta
    }
}
