import Foundation

// MARK: - Set Session Model Request

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request to change the model used by a session.
///
/// Allows clients to switch between available models during a session.
public struct SetSessionModelRequest: AcpRequest, AcpWithSessionId, Codable, Sendable, Hashable {
    /// The session to change the model for
    public let sessionId: SessionId

    /// The model to switch to
    public let modelId: ModelId

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a set session model request.
    ///
    /// - Parameters:
    ///   - sessionId: The session identifier
    ///   - modelId: The model to switch to
    ///   - _meta: Optional metadata
    public init(
        sessionId: SessionId,
        modelId: ModelId,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.modelId = modelId
        self._meta = _meta
    }
}

// MARK: - Set Session Model Response

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to a set session model request.
///
/// Confirms that the model change request was received.
/// The actual model change may be reported via session notifications.
public struct SetSessionModelResponse: AcpResponse, Codable, Sendable, Hashable {
    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a set session model response.
    ///
    /// - Parameter _meta: Optional metadata
    public init(
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self._meta = _meta
    }
}

// MARK: - Set Session Config Option Request

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Request to set a configuration option for a session.
///
/// The value field uses a flattened type+value encoding:
/// - Boolean: `{"type":"boolean","value":true}`
/// - String: `{"value":"code"}` (no type field, backward compatible)
public struct SetSessionConfigOptionRequest: AcpRequest, AcpWithSessionId, Sendable, Hashable {
    /// The session to configure
    public let sessionId: SessionId

    /// The configuration option to set
    public let configId: SessionConfigId

    /// The value to set
    public let value: SessionConfigOptionValue

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a set session config option request.
    ///
    /// - Parameters:
    ///   - sessionId: The session identifier
    ///   - configId: The configuration option identifier
    ///   - value: The value to set
    ///   - _meta: Optional metadata
    public init(
        sessionId: SessionId,
        configId: SessionConfigId,
        value: SessionConfigOptionValue,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.sessionId = sessionId
        self.configId = configId
        self.value = value
        self._meta = _meta
    }
}

extension SetSessionConfigOptionRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case sessionId, configId, type, value, _meta
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(SessionId.self, forKey: .sessionId)
        configId = try container.decode(SessionConfigId.self, forKey: .configId)
        _meta = try container.decodeIfPresent(MetaField.self, forKey: ._meta)

        let typeString = try container.decodeIfPresent(String.self, forKey: .type)
        switch typeString {
        case "boolean":
            let boolVal = try container.decode(Bool.self, forKey: .value)
            value = .bool(boolVal)
        case nil:
            // No type field — backward compatible: decode raw value
            if let boolVal = try? container.decode(Bool.self, forKey: .value) {
                value = .bool(boolVal)
            } else if let strVal = try? container.decode(String.self, forKey: .value) {
                value = .string(strVal)
            } else {
                let raw = try container.decode(JsonValue.self, forKey: .value)
                value = .unknown(raw)
            }
        default:
            // Unknown type - capture for forward compatibility
            let raw = try container.decode(JsonValue.self, forKey: .value)
            value = .unknown(raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(configId, forKey: .configId)
        try container.encodeIfPresent(_meta, forKey: ._meta)
        switch value {
        case .bool(let boolVal):
            try container.encode("boolean", forKey: .type)
            try container.encode(boolVal, forKey: .value)
        case .string(let strVal):
            // No type field for string values — backward compatible
            try container.encode(strVal, forKey: .value)
        case .unknown(let raw):
            try container.encode(raw, forKey: .value)
        }
    }
}

// MARK: - Set Session Config Option Response

/// **UNSTABLE**
///
/// This capability is not part of the spec yet, and may be removed or changed at any point.
///
/// Response to a set session config option request.
///
/// Contains the updated configuration options after the change.
public struct SetSessionConfigOptionResponse: AcpResponse, Codable, Sendable, Hashable {
    /// The updated configuration options
    public let configOptions: [SessionConfigOption]?

    /// Optional metadata
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    /// Creates a set session config option response.
    ///
    /// - Parameters:
    ///   - configOptions: Updated configuration options
    ///   - _meta: Optional metadata
    public init(
        configOptions: [SessionConfigOption]? = nil,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.configOptions = configOptions
        self._meta = _meta
    }
}
