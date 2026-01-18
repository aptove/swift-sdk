import Foundation

/// A semantic version number following the semver specification.
///
/// Protocol versions use semantic versioning to indicate compatibility
/// and feature availability between clients and agents.
public struct ProtocolVersion: Hashable, Codable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    /// Creates a protocol version.
    ///
    /// - Parameters:
    ///   - major: Major version number (breaking changes)
    ///   - minor: Minor version number (backward-compatible features)
    ///   - patch: Patch version number (backward-compatible fixes)
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Creates a protocol version from a string in the format "major.minor.patch".
    ///
    /// - Parameter string: The version string
    /// - Returns: A protocol version, or nil if the string is invalid
    public init?(string: String) {
        let components = string.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3 else { return nil }

        self.major = components[0]
        self.minor = components[1]
        self.patch = components[2]
    }

    /// The current ACP protocol version supported by this SDK.
    public static let current = ProtocolVersion(major: 0, minor: 9, patch: 1)

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let versionString = try container.decode(String.self)

        guard let version = ProtocolVersion(string: versionString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid version format: \(versionString). Expected format: major.minor.patch"
            )
        }

        self = version
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(major).\(minor).\(patch)")
    }
}

// MARK: - CustomStringConvertible

extension ProtocolVersion: CustomStringConvertible {
    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}

// MARK: - Comparable

extension ProtocolVersion: Comparable {
    public static func < (lhs: ProtocolVersion, rhs: ProtocolVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}
