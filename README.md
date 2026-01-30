# ACP Swift SDK

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

A Swift implementation of the [Agent Client Protocol (ACP)](https://agentclientprotocol.com) for building AI agent clients and servers. Ship ACP-compliant agents, clients, and transports for iOS apps, macOS tools, CLI utilities, or any Swift-based host.

> **Note:** This SDK is a Swift port of the [ACP Kotlin SDK](https://github.com/agentclientprotocol/kotlin-sdk) (v0.15.1), providing equivalent functionality with Swift-native APIs and idioms.

## What is ACP Swift SDK?

ACP standardizes how AI agents and clients exchange messages, negotiate capabilities, and handle file operations. This SDK provides a Swift implementation of that spec:

- Type-safe models for every ACP message and capability
- Agent and client connection stacks (JSON-RPC over STDIO)
- HTTP/WebSocket transport support (optional module)
- Comprehensive samples demonstrating end-to-end sessions and tool calls

### Common scenarios

- Embed an ACP client in your iOS/macOS app to talk to external agents
- Build a headless automation agent that serves ACP prompts and tools
- Prototype new transports with the connection layer and model modules
- Validate your ACP integration using the supplied test utilities

## Modules at a glance

| Module | Description | Main types |
|--------|-------------|------------|
| `ACPModel` | Pure data model for ACP messages, capabilities, and enums | `JsonRpcMessage`, `PromptRequest`, `SessionUpdate` |
| `ACP` | Core agent/client runtime with STDIO transport | `Agent`, `Client`, `AgentConnection`, `ClientConnection`, `StdioTransport` |
| `ACPHTTP` | HTTP/WebSocket transport support | `WebSocketTransport` |

## Requirements

- Swift 6.0+
- macOS 12.0+ / iOS 15.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 16.0+ (for development)

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/acp-swift-sdk.git", from: "0.1.0")
]
```

Then add the desired targets as dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ACPModel", package: "acp-swift-sdk"),
        .product(name: "ACP", package: "acp-swift-sdk"),
        // Optional:
        // .product(name: "ACPHTTP", package: "acp-swift-sdk"),
    ]
)
```

## Quick start

### Write your first agent

Set up an `Agent` implementation, wire the standard STDIO transport, and stream responses:

```swift
import ACP
import ACPModel
import Foundation

// 1. Implement the Agent protocol
final class MyAgent: Agent, @unchecked Sendable {
    var capabilities: AgentCapabilities {
        AgentCapabilities(
            loadSession: true,
            promptCapabilities: PromptCapabilities(
                audio: false,
                image: false,
                embeddedContext: true
            )
        )
    }

    var info: Implementation? {
        Implementation(name: "MyAgent", version: "1.0.0")
    }

    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        return NewSessionResponse(sessionId: SessionId())
    }

    func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
        // Extract user text from prompt
        let userText = request.prompt.compactMap { block -> String? in
            if case .text(let content) = block { return content.text }
            return nil
        }.joined(separator: " ")

        // Stream response back
        try await context.sendTextMessage("Agent heard: \(userText)")

        // Use client capabilities if available
        if context.clientCapabilities.fs?.readTextFile == true {
            let file = try await context.readTextFile(path: "README.md")
            try await context.sendTextMessage("README preview: \(file.content.prefix(120))...")
        }

        return PromptResponse(stopReason: .endTurn)
    }
}

// 2. Wire up the transport and start
@main
struct AgentMain {
    static func main() async throws {
        let transport = StdioTransport()
        let agent = MyAgent()
        let connection = AgentConnection(transport: transport, agent: agent)
        
        try await connection.start()
        await connection.waitUntilComplete()
    }
}
```

### Write your first client

Create a `ClientConnection` with your own `Client` implementation:

```swift
import ACP
import ACPModel
import Foundation

// 1. Implement the Client protocol
final class MyClient: Client, ClientSessionOperations, @unchecked Sendable {
    var capabilities: ClientCapabilities {
        ClientCapabilities(
            fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
            terminal: true
        )
    }

    var info: Implementation? {
        Implementation(name: "MyClient", version: "1.0.0")
    }

    func onSessionUpdate(_ update: SessionUpdate) async {
        print("Agent update: \(update)")
    }

    func onConnected() async {
        print("Connected to agent")
    }

    func onDisconnected(error: Error?) async {
        print("Disconnected")
    }

    // ClientSessionOperations
    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        // Auto-approve first option (replace with real UX)
        return RequestPermissionResponse(outcome: .selected(permissions.first!.optionId))
    }

    func notify(notification: SessionUpdate, meta: MetaField?) async {
        print("Notification: \(notification)")
    }

    // FileSystemOperations
    func readTextFile(path: String, line: UInt32?, limit: UInt32?, meta: MetaField?) async throws -> ReadTextFileResponse {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return ReadTextFileResponse(content: content)
    }

    func writeTextFile(path: String, content: String, meta: MetaField?) async throws -> WriteTextFileResponse {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return WriteTextFileResponse()
    }
}

// 2. Connect to an agent
@main
struct ClientMain {
    static func main() async throws {
        // Spawn agent process
        let (transport, process) = try createProcessTransport(command: "my-agent")
        let client = MyClient()
        let connection = ClientConnection(transport: transport, client: client)

        // Initialize connection
        let agentInfo = try await connection.connect()
        print("Connected to: \(agentInfo?.name ?? "agent")")

        // Create session
        let session = try await connection.createSession(
            request: NewSessionRequest(cwd: FileManager.default.currentDirectoryPath, mcpServers: [])
        )

        // Send prompt
        let response = try await connection.prompt(request: PromptRequest(
            sessionId: session.sessionId,
            prompt: [.text(TextContent(text: "Hello, agent!"))]
        ))

        print("Response: \(response.stopReason)")
        await connection.disconnect()
    }
}
```

## Sample projects

| Sample | Description | Command |
|--------|-------------|---------|
| `EchoAgent` | Simple agent that echoes messages back | `swift run EchoAgent` |
| `SimpleClient` | Basic client connecting to an agent | `swift run SimpleClient "agent-command"` |
| `InteractiveClient` | Full-featured CLI client with file/terminal ops | `swift run InteractiveClient copilot --acp` |
| `SimpleAgentApp` | In-process agent + client demo | `swift run SimpleAgentApp` |

Each sample includes a README with detailed usage instructions. Run samples from the `swift-sdk` directory.

## Capabilities

### Protocol
- ✅ Full ACP protocol coverage with JSON-RPC framing
- ✅ Typed request/response wrappers
- ✅ Message correlation, error propagation
- ✅ Protocol version: **2025-02-07**

### Agent runtime
- ✅ Capability negotiation and session lifecycle
- ✅ Prompt streaming with session updates
- ✅ Tool-call progress, execution plans, permission requests
- ✅ File-system operations via client callbacks

### Client runtime
- ✅ Capability advertising and lifecycle management
- ✅ File-system helpers and permission handling
- ✅ Session update listeners
- ✅ Process spawning for external agents

### Session Operations
- ✅ Create session (`session/new`)
- ✅ Send prompts (`session/prompt`)
- ✅ Cancel requests (`session/cancel`)
- ✅ Delete session (`session/delete`)
- ✅ Load session (with message history)
- ✅ Session configuration (get/set)
- ⚠️ List sessions (unstable)
- ⚠️ Fork session (unstable)
- ⚠️ Resume session (unstable)

### Transports
- ✅ STDIO transport (pipes, file handles)
- ✅ WebSocket transport (via ACPHTTP module)
- 🚧 HTTP SSE transport (not implemented in any ACP SDK)

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Agent App     │    │   Client App    │
│   (Agent impl)  │    │  (Client impl)  │
├─────────────────┤    ├─────────────────┤
│ AgentConnection │    │ClientConnection │
├─────────────────┤    ├─────────────────┤
│    Protocol     │    │    Protocol     │
├─────────────────┤    ├─────────────────┤
│   Transport     │◄──►│   Transport     │
│ (Stdio, WebSkt) │    │ (Stdio, WebSkt) │
└─────────────────┘    └─────────────────┘
```

**Lifecycle overview:** Clients establish a transport, call `connect()` to negotiate capabilities, create sessions, send prompts, and react to streamed updates (tool calls, permissions, status). Agents implement the mirror of these methods, delegating file and permission requests back to the client when required.

## Testing

Run the test suite:

```bash
cd swift-sdk
swift test
```

Run specific test files:

```bash
swift test --filter E2EIntegrationTests
swift test --filter ACPModelTests
```

## Contributing

Contributions are welcome! Please open an issue to discuss significant changes before submitting a PR.

1. Fork and clone the repo.
2. Run `swift test` to execute the test suite.
3. Ensure all tests pass before submitting.

## Support

- File bugs and feature requests through GitHub Issues.
- For questions or integration help, start a discussion or reach out through the issue tracker.

## License

Distributed under the Apache License 2.0. See [`LICENSE`](LICENSE) for details.

---

*This SDK maintains feature parity with the [ACP Kotlin SDK](https://github.com/agentclientprotocol/kotlin-sdk) v0.15.1.*
