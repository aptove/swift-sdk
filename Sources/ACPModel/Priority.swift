import Foundation

/// Priority level for messages or operations.
public enum Priority: String, Codable, Sendable {
    case low
    case normal
    case high
}
