// EchoAgent - Example ACP Agent Implementation
//
// This example demonstrates implementing the Agent protocol to create
// a simple echo agent that returns user prompts as agent messages.
//
// Usage:
//   swift run EchoAgent
//   (then send JSON-RPC messages via stdin)
//
// Example interaction:
//   → {"jsonrpc":"2.0","id":1,"method":"initialize","params":{...}}
//   ← {"jsonrpc":"2.0","id":1,"result":{...}}
//   → {"jsonrpc":"2.0","id":2,"method":"acp/session/new","params":{...}}
//   ← {"jsonrpc":"2.0","id":2,"result":{"sessionId":"..."}}
//   → {"jsonrpc":"2.0","id":3,"method":"acp/prompt","params":{...}}
//   ← {"jsonrpc":"2.0","method":"acp/session/update","params":{...}}
//   ← {"jsonrpc":"2.0","id":3,"result":{"stopReason":"end_turn"}}

import ACP
import ACPModel
import Foundation

// MARK: - EchoAgent Implementation

/// An example agent that echoes back user prompts.
///
/// This demonstrates:
/// - Implementing the `Agent` protocol
/// - Defining agent capabilities
/// - Session management (in-memory sessions)
/// - Processing prompts and sending session updates
private struct EchoAgent: Agent {
    /// Agent capabilities - we support basic sessions.
    var capabilities: AgentCapabilities {
        AgentCapabilities()
    }

    /// Agent implementation info.
    var info: Implementation? {
        Implementation(name: "EchoAgent", version: "1.0.0")
    }

    /// Create a new session.
    ///
    /// This simple implementation just generates a new session ID.
    /// A production agent might initialize resources, load context, etc.
    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        let sessionId = SessionId()
        log("Created session: \(sessionId)")
        return NewSessionResponse(sessionId: sessionId)
    }

    /// Process a prompt from the client.
    ///
    /// This echo agent extracts text from the prompt and returns it
    /// as an agent message in a session update.
    func handlePrompt(request: PromptRequest) async throws -> PromptResponse {
        log("Processing prompt for session: \(request.sessionId)")

        // Extract text content from the prompt
        let text = extractText(from: request.prompt)
        log("Received: \(text)")

        // Echo: We'll need the connection to send updates
        // For now, just return the response - the connection handles updates
        return PromptResponse(stopReason: .endTurn)
    }

    /// Extract text content from content blocks.
    private func extractText(from blocks: [ContentBlock]) -> String {
        blocks.compactMap { block -> String? in
            if case .text(let content) = block {
                return content.text
            }
            return nil
        }.joined(separator: "\n")
    }

    /// Log a message to stderr (so it doesn't interfere with JSON-RPC on stdout).
    private func log(_ message: String) {
        FileHandle.standardError.write(Data("[\(Date())] EchoAgent: \(message)\n".utf8))
    }
}

// MARK: - Main Entry Point

@main
private struct EchoAgentMain {
    static func main() async {
        // Log startup to stderr
        FileHandle.standardError.write(Data("EchoAgent starting...\n".utf8))

        // Create the transport (stdio)
        let transport = StdioTransport()

        // Create the agent
        let agent = EchoAgent()

        // Create the connection
        let connection = AgentConnection(transport: transport, agent: agent)

        do {
            // Start the connection
            try await connection.start()

            FileHandle.standardError.write(Data("EchoAgent ready, waiting for messages...\n".utf8))

            // Wait until the connection closes
            await connection.waitUntilComplete()

            FileHandle.standardError.write(Data("EchoAgent shutting down.\n".utf8))
        } catch {
            FileHandle.standardError.write(Data("EchoAgent error: \(error)\n".utf8))
        }
    }
}
