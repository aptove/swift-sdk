// InteractiveClient - Full-Featured ACP Client Sample
//
// This sample demonstrates a complete ACP client with:
// - Process spawning to connect to external agents
// - Interactive console UI with streaming responses
// - File system operations (read/write)
// - Terminal operations (process execution)
// - Permission request handling
//
// Usage:
//   # Connect to GitHub Copilot agent
//   swift run InteractiveClient copilot --acp
//
//   # Connect to Gemini agent
//   swift run InteractiveClient gemini --experimental-acp
//
//   # Connect to any agent via command
//   swift run InteractiveClient <command> [args...]

import ACP
import ACPModel
import Foundation

// MARK: - Terminal Manager Actor

/// Thread-safe terminal process manager using actor isolation.
actor TerminalManager {
    /// Active terminal processes keyed by terminal ID.
    private var activeTerminals: [String: Process] = [:]

    /// Output pipes for terminals.
    private var terminalOutputPipes: [String: Pipe] = [:]

    /// Error pipes for terminals.
    private var terminalErrorPipes: [String: Pipe] = [:]

    /// Create a new terminal and store it.
    func createTerminal(
        terminalId: String,
        process: Process,
        outputPipe: Pipe,
        errorPipe: Pipe
    ) {
        activeTerminals[terminalId] = process
        terminalOutputPipes[terminalId] = outputPipe
        terminalErrorPipes[terminalId] = errorPipe
    }

    /// Get pipes for a terminal.
    func getPipes(terminalId: String) -> (output: Pipe, error: Pipe)? {
        guard let outputPipe = terminalOutputPipes[terminalId],
              let errorPipe = terminalErrorPipes[terminalId] else {
            return nil
        }
        return (outputPipe, errorPipe)
    }

    /// Get a terminal process.
    func getProcess(terminalId: String) -> Process? {
        return activeTerminals[terminalId]
    }

    /// Remove and return a terminal.
    func removeTerminal(terminalId: String) -> Process? {
        let process = activeTerminals.removeValue(forKey: terminalId)
        terminalOutputPipes.removeValue(forKey: terminalId)
        terminalErrorPipes.removeValue(forKey: terminalId)
        return process
    }
}

// MARK: - Interactive Client Implementation

/// Full-featured client that connects to agents and provides interactive chat.
final class InteractiveClient: Client, ClientSessionOperations, @unchecked Sendable {

    // MARK: - Terminal Process Management

    /// Actor for thread-safe terminal management.
    private let terminalManager = TerminalManager()

    // MARK: - Client Protocol

    var capabilities: ClientCapabilities {
        ClientCapabilities(
            fs: FileSystemCapability(
                readTextFile: true,
                writeTextFile: true
            ),
            terminal: true
        )
    }

    var info: Implementation? {
        Implementation(name: "InteractiveClient", version: "1.0.0")
    }

    func onSessionUpdate(_ update: SessionUpdate) async {
        // Updates are handled inline during prompt streaming
    }

    func onConnected() async {
        // Connection handled in main flow
    }

    func onDisconnected(error: Error?) async {
        if let error = error {
            printError("Disconnected: \(error.localizedDescription)")
        }
    }

    // MARK: - Permission Requests

    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        print()
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║  PERMISSION REQUEST                                          ║")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║  Tool: \(toolCall.title ?? "Unknown")".padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
        if let kind = toolCall.kind {
            print("║  Kind: \(kind)".padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
        }
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║  Choose an option:                                           ║")

        for (index, option) in permissions.enumerated() {
            let line = "║  [\(index + 1)] \(option.name)"
            print(line.padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
        }
        print("╚══════════════════════════════════════════════════════════════╝")
        print()

        while true {
            print("Enter option number (1-\(permissions.count)): ", terminator: "")
            guard let input = readLine(),
                  let choice = Int(input),
                  choice >= 1 && choice <= permissions.count else {
                printError("Invalid choice. Please enter a number between 1 and \(permissions.count).")
                continue
            }

            let selectedOption = permissions[choice - 1]
            print("✓ Selected: \(selectedOption.name)")
            print()

            return RequestPermissionResponse(
                outcome: .selected(selectedOption.optionId)
            )
        }
    }

    func notify(notification: SessionUpdate, meta: MetaField?) async {
        print()
        renderUpdate(notification)
    }

    // MARK: - File System Operations

    func readTextFile(
        path: String,
        line: UInt32?,
        limit: UInt32?,
        meta: MetaField?
    ) async throws -> ReadTextFileResponse {
        printInfo("📖 Reading file: \(path)")

        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)

        // Handle line range if specified
        if let startLine = line {
            let lines = content.components(separatedBy: .newlines)
            let start = max(0, Int(startLine) - 1)
            let end: Int
            if let lim = limit {
                end = min(lines.count, start + Int(lim))
            } else {
                end = lines.count
            }

            let selectedLines = Array(lines[start..<end])
            return ReadTextFileResponse(content: selectedLines.joined(separator: "\n"))
        }

        return ReadTextFileResponse(content: content)
    }

    func writeTextFile(
        path: String,
        content: String,
        meta: MetaField?
    ) async throws -> WriteTextFileResponse {
        printInfo("📝 Writing file: \(path)")

        let url = URL(fileURLWithPath: path)

        // Create parent directories if needed
        let parentDir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        try content.write(to: url, atomically: true, encoding: .utf8)

        return WriteTextFileResponse()
    }

    // MARK: - Terminal Operations

    func terminalCreate(request: CreateTerminalRequest) async throws -> CreateTerminalResponse {
        printInfo("🖥️  Creating terminal: \(request.command) \(request.args.joined(separator: " "))")

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [request.command] + request.args
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        if let cwd = request.cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }

        // Set environment variables
        var environment = ProcessInfo.processInfo.environment
        for envVar in request.env {
            environment[envVar.name] = envVar.value
        }
        process.environment = environment

        try process.run()

        let terminalId = UUID().uuidString

        await terminalManager.createTerminal(
            terminalId: terminalId,
            process: process,
            outputPipe: outputPipe,
            errorPipe: errorPipe
        )

        return CreateTerminalResponse(terminalId: terminalId)
    }

    func terminalOutput(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> TerminalOutputResponse {
        guard let pipes = await terminalManager.getPipes(terminalId: terminalId) else {
            throw ClientError.requestFailed("Terminal not found: \(terminalId)")
        }

        let stdout = pipes.output.fileHandleForReading.availableData
        let stderr = pipes.error.fileHandleForReading.availableData

        var output = String(data: stdout, encoding: .utf8) ?? ""
        if let errStr = String(data: stderr, encoding: .utf8), !errStr.isEmpty {
            output += "\nSTDERR:\n\(errStr)"
        }

        return TerminalOutputResponse(output: output, truncated: false)
    }

    func terminalRelease(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> ReleaseTerminalResponse {
        if let process = await terminalManager.removeTerminal(terminalId: terminalId) {
            if process.isRunning {
                process.terminate()
            }
        }
        return ReleaseTerminalResponse()
    }

    func terminalWaitForExit(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> WaitForTerminalExitResponse {
        guard let process = await terminalManager.getProcess(terminalId: terminalId) else {
            throw ClientError.requestFailed("Terminal not found: \(terminalId)")
        }

        process.waitUntilExit()

        return WaitForTerminalExitResponse(exitCode: UInt32(process.terminationStatus))
    }

    func terminalKill(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> KillTerminalCommandResponse {
        if let process = await terminalManager.getProcess(terminalId: terminalId), process.isRunning {
            process.terminate()
        }

        return KillTerminalCommandResponse()
    }

    // MARK: - Session Update Rendering

    func renderUpdate(_ update: SessionUpdate) {
        switch update {
        case .agentMessageChunk(let chunk):
            // Print agent message inline (no newline)
            print(renderContent(chunk.content), terminator: "")
            fflush(stdout)

        case .agentThoughtChunk(let chunk):
            print("💭 \(renderContent(chunk.content))", terminator: "")
            fflush(stdout)

        case .userMessageChunk(let chunk):
            print("You: \(renderContent(chunk.content))")

        case .toolCall(let call):
            print()
            print("🔧 Tool call: \(call.title ?? "Unknown") (\(call.kind?.rawValue ?? ""))")

        case .toolCallUpdate(let update):
            print("   → \(update.title ?? ""): \(update.status?.rawValue ?? "")")

        case .planUpdate(let plan):
            print()
            print("📋 Plan:")
            for entry in plan.entries {
                let statusIcon: String
                switch entry.status {
                case .completed: statusIcon = "✅"
                case .inProgress: statusIcon = "🔄"
                case .pending: statusIcon = "⏳"
                }
                print("   \(statusIcon) \(entry.content)")
            }

        case .currentModeUpdate(let mode):
            print("🎯 Mode changed to: \(mode.currentModeId.value)")

        case .availableCommandsUpdate:
            print("📝 Available commands updated")

        case .configOptionUpdate:
            print("⚙️  Configuration updated")

        case .sessionInfoUpdate(let info):
            if let title = info.title {
                print("📌 Session: \(title)")
            }
        }
    }

    func renderContent(_ content: ContentBlock) -> String {
        switch content {
        case .text(let text):
            return text.text
        case .image:
            return "[Image]"
        case .audio:
            return "[Audio]"
        case .resourceLink(let link):
            return "[Resource: \(link.uri)]"
        case .resource:
            return "[Embedded Resource]"
        }
    }

    // MARK: - Helpers

    func printInfo(_ message: String) {
        FileHandle.standardError.write(Data("ℹ️  \(message)\n".utf8))
    }

    func printError(_ message: String) {
        FileHandle.standardError.write(Data("❌ \(message)\n".utf8))
    }
}

// MARK: - Process Transport

/// Creates a transport connected to an external process via stdin/stdout.
func createProcessTransport(command: String, arguments: [String]) throws -> (StdioTransport, Process) {
    let process = Process()
    let stdinPipe = Pipe()
    let stdoutPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + arguments
    process.standardInput = stdinPipe
    process.standardOutput = stdoutPipe
    process.standardError = FileHandle.standardError  // Pass through agent errors

    try process.run()

    let transport = StdioTransport(
        input: stdoutPipe.fileHandleForReading,
        output: stdinPipe.fileHandleForWriting
    )

    return (transport, process)
}

// MARK: - Main Entry Point

@main
struct InteractiveClientMain {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        // Show usage if no command provided
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let command = args[0]
        let commandArgs = Array(args.dropFirst())

        print()
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║           ACP Interactive Client                             ║")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║  Starting agent: \(command)".padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print()

        do {
            // Create process transport
            let (transport, process) = try createProcessTransport(command: command, arguments: commandArgs)

            // Create client
            let client = InteractiveClient()

            // Create connection
            let connection = ClientConnection(transport: transport, client: client)

            // Connect and initialize
            print("Connecting to agent...")
            let agentInfo = try await connection.connect()

            if let info = agentInfo {
                print("✓ Connected to: \(info.name) v\(info.version)")
            } else {
                print("✓ Connected to agent")
            }
            print()

            // Create session
            print("Creating session...")
            let cwd = FileManager.default.currentDirectoryPath
            let sessionResponse = try await connection.createSession(
                request: NewSessionRequest(cwd: cwd, mcpServers: [])
            )
            print("✓ Session created: \(sessionResponse.sessionId.value)")
            print()

            print("═══════════════════════════════════════════════════════════════")
            print("  Type your messages below. Commands:")
            print("    'exit', 'quit', 'bye' - Exit the client")
            print("    Ctrl+C                - Cancel current request")
            print("═══════════════════════════════════════════════════════════════")
            print()

            // Interactive chat loop
            await runChatLoop(connection: connection, sessionId: sessionResponse.sessionId, client: client)

            // Cleanup
            print()
            print("Disconnecting...")
            await connection.disconnect()
            process.terminate()
            print("Goodbye! 👋")

        } catch {
            FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        ACP Interactive Client

        Usage:
          swift run InteractiveClient <command> [args...]

        Examples:
          swift run InteractiveClient copilot --acp
          swift run InteractiveClient gemini --experimental-acp

        Description:
          Connects to an ACP agent via stdio and provides an interactive
          chat interface. Supports file system operations, terminal
          execution, and permission requests.

        Features:
          • Interactive console chat with streaming responses
          • File system read/write operations
          • Terminal command execution
          • Permission request handling with user prompts
          • Real-time session updates

        """)
    }

    static func runChatLoop(connection: ClientConnection, sessionId: SessionId, client: InteractiveClient) async {
        while true {
            print("You: ", terminator: "")
            fflush(stdout)

            guard let input = readLine() else {
                // EOF (Ctrl+D)
                break
            }

            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check exit commands
            if trimmed.lowercased() == "exit" ||
               trimmed.lowercased() == "quit" ||
               trimmed.lowercased() == "bye" {
                break
            }

            // Skip empty input
            if trimmed.isEmpty {
                continue
            }

            do {
                let promptRequest = PromptRequest(
                    sessionId: sessionId,
                    prompt: [.text(TextContent(text: trimmed))]
                )

                print()
                print("Agent: ", terminator: "")
                fflush(stdout)

                let response = try await connection.prompt(request: promptRequest)

                // Ensure we end the line after agent response
                print()

                // Show stop reason if not normal
                switch response.stopReason {
                case .endTurn:
                    break  // Normal completion
                case .maxTokens:
                    print("[Response truncated - token limit reached]")
                case .maxTurnRequests:
                    print("[Turn limit reached]")
                case .refusal:
                    print("[Agent declined to respond]")
                case .cancelled:
                    print("[Response cancelled]")
                }

                print()

            } catch {
                print()
                FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8))
                print()
            }
        }
    }
}
