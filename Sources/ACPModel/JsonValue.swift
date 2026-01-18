import Foundation

/// A type-erased JSON value for dynamic JSON handling.
///
/// This type is used when the exact JSON structure is not known at compile time,
/// such as for tool parameters, error data, or extensible fields.
public enum JsonValue: Codable, Sendable, Hashable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JsonValue])
    case object([String: JsonValue])
    
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JsonValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JsonValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode JsonValue"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Convenience Accessors

extension JsonValue {
    /// Returns the value as a Boolean if it is a Boolean, nil otherwise.
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
    
    /// Returns the value as an Int if it is an Int, nil otherwise.
    public var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
    
    /// Returns the value as a Double if it is a Double or Int, nil otherwise.
    public var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }
    
    /// Returns the value as a String if it is a String, nil otherwise.
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    /// Returns the value as an Array if it is an Array, nil otherwise.
    public var arrayValue: [JsonValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
    
    /// Returns the value as an Object if it is an Object, nil otherwise.
    public var objectValue: [String: JsonValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
    
    /// Returns true if the value is null.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

// MARK: - ExpressibleBy Literals

extension JsonValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JsonValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JsonValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension JsonValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension JsonValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JsonValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JsonValue...) {
        self = .array(elements)
    }
}

extension JsonValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JsonValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}
