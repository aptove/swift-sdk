# EchoAgent

A simple ACP agent that echoes back user messages. This is the most basic example of implementing the Agent protocol.

## Features

- Demonstrates basic `Agent` protocol implementation
- Echoes user messages back with session updates
- Uses stdio transport for communication

## Building

```bash
# From the swift-sdk directory
swift build --target EchoAgent
```

## Running

The EchoAgent communicates via stdin/stdout using JSON-RPC, so it's designed to be launched by a client:

```bash
# Run directly (will wait for JSON-RPC input on stdin)
swift run EchoAgent
```

## Testing with SimpleClient

The easiest way to test EchoAgent is with the SimpleClient sample:

```bash
# Terminal 1: Build both
swift build

# Terminal 2: Run SimpleClient connecting to EchoAgent
swift run SimpleClient "swift run EchoAgent"
```

## Testing with InteractiveClient

For a full-featured interactive experience:

```bash
swift run InteractiveClient swift run EchoAgent
```

## Manual Testing

You can also test by sending JSON-RPC messages directly:

```bash
# Start the agent
swift run EchoAgent

# Send initialize request (paste this):
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"test","version":"1.0"},"capabilities":{}}}

# Send session/new request:
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/tmp","mcpServers":[]}}

# Send prompt request (use the sessionId from previous response):
{"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"<session-id>","prompt":[{"type":"text","text":"Hello!"}]}}
```

## Code Overview

The agent implements the `Agent` protocol with:

- `capabilities` - Declares agent capabilities
- `info` - Returns agent name and version
- `createSession()` - Creates a new session
- `handlePrompt()` - Processes prompts and returns responses

```swift
final class EchoAgentImpl: Agent {
    func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
        // Echo the user's message back
        let text = extractText(from: request.prompt)
        try await context.sendTextMessage("Echo: \(text)")
        return PromptResponse(stopReason: .endTurn)
    }
}
```
