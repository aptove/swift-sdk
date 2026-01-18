import Foundation

/// A unique identifier for a JSON-RPC request.
///
/// The ACP protocol supports both integer and string request IDs
/// to maintain compatibility with various JSON-RPC implementations.
public enum RequestId: Hashable, Codable, Sendable {
    case int(Int)
    case string(String)
    
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "RequestId must be either an integer or string"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: - CustomStringConvertible

extension RequestId: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let value):
            return "\(value)"
        case .string(let value):
            return value
        }
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension RequestId: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RequestId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
