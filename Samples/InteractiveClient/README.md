# InteractiveClient

A full-featured ACP client with interactive chat, file system operations, terminal execution, and permission handling. This is the most complete client sample.

## Features

- **Interactive Chat** - REPL-style conversation with streaming responses
- **Process Spawning** - Connect to any ACP agent via command line
- **File System Operations** - Read and write files on behalf of the agent
- **Terminal Operations** - Execute commands requested by the agent
- **Permission Handling** - Interactive prompts for agent permission requests
- **Session Updates** - Real-time display of plans, tool calls, and status

## Building

```bash
# From the swift-sdk directory
swift build --target InteractiveClient
```

## Running

```bash
# Connect to GitHub Copilot
swift run InteractiveClient copilot --acp

# Connect to Gemini
swift run InteractiveClient copilot --acp

# Connect to EchoAgent (for testing)
swift run InteractiveClient swift run EchoAgent

# Connect to any ACP agent
swift run InteractiveClient <command> [args...]
```

## Usage

Once connected, you'll see an interactive prompt:

```
╔══════════════════════════════════════════════════════════════╗
║           ACP Interactive Client                             ║
╠══════════════════════════════════════════════════════════════╣
║  Starting agent: copilot --acp                               ║
╚══════════════════════════════════════════════════════════════╝

Connecting to agent...
✓ Connected to: GitHub Copilot v1.0.0

Creating session...
✓ Session created: A1B2C3D4-E5F6-...

═══════════════════════════════════════════════════════════════
  Type your messages below. Commands:
    'exit', 'quit', 'bye' - Exit the client
    Ctrl+C                - Cancel current request
═══════════════════════════════════════════════════════════════

You: Hello! Can you help me write a function?

Agent: Of course! I'd be happy to help...
```

## Features in Detail

### File System Operations

When the agent requests file operations, the client handles them:

```
ℹ️  📖 Reading file: /path/to/file.swift
ℹ️  📝 Writing file: /path/to/output.swift
```

### Terminal Operations

The client can execute terminal commands for the agent:

```
ℹ️  🖥️  Creating terminal: swift build
```

### Permission Requests

When the agent needs permission, you'll see an interactive prompt:

```
╔══════════════════════════════════════════════════════════════╗
║  PERMISSION REQUEST                                          ║
╠══════════════════════════════════════════════════════════════╣
║  Tool: Write File                                            ║
║  Kind: file_write                                            ║
╠══════════════════════════════════════════════════════════════╣
║  Choose an option:                                           ║
║  [1] Allow once                                              ║
║  [2] Allow for session                                       ║
║  [3] Deny                                                    ║
╚══════════════════════════════════════════════════════════════╝

Enter option number (1-3): 1
✓ Selected: Allow once
```

### Session Updates

The client displays real-time updates:

```
📋 Plan:
   🔄 Analyze the codebase
   ⏳ Generate implementation
   ⏳ Write tests

🔧 Tool call: Read File (file_read)
   → Reading: in_progress
   → Reading: completed
```

## Code Structure

```
InteractiveClient/
└── main.swift
    ├── TerminalManager (actor)     - Thread-safe process management
    ├── InteractiveClient (class)   - Client implementation
    │   ├── Client protocol         - Connection callbacks
    │   ├── ClientSessionOperations - Permission & notification handling
    │   ├── File system operations  - readTextFile, writeTextFile
    │   ├── Terminal operations     - create, output, kill, release, wait
    │   └── Rendering utilities     - Session update display
    ├── createProcessTransport()    - Spawn agent subprocess
    └── main()                      - Entry point & chat loop
```

## Client Capabilities

The client declares these capabilities to agents:

```swift
var capabilities: ClientCapabilities {
    ClientCapabilities(
        fs: FileSystemCapability(
            readTextFile: true,
            writeTextFile: true
        ),
        terminal: true
    )
}
```

## Keyboard Commands

| Key | Action |
|-----|--------|
| `Enter` | Send message |
| `exit` / `quit` / `bye` | Exit client |
| `Ctrl+D` | Exit (EOF) |
| `Ctrl+C` | Cancel current request |

## Troubleshooting

### Agent fails to start

```
Error: The operation couldn't be completed. No such file or directory
```

Make sure the agent command is correct and the agent is installed.

### Connection timeout

```
Error: Connection timed out
```

The agent may have crashed during startup. Check if the agent runs correctly standalone.

### Permission denied

```
Error: Permission denied
```

Ensure you have permission to execute the agent and access requested files.
