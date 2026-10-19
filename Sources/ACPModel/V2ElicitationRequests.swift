import Foundation

// MARK: - V2CreateElicitationRequest

/// **UNSTABLE** - Request parameters for the v2 `elicitation/create` method.
///
/// The `mode` is **flattened** into this object: its discriminator, its own fields, and the scope it
/// carries all sit next to `message` on the wire. There is no session id of its own — scope comes from
/// the mode.
public struct V2CreateElicitationRequest: Codable, Sendable, Hashable {
    public let message: String
    public let mode: V2ElicitationMode
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        message: String,
        mode: V2ElicitationMode,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.message = message
        self.mode = mode
        self._meta = _meta
    }

    private static let ownKeys: Set<String> = ["message", "_meta"]

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        guard case .string(let msg) = raw["message"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Missing 'message' in V2CreateElicitationRequest"
            )
        }
        self.message = msg
        let modeDict = JsonValue.object(raw.filter { !Self.ownKeys.contains($0.key) })
        guard let modeData = try? JSONEncoder().encode(modeDict),
              let mode = try? JSONDecoder().decode(V2ElicitationMode.self, from: modeData) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Failed to decode V2ElicitationMode in V2CreateElicitationRequest"
            )
        }
        self.mode = mode
        if let metaRaw = raw["_meta"],
           let metaData = try? JSONEncoder().encode(metaRaw),
           let meta = try? JSONDecoder().decode(MetaField.self, from: metaData) {
            self._meta = meta
        } else {
            self._meta = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        let modeData = try JSONEncoder().encode(mode)
        guard let modeJsonValue = try? JSONDecoder().decode(JsonValue.self, from: modeData),
              case .object(var fields) = modeJsonValue else {
            throw EncodingError.invalidValue(
                mode,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "V2ElicitationMode must encode as object")
            )
        }
        fields["message"] = .string(message)
        if let meta = _meta,
           let metaData = try? JSONEncoder().encode(meta),
           let metaJsonValue = try? JSONDecoder().decode(JsonValue.self, from: metaData) {
            fields["_meta"] = metaJsonValue
        }
        var c = encoder.singleValueContainer()
        try c.encode(JsonValue.object(fields))
    }
}

// MARK: - V2CreateElicitationResponse

/// **UNSTABLE** - Response to the v2 `elicitation/create` method.
///
/// The `action` is flattened in the same way: `action` and whatever it carries sit at the top level.
public struct V2CreateElicitationResponse: Codable, Sendable, Hashable {
    public let action: V2ElicitationAction
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        action: V2ElicitationAction,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.action = action
        self._meta = _meta
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: JsonValue].self)
        let actionDict = JsonValue.object(raw.filter { $0.key != "_meta" })
        guard let actionData = try? JSONEncoder().encode(actionDict),
              let action = try? JSONDecoder().decode(V2ElicitationAction.self, from: actionData) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Failed to decode V2ElicitationAction in V2CreateElicitationResponse"
            )
        }
        self.action = action
        if let metaRaw = raw["_meta"],
           let metaData = try? JSONEncoder().encode(metaRaw),
           let meta = try? JSONDecoder().decode(MetaField.self, from: metaData) {
            self._meta = meta
        } else {
            self._meta = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        let actionData = try JSONEncoder().encode(action)
        guard let actionJsonValue = try? JSONDecoder().decode(JsonValue.self, from: actionData),
              case .object(var fields) = actionJsonValue else {
            throw EncodingError.invalidValue(
                action,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "V2ElicitationAction must encode as object")
            )
        }
        if let meta = _meta,
           let metaData = try? JSONEncoder().encode(meta),
           let metaJsonValue = try? JSONDecoder().decode(JsonValue.self, from: metaData) {
            fields["_meta"] = metaJsonValue
        }
        var c = encoder.singleValueContainer()
        try c.encode(JsonValue.object(fields))
    }
}

// MARK: - V2CompleteElicitationNotification

/// **UNSTABLE** - The v2 `elicitation/complete` notification: a URL-based elicitation has finished.
///
/// Sent by the agent for the `url` mode flow, where the user acts outside the client and the
/// client would otherwise have no way to know the form is done.
public struct V2CompleteElicitationNotification: Codable, Sendable, Hashable {
    public let elicitationId: ElicitationId
    public let _meta: MetaField? // swiftlint:disable:this identifier_name

    public init(
        elicitationId: ElicitationId,
        _meta: MetaField? = nil // swiftlint:disable:this identifier_name
    ) {
        self.elicitationId = elicitationId
        self._meta = _meta
    }
}
