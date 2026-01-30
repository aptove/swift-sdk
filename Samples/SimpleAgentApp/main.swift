// SimpleAgentApp - In-Process Agent + Client Demo
//
// This sample demonstrates running both an agent AND a client
// in the same process, connected via in-memory pipes.
//
// This is useful for:
// - Testing agent/client interactions without external processes
// - Demonstrating the full ACP protocol flow
// - Learning how agent and client communicate
//
// Usage:
//   swift run SimpleAgentApp

import ACP
import ACPModel
import Foundation

// MARK: - In-Memory Pipe Transport

/// A bidirectional pipe transport for in-process communication.
/// Creates two connected transports where messages sent on one
/// side are received on the other.
final class InMemoryPipeTransport: Transport, @unchecked Sendable {
    let state: AsyncStream<TransportState>
    let messages: AsyncStream<JsonRpcMessage>

    private let stateContinuation: AsyncStream<TransportState>.Continuation
    private let messagesContinuation: AsyncStream<JsonRpcMessage>.Continuation
    private weak var peer: InMemoryPipeTransport?

    private init() {
        var stateCont: AsyncStream<TransportState>.Continuation?
        self.state = AsyncStream { stateCont = $0 }
        self.stateContinuation = stateCont!

        var msgCont: AsyncStream<JsonRpcMessage>.Continuation?
        self.messages = AsyncStream { msgCont = $0 }
        self.messagesContinuation = msgCont!

        stateContinuation.yield(.created)
    }

    /// Create a connected pair of transports.
    static func createPair() -> (client: InMemoryPipeTransport, agent: InMemoryPipeTransport) {
        let clientTransport = InMemoryPipeTransport()
        let agentTransport = InMemoryPipeTransport()
        clientTransport.peer = agentTransport
        agentTransport.peer = clientTransport
        return (clientTransport, agentTransport)
    }

    func start() async throws {
        stateContinuation.yield(.starting)
        stateContinuation.yield(.started)
    }

    func send(_ message: JsonRpcMessage) async throws {
        guard let peer = peer else {
            fatalError("InMemoryPipeTransport: no peer connected")
        }
        // Deliver to the peer's message stream
        peer.receive(message)
    }

    func close() async {
        stateContinuation.yield(.closing)
        stateContinuation.yield(.closed)
        stateContinuation.finish()
        messagesContinuation.finish()
    }

    // Called by peer to deliver a message
    fileprivate func receive(_ message: JsonRpcMessage) {
        messagesContinuation.yield(message)
    }
}

// MARK: - Simple Agent Implementation

/// A demonstration agent that echoes messages and demonstrates ACP features.
final class SimpleAgent: Agent, @unchecked Sendable {

    var capabilities: AgentCapabilities {
        AgentCapabilities(
            loadSession: false,
            promptCapabilities: PromptCapabilities(
                audio: false,
                image: false,
                embeddedContext: true
            )
        )
    }

    var info: Implementation? {
        Implementation(name: "SimpleAgent", version: "1.0.0")
    }

    func createSession(request: NewSessionRequest) async throws -> NewSessionResponse {
        let sessionId = SessionId()
        print("🤖 Agent: Created session \(sessionId.value)")
        return NewSessionResponse(sessionId: sessionId)
    }

    func handlePrompt(request: PromptRequest, context: AgentContext) async throws -> PromptResponse {
        print("🤖 Agent: Processing prompt for session \(request.sessionId.value)")

        // Extract text from the prompt
        let userText = request.prompt.compactMap { block -> String? in
            if case .text(let content) = block {
                return content.text
            }
            return nil
        }.joined(separator: " ")

        print("🤖 Agent: Received: \(userText)")

        // Send a plan update
        try await context.notify(notification: .planUpdate(PlanUpdate(entries: [
            PlanEntry(content: "Process user input", priority: .high, status: .inProgress),
            PlanEntry(content: "Generate response", priority: .high, status: .pending),
            PlanEntry(content: "Execute tools if needed", priority: .medium, status: .pending)
        ])))

        // Echo the user's message back
        try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
            content: .text(TextContent(text: "Hello! I received your message: \"\(userText)\"\n"))
        )))

        // Simulate a tool call
        let toolCallId = ToolCallId(value: UUID().uuidString)
        try await context.notify(notification: .toolCallUpdate(ToolCallUpdateData(
            toolCallId: toolCallId,
            title: "Processing request",
            kind: .think,
            status: .inProgress
        )))

        // Simulate some processing time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        try await context.notify(notification: .toolCallUpdate(ToolCallUpdateData(
            toolCallId: toolCallId,
            title: "Processing request",
            kind: .think,
            status: .completed
        )))

        // Demonstrate file system operations if client supports them
        let clientCapabilities = context.clientCapabilities
        if clientCapabilities.fs?.readTextFile == true {
            try await demonstrateFileSystemOperations(context: context)
        }

        // Demonstrate terminal operations if client supports them
        if clientCapabilities.terminal == true {
            try await demonstrateTerminalOperations(context: context)
        }

        // Update plan to completed
        try await context.notify(notification: .planUpdate(PlanUpdate(entries: [
            PlanEntry(content: "Process user input", priority: .high, status: .completed),
            PlanEntry(content: "Generate response", priority: .high, status: .completed),
            PlanEntry(content: "Execute tools if needed", priority: .medium, status: .completed)
        ])))

        // Final response
        try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
            content: .text(TextContent(text: "\n✅ All operations completed successfully!"))
        )))

        return PromptResponse(stopReason: .endTurn)
    }

    private func demonstrateFileSystemOperations(context: AgentContext) async throws {
        try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
            content: .text(TextContent(text: "\n📁 Demonstrating file system operations...\n"))
        )))

        // Write a test file
        let testPath = "/tmp/acp_simple_agent_test.txt"
        let testContent = "Hello from SimpleAgent! Written at \(Date())"

        do {
            _ = try await context.writeTextFile(path: testPath, content: testContent)

            try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
                content: .text(TextContent(text: "   ✓ Wrote file: \(testPath)\n"))
            )))

            // Read the file back
            let readResponse = try await context.readTextFile(path: testPath)

            try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
                content: .text(TextContent(text: "   ✓ Read back: \(readResponse.content)\n"))
            )))
        } catch {
            try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
                content: .text(TextContent(text: "   ✗ File operation failed: \(error)\n"))
            )))
        }
    }

    private func demonstrateTerminalOperations(context: AgentContext) async throws {
        try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
            content: .text(TextContent(text: "\n🖥️  Demonstrating terminal operations...\n"))
        )))

        do {
            // Execute a simple command
            let createResponse = try await context.terminalCreate(
                command: "echo",
                args: ["Hello from terminal!"]
            )

            let exitResponse = try await context.terminalWaitForExit(
                terminalId: createResponse.terminalId,
                meta: nil
            )

            let outputResponse = try await context.terminalOutput(
                terminalId: createResponse.terminalId,
                meta: nil
            )

            _ = try await context.terminalRelease(
                terminalId: createResponse.terminalId,
                meta: nil
            )

            let outputText = outputResponse.output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
                content: .text(TextContent(text: "   ✓ Terminal output: \(outputText) (exit code: \(exitResponse.exitCode ?? 0))\n"))
            )))
        } catch {
            try await context.notify(notification: .agentMessageChunk(AgentMessageChunk(
                content: .text(TextContent(text: "   ✗ Terminal operation failed: \(error)\n"))
            )))
        }
    }
}

// MARK: - Simple Client Implementation

/// A simple client that handles agent callbacks.
final class SimpleAgentClient: Client, ClientSessionOperations, @unchecked Sendable {

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
        Implementation(name: "SimpleAgentClient", version: "1.0.0")
    }

    func onSessionUpdate(_ update: SessionUpdate) async {
        // Render session updates
        renderUpdate(update)
    }

    func onConnected() async {
        print("📱 Client: Connected to agent")
    }

    func onDisconnected(error: Error?) async {
        if let error = error {
            print("📱 Client: Disconnected with error: \(error)")
        } else {
            print("📱 Client: Disconnected")
        }
    }

    // MARK: - ClientSessionOperations

    func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        print("📱 Client: Permission requested for \(toolCall.title ?? "unknown")")
        // Auto-approve for demo
        if let first = permissions.first {
            return RequestPermissionResponse(outcome: .selected(first.optionId))
        }
        return RequestPermissionResponse(outcome: .cancelled)
    }

    func notify(notification: SessionUpdate, meta: MetaField?) async {
        renderUpdate(notification)
    }

    // MARK: - FileSystemOperations

    func readTextFile(
        path: String,
        line: UInt32?,
        limit: UInt32?,
        meta: MetaField?
    ) async throws -> ReadTextFileResponse {
        print("📱 Client: Reading file \(path)")
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return ReadTextFileResponse(content: content)
    }

    func writeTextFile(
        path: String,
        content: String,
        meta: MetaField?
    ) async throws -> WriteTextFileResponse {
        print("📱 Client: Writing file \(path)")
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return WriteTextFileResponse()
    }

    // MARK: - TerminalOperations

    private var processes: [String: Process] = [:]
    private var outputPipes: [String: Pipe] = [:]

    func terminalCreate(request: CreateTerminalRequest) async throws -> CreateTerminalResponse {
        print("📱 Client: Creating terminal for \(request.command)")

        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [request.command] + request.args
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()

        let terminalId = UUID().uuidString
        processes[terminalId] = process
        outputPipes[terminalId] = outputPipe

        return CreateTerminalResponse(terminalId: terminalId)
    }

    func terminalOutput(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> TerminalOutputResponse {
        guard let pipe = outputPipes[terminalId] else {
            throw ClientError.requestFailed("Terminal not found")
        }
        let data = pipe.fileHandleForReading.availableData
        let output = String(data: data, encoding: .utf8) ?? ""
        return TerminalOutputResponse(output: output, truncated: false)
    }

    func terminalRelease(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> ReleaseTerminalResponse {
        if let process = processes.removeValue(forKey: terminalId) {
            if process.isRunning { process.terminate() }
        }
        outputPipes.removeValue(forKey: terminalId)
        return ReleaseTerminalResponse()
    }

    func terminalWaitForExit(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> WaitForTerminalExitResponse {
        guard let process = processes[terminalId] else {
            throw ClientError.requestFailed("Terminal not found")
        }
        process.waitUntilExit()
        return WaitForTerminalExitResponse(exitCode: UInt32(process.terminationStatus))
    }

    func terminalKill(
        sessionId: SessionId,
        terminalId: String,
        meta: MetaField?
    ) async throws -> KillTerminalCommandResponse {
        if let process = processes[terminalId], process.isRunning {
            process.terminate()
        }
        return KillTerminalCommandResponse()
    }

    // MARK: - Rendering

    func renderUpdate(_ update: SessionUpdate) {
        switch update {
        case .agentMessageChunk(let chunk):
            if case .text(let text) = chunk.content {
                print(text.text, terminator: "")
                fflush(stdout)
            }
        case .agentThoughtChunk(let chunk):
            if case .text(let text) = chunk.content {
                print("💭 \(text.text)", terminator: "")
            }
        case .toolCall(let call):
            print("🔧 Tool: \(call.title)")
        case .toolCallUpdate(let update):
            if let status = update.status {
                print("   → \(update.title ?? ""): \(status.rawValue)")
            }
        case .planUpdate(let plan):
            print("\n📋 Plan:")
            for entry in plan.entries {
                let icon: String
                switch entry.status {
                case .completed: icon = "✅"
                case .inProgress: icon = "🔄"
                case .pending: icon = "⏳"
                }
                print("   \(icon) \(entry.content)")
            }
            print()
        default:
            break
        }
    }
}

// MARK: - Main Entry Point

@main
struct SimpleAgentAppMain {
    static func main() async {
        print()
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║           SimpleAgentApp - In-Process Demo                   ║")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║  Running both agent and client in the same process           ║")
        print("║  connected via in-memory message passing.                    ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print()

        // Create connected transport pair
        let (clientTransport, agentTransport) = InMemoryPipeTransport.createPair()

        // Create agent and client
        let agent = SimpleAgent()
        let client = SimpleAgentClient()

        // Create connections
        let agentConnection = AgentConnection(transport: agentTransport, agent: agent)
        let clientConnection = ClientConnection(transport: clientTransport, client: client)

        do {
            // Start agent in background task
            print("Starting agent...")
            let agentTask = Task {
                try await agentConnection.start()
                await agentConnection.waitUntilComplete()
            }

            // Give agent a moment to start
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms

            // Connect client
            print("Connecting client...")
            let agentInfo = try await clientConnection.connect()

            if let info = agentInfo {
                print("✓ Connected to: \(info.name) v\(info.version)")
            }
            print()

            // Create session
            let cwd = FileManager.default.currentDirectoryPath
            let sessionResponse = try await clientConnection.createSession(
                request: NewSessionRequest(cwd: cwd, mcpServers: [])
            )
            print("✓ Session created: \(sessionResponse.sessionId.value)")
            print()

            print("═══════════════════════════════════════════════════════════════")
            print("  Type your messages. Commands: 'exit' to quit")
            print("═══════════════════════════════════════════════════════════════")
            print()

            // Interactive loop
            while true {
                print("You: ", terminator: "")
                fflush(stdout)

                guard let input = readLine() else { break }

                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.lowercased() == "exit" { break }
                if trimmed.isEmpty { continue }

                print()
                print("Agent: ", terminator: "")
                fflush(stdout)

                let response = try await clientConnection.prompt(request: PromptRequest(
                    sessionId: sessionResponse.sessionId,
                    prompt: [.text(TextContent(text: trimmed))]
                ))

                print()
                print("(Stop reason: \(response.stopReason))")
                print()
            }

            // Cleanup
            print()
            print("Shutting down...")
            await clientConnection.disconnect()
            await agentConnection.stop()
            agentTask.cancel()
            print("Goodbye! 👋")

        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}
