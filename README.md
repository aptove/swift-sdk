# ACP Swift SDK

A Swift implementation of the Agent Client Protocol (ACP) for building AI agent clients and servers.

## Overview

This SDK provides a complete implementation of the [Agent Client Protocol](https://agentclientprotocol.org/) specification, enabling Swift applications to communicate with AI agents using a standardized protocol.

## Installation

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/acp-swift-sdk.git", branch: "main")
]
```

Then add the desired targets as dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ACPModel", package: "acp-swift-sdk"),
        .product(name: "ACP", package: "acp-swift-sdk"),
        .product(name: "ACPHTTP", package: "acp-swift-sdk"),
    ]
)
```

## Modules

### ACPModel

Core protocol types and message definitions. Includes:

- JSON-RPC message types
- Request/response types for all ACP operations
- Notification types
- Capability types

### ACP

Client and server implementation for the ACP protocol:

- `Client` - High-level client for connecting to agents
- `Protocol` - Low-level protocol layer handling JSON-RPC messaging
- Transport abstraction for different communication channels

### ACPHTTP

HTTP transport implementation:

- HTTP client transport using URLSession
- HTTP server transport using Swift NIO

## Usage

### Basic Client Example

```swift
import ACP
import ACPHTTP

// Create a client with HTTP transport
let transport = HTTPClientTransport(url: URL(string: "http://localhost:8080")!)
let client = Client(transport: transport)

// Connect and initialize
try await client.connect(
    clientInfo: ClientInfo(
        clientId: "my-app",
        clientVersion: "1.0.0"
    )
)

// Send a prompt
let response = try await client.prompt(request: PromptRequest(
    sessionId: client.agentInfo.sessionId,
    messages: [
        PromptMessage(role: .user, content: .text("Hello, agent!"))
    ]
))

// Close when done
await client.close()
```

## Protocol Version

This SDK implements **ACP Protocol Version 2025-02-07**.

## Implemented Features

### Core Operations
- ✅ Initialize/shutdown handshake
- ✅ Prompt/response with streaming
- ✅ Session management (start, load, close, config)
- ✅ Session modes
- ✅ Cancellation support

### Session Operations
- ✅ Start session
- ✅ Load session (with message history)
- ✅ Close session
- ✅ Session configuration (get/set)

### Events and Notifications
- ✅ Message streaming events
- ✅ Agent events
- ✅ Session events
- ✅ Client events

### Capabilities
- ✅ Agent capabilities negotiation
- ✅ Client capabilities declaration
- ✅ Model capabilities
- ✅ Permissions model

### Tools and Models
- ✅ Tool definitions and execution
- ✅ Tool approval flow
- ✅ Model listing
- ✅ Model preferences

### File Operations
- ✅ File read/write/edit permissions
- ✅ Directory listing permissions
- ✅ Terminal execution permissions

### Unstable APIs

The following APIs are marked as **UNSTABLE** and may change without notice:

- ⚠️ `listSessions()` - List existing sessions
- ⚠️ `forkSession()` - Fork a session to create an independent copy
- ⚠️ `resumeSession()` - Resume a session without message history

## Not Implemented

The following features are defined in the ACP specification but not yet implemented in this SDK:

### HTTP SSE Transport

Server-Sent Events (SSE) transport is not implemented. This transport type allows servers to push events to clients over a persistent HTTP connection. Note that **no ACP SDK currently implements HTTP SSE transport** - the feature exists only as model types in the specification.

If you need real-time server-to-client streaming, use the WebSocket transport or the built-in streaming support in the standard HTTP transport.

## Requirements

- Swift 5.9+
- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
