// SimpleClient - Example ACP Client Implementation
//
// This example demonstrates implementing the Client protocol to connect
// to an ACP agent, create sessions, and send prompts.
//
// Usage:
//   # Connect to an agent running via stdio (e.g., EchoAgent)
//   echo '{"prompt":"Hello!"}' | swift run SimpleClient --stdin
//
//   # Or pipe to an agent
//   swift run SimpleClient | swift run EchoAgent
//
// The client demonstrates:
// - Implementing the Client protocol
// - Connecting to an agent and initializing
// - Creating sessions
// - Sending prompts
// - Handling session updates

import ACP
import ACPModel
import Foundation

// MARK: - SimpleClient Implementation

/// An example client that connects to an agent and sends prompts.
///
/// This demonstrates:
/// - Implementing the `Client` protocol
/// - Defining client capabilities
/// - Handling session updates from the agent
/// - Connection lifecycle callbacks
private final class SimpleClient: Client, @unchecked Sendable {
    /// Client capabilities - minimal capabilities for this example.
    var capabilities: ClientCapabilities {
        ClientCapabilities()
    }

    /// Client implementation info.
    var info: Implementation? {
        Implementation(name: "SimpleClient", version: "1.0.0")
    }

    /// Called when session update is received from the agent.
    func onSessionUpdate(_ update: SessionInfoUpdate) async {
        log("Session update received: \(update)")
    }

    /// Called when connection to agent is established.
    func onConnected() async {
        log("Connected to agent")
    }

    /// Called when connection to agent is lost.
    func onDisconnected(error: Error?) async {
        if let error = error {
            log("Disconnected with error: \(error)")
        } else {
            log("Disconnected")
        }
    }

    /// Log a message to stderr.
    private func log(_ message: String) {
        FileHandle.standardError.write(Data("[\(Date())] SimpleClient: \(message)\n".utf8))
    }
}

// MARK: - Main Entry Point

@main
private struct SimpleClientMain {
    static func main() async {
        // Log startup to stderr
        FileHandle.standardError.write(Data("SimpleClient starting...\n".utf8))

        // Check for command line arguments
        let args = CommandLine.arguments

        // Default: demo mode - shows example usage
        if args.count < 2 || args.contains("--help") {
            printUsage()
            return
        }

        // Create the transport (stdio for this example)
        let transport = StdioTransport()

        // Create the client
        let client = SimpleClient()

        // Create the connection
        let connection = ClientConnection(transport: transport, client: client)

        do {
            // Connect to the agent
            FileHandle.standardError.write(Data("Connecting to agent...\n".utf8))
            let agentInfo = try await connection.connect()

            if let info = agentInfo {
                FileHandle.standardError.write(Data("Connected to: \(info.name) v\(info.version)\n".utf8))
            } else {
                FileHandle.standardError.write(Data("Connected to agent (no info provided)\n".utf8))
            }

            // Create a session
            FileHandle.standardError.write(Data("Creating session...\n".utf8))
            let sessionRequest = NewSessionRequest(
                cwd: FileManager.default.currentDirectoryPath,
                mcpServers: []
            )
            let sessionResponse = try await connection.createSession(request: sessionRequest)
            FileHandle.standardError.write(Data("Session created: \(sessionResponse.sessionId)\n".utf8))

            // Demo: read prompt from stdin if --demo flag
            if args.contains("--demo") {
                await runDemo(connection: connection, sessionId: sessionResponse.sessionId)
            } else {
                // Interactive mode: read prompts from stdin
                await runInteractive(connection: connection, sessionId: sessionResponse.sessionId)
            }

            // Disconnect
            FileHandle.standardError.write(Data("Disconnecting...\n".utf8))
            await connection.disconnect()
            FileHandle.standardError.write(Data("SimpleClient finished.\n".utf8))

        } catch {
            FileHandle.standardError.write(Data("SimpleClient error: \(error)\n".utf8))
        }
    }

    /// Print usage information.
    static func printUsage() {
        let usage = """
        SimpleClient - Example ACP Client

        Usage:
          swift run SimpleClient --demo         Run with demo prompt
          swift run SimpleClient --interactive  Read prompts from stdin
          swift run SimpleClient --help         Show this help

        This client connects to an ACP agent via stdio, creates a session,
        and sends prompts. It demonstrates implementing the Client protocol.

        Example with EchoAgent:
          # Terminal 1: Start EchoAgent
          swift run EchoAgent

          # Terminal 2: Send a message (requires stdio piping setup)
          # Note: For real usage, you'd connect transports via pipes

        """
        FileHandle.standardError.write(Data(usage.utf8))
    }

    /// Run demo mode with a single test prompt.
    static func runDemo(connection: ClientConnection, sessionId: SessionId) async {
        FileHandle.standardError.write(Data("Sending demo prompt...\n".utf8))

        do {
            let promptRequest = PromptRequest(
                sessionId: sessionId,
                prompt: [
                    .text(TextContent(text: "Hello from SimpleClient! Please echo this message."))
                ]
            )

            let response = try await connection.prompt(request: promptRequest)
            FileHandle.standardError.write(Data("Response received - stopReason: \(response.stopReason)\n".utf8))
        } catch {
            FileHandle.standardError.write(Data("Prompt error: \(error)\n".utf8))
        }
    }

    /// Run interactive mode reading prompts from stdin.
    static func runInteractive(connection: ClientConnection, sessionId: SessionId) async {
        FileHandle.standardError.write(Data("Interactive mode - enter prompts (Ctrl+D to quit):\n".utf8))

        while let line = readLine() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            do {
                let promptRequest = PromptRequest(
                    sessionId: sessionId,
                    prompt: [
                        .text(TextContent(text: trimmed))
                    ]
                )

                FileHandle.standardError.write(Data("Sending: \(trimmed)\n".utf8))
                let response = try await connection.prompt(request: promptRequest)
                FileHandle.standardError.write(Data("Response: stopReason=\(response.stopReason)\n".utf8))
            } catch {
                FileHandle.standardError.write(Data("Prompt error: \(error)\n".utf8))
            }
        }
    }
}
