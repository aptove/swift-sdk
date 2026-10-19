<a href="https://agentclientprotocol.com/" >
  <img alt="Agent Client Protocol" src="https://zed.dev/img/acp/banner-dark.webp">
</a>

# ACP Swift SDK

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/aptove/swift-sdk/actions/workflows/tests.yml/badge.svg)](https://github.com/aptove/swift-sdk/actions/workflows/tests.yml)

A Swift implementation of the [Agent Client Protocol (ACP)](https://agentclientprotocol.com) for building AI agent clients and servers. Ship ACP-compliant agents, clients, and transports for iOS apps, macOS tools, CLI utilities, or any Swift-based host.

> **Note:** This SDK is a Swift port of the [ACP Kotlin SDK](https://github.com/agentclientprotocol/kotlin-sdk) (v0.33.0), providing equivalent functionality with Swift-native APIs and idioms.

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
| `ACP` | Core agent/client runtime with STDIO transport | `Agent`, `Client`, `AgentConnection`, `ClientConnection`, `StdioTransport`, `ACPProtocol` |
| `ACPHTTP` | HTTP/WebSocket transport support | `WebSocketTransport` |

> **Tip:** When using the low-level `Protocol` actor directly (e.g. for V2 sessions), import `ACP` and use the `ACPProtocol` typealias to avoid ambiguity with `ObjectiveC.Protocol` in files that also import Foundation.

## Requirements

- Swift 6.0+
- macOS 12.0+ / iOS 15.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 16.0+ (for development)

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aptove/swift-sdk.git", from: "0.1.0")
]
```

Then add the desired targets as dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ACPModel", package: "ACP"),
        .product(name: "ACP", package: "ACP"),
        // Optional:
        // .product(name: "ACPHTTP", package: "ACP"),
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
        // Spawn agent process and wire up stdio pipes
        let process = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["my-agent"]
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        try process.run()

        let transport = StdioTransport(
            input: stdoutPipe.fileHandleForReading,
            output: stdinPipe.fileHandleForWriting
        )
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

### Use the V2 protocol

The V2 protocol uses `ACPProtocol` directly instead of the high-level `AgentConnection`/`ClientConnection` wrappers. The example below runs a V2 agent and client in-process:

```swift
import ACP
import ACPModel
import Foundation

// Register V2 handlers on an ACPProtocol instance
func registerAgentHandlers(proto: ACPProtocol) async {
    let info = Implementation(name: "MyV2Agent", version: "1.0.0")

    await proto.onRequest(method: "initialize", requestType: V2InitializeRequest.self) { _ in
        V2InitializeResponse(protocolVersion: .v2, info: info, capabilities: V2AgentCapabilities())
    }

    await proto.onRequest(method: "session/new", requestType: V2NewSessionRequest.self) { _ in
        V2NewSessionResponse(sessionId: SessionId())
    }

    await proto.onRequest(method: "session/prompt", requestType: V2PromptRequest.self) { [proto] req in
        let text = req.prompt.compactMap { if case .text(let t) = $0 { return t.text } else { return nil } }.joined()

        // Send session updates back to the client
        try await proto.sendNotification(method: "session/update", params:
            V2UpdateSessionNotification(sessionId: req.sessionId, update: .stateUpdate(.running(_meta: nil))))
        try await proto.sendNotification(method: "session/update", params:
            V2UpdateSessionNotification(sessionId: req.sessionId, update: .agentMessageChunk(
                V2ContentChunk(messageId: MessageId(rawValue: UUID().uuidString),
                               content: .text(V2ContentBlock.Text(text: text)), _meta: nil))))
        try await proto.sendNotification(method: "session/update", params:
            V2UpdateSessionNotification(sessionId: req.sessionId, update: .stateUpdate(.idle(stopReason: .endTurn, usage: nil, _meta: nil))))

        return V2PromptResponse()
    }
}

// Run a prompt turn and collect session updates
func sendPrompt(proto: ACPProtocol, sessionId: SessionId, text: String) async throws {
    let (updates, cont) = AsyncStream<V2SessionUpdate>.makeStream()

    await proto.onNotification(method: "session/update") { notification in
        guard let params = notification.params,
              let data = try? JSONEncoder().encode(params),
              let notif = try? JSONDecoder().decode(V2UpdateSessionNotification.self, from: data) else { return }
        cont.yield(notif.update)
    }

    let collectTask = Task {
        for await update in updates {
            if case .agentMessageChunk(let chunk) = update, case .text(let t) = chunk.content {
                print("Agent: \(t.text)")
            }
            if case .stateUpdate(.idle) = update { cont.finish(); break }
        }
    }

    _ = try await proto.request(
        method: "session/prompt",
        params: V2PromptRequest(sessionId: sessionId, prompt: [.text(V2ContentBlock.Text(text: text))]),
        responseType: V2PromptResponse.self
    )
    await collectTask.value
}

// Wire up in-process agent and client
let (clientTransport, agentTransport) = InMemoryPipeTransport.createPair()
let agentProto = ACPProtocol(transport: agentTransport)
let clientProto = ACPProtocol(transport: clientTransport)

await registerAgentHandlers(proto: agentProto)
try await agentProto.start()
try await clientProto.start()

_ = try await clientProto.request(
    method: "initialize",
    params: V2InitializeRequest(protocolVersion: .v2, info: Implementation(name: "MyClient", version: "1.0.0")),
    responseType: V2InitializeResponse.self
)

let sessionResp = try await clientProto.request(
    method: "session/new",
    params: V2NewSessionRequest(cwd: FileManager.default.currentDirectoryPath),
    responseType: V2NewSessionResponse.self
)

try await sendPrompt(proto: clientProto, sessionId: sessionResp.sessionId, text: "Hello V2!")

await agentProto.close()
await clientProto.close()
```

> The `InMemoryPipeTransport` used above is defined in `Samples/V2SimpleAgentApp/main.swift` and is not part of the SDK library — copy it into your own code or use a real transport like `StdioTransport`.

## Sample projects

| Sample | Description | Command |
|--------|-------------|---------|
| `SimpleAgentApp` | In-process V1 agent + client demo | `swift run SimpleAgentApp` |
| `V2SimpleAgentApp` | In-process V2 agent + client demo with session config options | `swift run V2SimpleAgentApp` |
| `V2NegotiationApp` | Protocol version negotiation: client tries V2 first, falls back to V1 | `swift run V2NegotiationApp` |
| `AuthStatusApp` | Queries `auth/status` via both V1 and V2 protocols against a real agent | `swift run AuthStatusApp <cmd> [args]` |
| `GeminiClientApp` | Interactive stdio client with file system and terminal support | `swift run GeminiClientApp <cmd> [args]` |

Run samples from the `swift-sdk` directory.

## Capabilities

### Protocol
- ✅ Full ACP V1 and V2 protocol coverage with JSON-RPC framing
- ✅ Typed request/response wrappers for both V1 and V2
- ✅ Message correlation, error propagation
- ✅ V2: `session/new`, `session/prompt`, `session/update`, `session/set_config_option`
- ✅ V2 protocol version negotiation (client tries V2, falls back to V1)

### Agent runtime
- ✅ Capability negotiation and session lifecycle
- ✅ Prompt streaming with session updates
- ✅ Tool-call progress, execution plans, permission requests
- ✅ File-system operations via client callbacks
- ✅ Terminal operations via client callbacks

### Client runtime
- ✅ Capability advertising and lifecycle management
- ✅ File-system and terminal helpers
- ✅ Permission request handling
- ✅ Session update listeners
- ✅ Process spawning for external agents

### Session Operations
- ✅ Create session (`session/new`)
- ✅ Send prompts (`session/prompt`)
- ✅ Cancel prompt (`session/cancel`)
- ✅ Load session with message history (`session/load`)
- ✅ Set session config option (`session/set_config_option`) ⚠️ unstable
- ✅ List sessions (`session/list`) ⚠️ unstable
- ✅ Fork session (`session/fork`) ⚠️ unstable
- ✅ Resume session (`session/resume`) ⚠️ unstable
- ⚠️ Delete session (`session/delete`) — V2 model types only, no runtime helper yet

### Transports
- ✅ STDIO transport (pipes, file handles)
- ✅ WebSocket transport (via ACPHTTP module)
- 🚧 HTTP SSE transport (not implemented in any ACP SDK)

## Architecture

### V1 — high-level connection layer

```
┌─────────────────┐    ┌─────────────────┐
│   Agent App     │    │   Client App    │
│   (Agent impl)  │    │  (Client impl)  │
├─────────────────┤    ├─────────────────┤
│ AgentConnection │    │ClientConnection │
├─────────────────┤    ├─────────────────┤
│   ACPProtocol   │    │   ACPProtocol   │
├─────────────────┤    ├─────────────────┤
│   Transport     │◄──►│   Transport     │
│ (Stdio, WebSkt) │    │ (Stdio, WebSkt) │
└─────────────────┘    └─────────────────┘
```

**V1 lifecycle:** Clients call `connect()` to negotiate capabilities, `createSession()`, `prompt()`, and react to streamed updates (tool calls, permissions, file ops). Agents implement the mirror of these methods.

### V2 — direct protocol layer

V2 has no high-level `AgentConnection`/`ClientConnection` wrappers yet. Both sides use `ACPProtocol` directly, registering typed handlers and sending notifications manually:

```
┌──────────────────────┐    ┌───────────────────────┐
│ Agent (V2 handlers)  │    │  Client (V2 requests) │
├──────────────────────┤    ├───────────────────────┤
│     ACPProtocol      │    │     ACPProtocol       │
├──────────────────────┤    ├───────────────────────┤
│      Transport       │◄──►│      Transport        │
│   (Stdio, WebSkt)    │    │   (Stdio, WebSkt)     │
└──────────────────────┘    └───────────────────────┘
```

**V2 lifecycle:** Agent registers handlers via `onRequest(method:requestType:handler:)`. Client calls `request(method:params:responseType:)` and listens for `session/update` notifications via `onNotification(method:)`. See the [V2 quick start](#use-the-v2-protocol) above for a working example.

## Testing

The test suite and SwiftLint run automatically on every push via GitHub Actions. To run locally:

```bash
cd swift-sdk
swift test
swiftlint lint --strict
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

*This SDK maintains feature parity with the [ACP Kotlin SDK](https://github.com/agentclientprotocol/kotlin-sdk) v0.33.0.*
