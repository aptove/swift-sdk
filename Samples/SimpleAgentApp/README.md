# SimpleAgentApp

An in-process demo that runs both an ACP agent AND client in the same process, connected via in-memory message passing. This is ideal for testing and learning the ACP protocol flow.

## Features

- **In-Process Communication** - Agent and client run in same process
- **In-Memory Transport** - No external processes or network required
- **Full Protocol Demo** - Shows complete ACP handshake and messaging
- **Interactive Chat** - REPL interface for testing
- **Feature Demonstrations** - Plan updates, tool calls, file ops

## Building

```bash
# From the swift-sdk directory
swift build --target SimpleAgentApp
```

## Running

```bash
swift run SimpleAgentApp
```

## Example Session

```
╔══════════════════════════════════════════════════════════════╗
║           SimpleAgentApp - In-Process Demo                   ║
╠══════════════════════════════════════════════════════════════╣
║  Running both agent and client in the same process           ║
║  connected via in-memory message passing.                    ║
╚══════════════════════════════════════════════════════════════╝

Starting agent...
Connecting client...
📱 Client: Connected to agent
✓ Connected to: SimpleAgent v1.0.0

🤖 Agent: Created session A1B2C3D4-E5F6-...
✓ Session created: A1B2C3D4-E5F6-...

═══════════════════════════════════════════════════════════════
  Type your messages. Commands: 'exit' to quit
═══════════════════════════════════════════════════════════════

You: Hello world

Agent: 🤖 Agent: Processing prompt for session A1B2C3D4-...
🤖 Agent: Received: Hello world

📋 Plan:
   🔄 Process user input
   ⏳ Generate response
   ⏳ Execute tools if needed

Hello! I received your message: "Hello world"
   → Processing request: in_progress
   → Processing request: completed

📁 Demonstrating file system operations...
📱 Client: Writing file /tmp/acp_simple_agent_test.txt
📱 Client: Reading file /tmp/acp_simple_agent_test.txt
   ✓ Wrote file: /tmp/acp_simple_agent_test.txt
   ✓ Read back: Hello from SimpleAgent! Written at 2026-01-30...

📋 Plan:
   ✅ Process user input
   ✅ Generate response
   ✅ Execute tools if needed

✅ All operations completed successfully!
(Stop reason: endTurn)

You: exit

Shutting down...
📱 Client: Disconnected
Goodbye! 👋
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SimpleAgentApp Process                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐      InMemoryPipe      ┌────────────┐ │
│  │                  │ ◄──────────────────────► │            │ │
│  │   SimpleAgent    │                         │  Client    │ │
│  │                  │ ◄──────────────────────► │            │ │
│  └──────────────────┘      InMemoryPipe      └────────────┘ │
│                                                              │
│         AgentConnection              ClientConnection        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components

### InMemoryPipeTransport

A bidirectional transport that delivers messages directly in memory:

```swift
let (clientTransport, agentTransport) = InMemoryPipeTransport.createPair()
```

### SimpleAgent

Demonstrates agent features:
- Plan updates with status changes
- Tool call simulation
- File system operations via client
- Message streaming

### SimpleAgentClient

Implements client operations:
- Permission request handling (auto-approve)
- File read/write operations
- Session update rendering

## Code Overview

```swift
// Create connected transport pair
let (clientTransport, agentTransport) = InMemoryPipeTransport.createPair()

// Create agent and client
let agent = SimpleAgent()
let client = SimpleAgentClient()

// Create connections
let agentConnection = AgentConnection(transport: agentTransport, agent: agent)
let clientConnection = ClientConnection(transport: clientTransport, client: client)

// Start agent in background
Task {
    try await agentConnection.start()
    await agentConnection.waitUntilComplete()
}

// Connect client
let agentInfo = try await clientConnection.connect()

// Create session and chat
let session = try await clientConnection.createSession(...)
let response = try await clientConnection.prompt(...)
```

## Use Cases

1. **Learning ACP** - Understand the protocol flow without external dependencies
2. **Testing** - Write unit/integration tests for agent logic
3. **Development** - Iterate quickly on agent implementation
4. **Debugging** - Step through both agent and client code together

## Extending

To add new agent behaviors:

```swift
func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
    // Your custom logic here
    
    // Send messages
    try await context.notify(notification: .agentMessageChunk(...))
    
    // Use client capabilities
    if context.clientCapabilities.fs?.readTextFile == true {
        let file = try await context.readTextFile(path: "/path/to/file")
    }
    
    return PromptResponse(stopReason: .endTurn)
}
```
