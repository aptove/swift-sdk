import Foundation

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
