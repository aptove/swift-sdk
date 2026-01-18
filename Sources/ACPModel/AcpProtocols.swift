import Foundation

/// Base protocol for all ACP request messages.
///
/// ACP requests are messages that expect a response. They are sent via
/// JSON-RPC and include a request ID for correlation.
public protocol AcpRequest: Codable, Sendable {
    /// The associated response type for this request
    associatedtype Response: AcpResponse
    
    /// The ACP method name for this request
    static var method: String { get }
}

/// Base protocol for all ACP response messages.
///
/// ACP responses are returned in reply to requests and contain the
/// result of the requested operation.
public protocol AcpResponse: Codable, Sendable {
}

/// Base protocol for all ACP notification messages.
///
/// ACP notifications are one-way messages that do not expect a response.
/// They are used for events and streaming updates.
public protocol AcpNotification: Codable, Sendable {
    /// The ACP method name for this notification
    static var method: String { get }
}

/// Protocol for messages that include a session ID.
///
/// Many ACP operations are scoped to a specific session and include
/// the session ID in their payload.
public protocol AcpWithSessionId {
    /// The session identifier
    var sessionId: SessionId { get }
}

/// Protocol for messages that can include metadata.
///
/// The `_meta` field is used for extensible metadata that doesn't
/// fit into the standard message structure.
public protocol AcpWithMeta {
    /// Optional metadata
    var _meta: MetaField? { get }
}

/// Metadata that can be attached to ACP messages.
///
/// The meta field provides a standardized way to attach additional
/// information to messages without breaking protocol compatibility.
public struct MetaField: Codable, Sendable, Hashable {
    /// Progress information for long-running operations
    public var progressToken: String?
    
    /// Additional arbitrary metadata
    public var additionalData: [String: JsonValue]
    
    /// Creates metadata.
    ///
    /// - Parameters:
    ///   - progressToken: Progress tracking token
    ///   - additionalData: Additional key-value data
    public init(progressToken: String? = nil, additionalData: [String: JsonValue] = [:]) {
        self.progressToken = progressToken
        self.additionalData = additionalData
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case progressToken
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        progressToken = try container.decodeIfPresent(String.self, forKey: .progressToken)
        
        // Decode additional data from remaining keys
        let allKeys = container.allKeys
        var additionalData: [String: JsonValue] = [:]
        
        for key in allKeys where key != .progressToken {
            if let value = try? decoder.singleValueContainer().decode(JsonValue.self) {
                additionalData[key.stringValue] = value
            }
        }
        
        self.additionalData = additionalData
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(progressToken, forKey: .progressToken)
        
        // Encode additional data
        for (key, value) in additionalData {
            let dynamicKey = DynamicCodingKey(stringValue: key)
            var nestedContainer = encoder.container(keyedBy: DynamicCodingKey.self)
            try nestedContainer.encode(value, forKey: dynamicKey)
        }
    }
}

/// A dynamic coding key for encoding/decoding arbitrary keys.
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
