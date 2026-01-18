import Foundation

/// The role of a message participant in a conversation.
public enum Role: String, Codable, Sendable {
    /// A message from the user/client
    case user
    
    /// A message from the agent/assistant
    case agent
}
