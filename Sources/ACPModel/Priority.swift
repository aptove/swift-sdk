import Foundation

/// Priority level for messages or operations.
public enum Priority: String, Codable, Sendable {
    case low = "low"
    case normal = "normal"
    case high = "high"
}
