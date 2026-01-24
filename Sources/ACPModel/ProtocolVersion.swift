import Foundation

/// A protocol version number.
///
/// ACP uses integer version numbers for protocol negotiation.
/// Version 1 is the current stable version.
public struct ProtocolVersion: Hashable, Codable, Sendable {
    public let version: Int

    /// Creates a protocol version.
    ///
    /// - Parameter version: The protocol version number
    public init(version: Int) {
        self.version = version
    }

    /// The current ACP protocol version supported by this SDK.
    public static let current = ProtocolVersion(version: 1)

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.version = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(version)
    }
}

// MARK: - CustomStringConvertible

extension ProtocolVersion: CustomStringConvertible {
    public var description: String {
        "\(version)"
    }
}

// MARK: - Comparable

extension ProtocolVersion: Comparable {
    public static func < (lhs: ProtocolVersion, rhs: ProtocolVersion) -> Bool {
        return lhs.version < rhs.version
    }
}
