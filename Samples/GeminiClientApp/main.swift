// GeminiClientApp - Interactive ACP Client
//
// Connects to an external ACP agent via stdio and provides an interactive
// terminal chat interface. Modelled after the Kotlin SDK's GeminiClientApp.
//
// Usage:
//   swift run GeminiClientApp <command> [args...]
//
// Examples:
//   swift run GeminiClientApp gemini --experimental-acp
//   swift run GeminiClientApp claude --acp

import ACP
import ACPModel
import Foundation

// MARK: - Terminal Manager Actor

/// Thread-safe terminal process manager.
actor TerminalManager {
    private var processes: [String: Process] = [:]
    private var outputPipes: [String: Pipe] = [:]
    private var errorPipes: [String: Pipe] = [:]

    func add(terminalId: String, process: Process, outputPipe: Pipe, errorPipe: Pipe) {
        processes[terminalId] = process
        outputPipes[terminalId] = outputPipe
        errorPipes[terminalId] = errorPipe
    }

    func pipes(for terminalId: String) -> (output: Pipe, error: Pipe)? {
        guard let output = outputPipes[terminalId], let error = errorPipes[terminalId] else { return nil }
        return (output, error)
    }

    func process(for terminalId: String) -> Process? { processes[terminalId] }

    func remove(terminalId: String) -> Process? {
        let process = processes.removeValue(forKey: terminalId)
        outputPipes.removeValue(forKey: terminalId)
        errorPipes.removeValue(forKey: terminalId)
        return process
    }
}

// MARK: - Gemini Client

/// Full-featured interactive client for connecting to ACP agents.
final class GeminiClient: Client, ClientSessionOperations, @unchecked Sendable {
    private let terminalManager = TerminalManager()

    var capabilities: ClientCapabilities {
        ClientCapabilities(
            fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
            terminal: true
        )
    }

    var info: Implementation? {
        Implementation(name: "GeminiClientApp", version: "1.0.0")
    }

    func onSessionUpdate(_ update: SessionUpdate) async {}
    func onConnected() async {}
    func onDisconnected(error: Error?) async {
        if let error = error {
            printErr("Disconnected: \(error.localizedDescription)")
        }
    }

    // MARK: - Permissions

    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        print()
        print("Permission requested for: \(toolCall.title ?? "unknown")")
        for (i, option) in permissions.enumerated() {
            print("  [\(i + 1)] \(option.name)")
        }
        print("Enter choice (1-\(permissions.count)): ", terminator: "")
        if let input = readLine(), let choice = Int(input), choice >= 1, choice <= permissions.count {
            return RequestPermissionResponse(outcome: .selected(permissions[choice - 1].optionId))
        }
        return RequestPermissionResponse(outcome: .cancelled)
    }

    func notify(notification: SessionUpdate, meta: MetaField?) async {
        renderUpdate(notification)
    }

    // MARK: - File System

    func readTextFile(path: String, line: UInt32?, limit: UInt32?, meta: MetaField?) async throws -> ReadTextFileResponse {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        if let start = line.map({ Int($0) - 1 }) {
            let lines = content.components(separatedBy: .newlines)
            let end = limit.map { min(lines.count, start + Int($0)) } ?? lines.count
            return ReadTextFileResponse(content: Array(lines[start..<end]).joined(separator: "\n"))
        }
        return ReadTextFileResponse(content: content)
    }

    func writeTextFile(path: String, content: String, meta: MetaField?) async throws -> WriteTextFileResponse {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return WriteTextFileResponse()
    }

    // MARK: - Terminal

    func terminalCreate(request: CreateTerminalRequest) async throws -> CreateTerminalResponse {
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
        var env = ProcessInfo.processInfo.environment
        for v in request.env { env[v.name] = v.value }
        process.environment = env
        try process.run()

        let terminalId = UUID().uuidString
        await terminalManager.add(terminalId: terminalId, process: process, outputPipe: outputPipe, errorPipe: errorPipe)
        return CreateTerminalResponse(terminalId: terminalId)
    }

    func terminalOutput(sessionId: SessionId, terminalId: String, meta: MetaField?) async throws -> TerminalOutputResponse {
        guard let pipes = await terminalManager.pipes(for: terminalId) else {
            throw ClientError.requestFailed("Terminal not found: \(terminalId)")
        }
        var output = String(data: pipes.output.fileHandleForReading.availableData, encoding: .utf8) ?? ""
        if let err = String(data: pipes.error.fileHandleForReading.availableData, encoding: .utf8), !err.isEmpty {
            output += "\nSTDERR:\n\(err)"
        }
        return TerminalOutputResponse(output: output, truncated: false)
    }

    func terminalRelease(sessionId: SessionId, terminalId: String, meta: MetaField?) async throws -> ReleaseTerminalResponse {
        if let process = await terminalManager.remove(terminalId: terminalId), process.isRunning {
            process.terminate()
        }
        return ReleaseTerminalResponse()
    }

    func terminalWaitForExit(sessionId: SessionId, terminalId: String, meta: MetaField?) async throws -> WaitForTerminalExitResponse {
        guard let process = await terminalManager.process(for: terminalId) else {
            throw ClientError.requestFailed("Terminal not found: \(terminalId)")
        }
        process.waitUntilExit()
        return WaitForTerminalExitResponse(exitCode: UInt32(process.terminationStatus))
    }

    func terminalKill(sessionId: SessionId, terminalId: String, meta: MetaField?) async throws -> KillTerminalCommandResponse {
        if let process = await terminalManager.process(for: terminalId), process.isRunning {
            process.terminate()
        }
        return KillTerminalCommandResponse()
    }

    // MARK: - Rendering

    func renderUpdate(_ update: SessionUpdate) {
        switch update {
        case .agentMessageChunk(let chunk):
            if case .text(let t) = chunk.content { print(t.text, terminator: ""); fflush(stdout) }
        case .agentThoughtChunk(let chunk):
            if case .text(let t) = chunk.content { print("💭 \(t.text)", terminator: ""); fflush(stdout) }
        case .toolCallUpdate(let u):
            if let status = u.status { print("\n  [\(u.title ?? "")] \(status.rawValue)") }
        case .planUpdate(let plan):
            print("\nPlan:"); for e in plan.entries { print("  \(e.content)") }
        default:
            break
        }
    }

    func printErr(_ msg: String) {
        FileHandle.standardError.write(Data("\(msg)\n".utf8))
    }
}

// MARK: - Process Transport

func createProcessTransport(command: String, arguments: [String]) throws -> (StdioTransport, Process) {
    let process = Process()
    let stdinPipe = Pipe()
    let stdoutPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [command] + arguments
    process.standardInput = stdinPipe
    process.standardOutput = stdoutPipe
    process.standardError = FileHandle.standardError

    try process.run()

    return (
        StdioTransport(input: stdoutPipe.fileHandleForReading, output: stdinPipe.fileHandleForWriting),
        process
    )
}

// MARK: - Main

@main
struct GeminiClientAppMain {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        guard !args.isEmpty, !args.contains("--help") else {
            print("""
            GeminiClientApp - Interactive ACP Client

            Usage:
              swift run GeminiClientApp <command> [args...]

            Examples:
              swift run GeminiClientApp gemini --experimental-acp
              swift run GeminiClientApp claude --acp
            """)
            return
        }

        let command = args[0]
        let commandArgs = Array(args.dropFirst())

        do {
            let (transport, process) = try createProcessTransport(command: command, arguments: commandArgs)
            let client = GeminiClient()
            let connection = ClientConnection(transport: transport, client: client)

            print("Connecting to \(command)...")
            let agentInfo = try await connection.connect()
            if let info = agentInfo {
                print("Connected to: \(info.name) v\(info.version)")
            }

            let session = try await connection.createSession(
                request: NewSessionRequest(cwd: FileManager.default.currentDirectoryPath, mcpServers: [])
            )
            print("Session: \(session.sessionId.value)")
            print("Type your messages (exit to quit)\n")

            while true {
                print("You: ", terminator: ""); fflush(stdout)
                guard let input = readLine() else { break }
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if ["exit", "quit", "bye"].contains(trimmed.lowercased()) { break }

                print("\nAgent: ", terminator: ""); fflush(stdout)
                let response = try await connection.prompt(
                    request: PromptRequest(sessionId: session.sessionId, prompt: [.text(TextContent(text: trimmed))])
                )
                print("\n(\(response.stopReason))\n")
            }

            await connection.disconnect()
            process.terminate()
            print("Goodbye!")

        } catch {
            FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}
