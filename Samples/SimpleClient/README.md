# SimpleClient

A basic ACP client that connects to an external agent process and sends a simple prompt. This demonstrates the minimal setup needed to communicate with an ACP agent.

## Features

- Spawns an external agent process
- Connects via stdio transport
- Sends a single prompt and displays the response
- Clean shutdown handling

## Building

```bash
# From the swift-sdk directory
swift build --target SimpleClient
```

## Running

SimpleClient takes an agent command as its argument:

```bash
# Connect to EchoAgent
swift run SimpleClient "swift run EchoAgent"

# Connect to GitHub Copilot (if installed)
swift run SimpleClient "copilot --acp"

# Connect to any ACP-compatible agent
swift run SimpleClient "<agent-command> [args...]"
```

## Example Output

```
SimpleClient - Basic ACP Client Demo
====================================

Starting agent: swift run EchoAgent
Connecting...
✓ Connected to: EchoAgent v1.0.0

Creating session...
✓ Session ID: A1B2C3D4-E5F6-...

Sending prompt: Hello, Agent!
Agent response:
Echo: Hello, Agent!

Stop reason: endTurn
Disconnecting...
Done!
```

## Code Overview

The client demonstrates:

1. **Process Spawning** - Launching an agent as a subprocess
2. **Transport Setup** - Creating stdio transport from process pipes
3. **Connection** - Initializing the ACP handshake
4. **Session Creation** - Creating a new chat session
5. **Prompt/Response** - Sending a prompt and receiving the response

```swift
// Spawn agent process
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["bash", "-c", agentCommand]

// Create transport from process pipes
let transport = StdioTransport(
    input: stdoutPipe.fileHandleForReading,
    output: stdinPipe.fileHandleForWriting
)

// Connect and communicate
let connection = ClientConnection(transport: transport, client: client)
let agentInfo = try await connection.connect()
let session = try await connection.createSession(request: NewSessionRequest(...))
let response = try await connection.prompt(request: PromptRequest(...))
```

## Error Handling

The client handles common errors:

- Agent process fails to start
- Connection timeout
- Invalid agent response
- Session creation failure

## Next Steps

For a more interactive client with full features, see the [InteractiveClient](../InteractiveClient/README.md) sample.
