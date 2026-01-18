import ACPModel
import Foundation

/// Events emitted during a prompt execution.
///
/// Used to stream real-time updates from the agent while processing a prompt.
/// Clients can iterate over an `AsyncStream<Event>` to receive updates as they occur.
///
/// ## Usage
///
/// ```swift
/// let eventStream = session.prompt(content: [.text(TextContent(text: "Hello"))])
/// for await event in eventStream {
///     switch event {
///     case .sessionUpdate(let update):
///         // Handle incremental update (tool calls, messages, etc.)
///         print("Update: \(update)")
///     case .promptResponse(let response):
///         // Handle final response
///         print("Done: \(response.stopReason)")
///     }
/// }
/// ```
public enum Event: Sendable {
    /// A session update notification from the agent.
    ///
    /// These arrive during prompt processing and indicate progress,
    /// tool calls, message chunks, and other incremental updates.
    case sessionUpdate(SessionUpdate)

    /// The final prompt response indicating the turn is complete.
    ///
    /// Contains the stop reason (end_turn, max_tokens, cancelled, etc.).
    case promptResponse(PromptResponse)
}
