// V2SimpleAgentApp - In-Process V2 Agent + V2 Client Demo
//
// Demonstrates the ACP v2 protocol with both an agent and a client
// running in the same process, connected via in-memory transport.
//
// Mirrors the Kotlin SDK's V2SimpleAgentApp.
//
// Features demonstrated:
//   - V2 initialize / session/new / session/prompt
//   - V2 session updates: stateUpdate, userMessage, agentMessageChunk
//   - session/set_config_option (response_mode: echo | uppercase)
//
// Usage:
//   swift run V2SimpleAgentApp

import ACP
import ACPModel
import Foundation

// MARK: - In-Memory Transport

/// Bidirectional in-memory transport for in-process agent/client demos.
final class InMemoryPipeTransport: Transport, @unchecked Sendable {
    let state: AsyncStream<TransportState>
    let messages: AsyncStream<JsonRpcMessage>

    private let stateContinuation: AsyncStream<TransportState>.Continuation
    private let messagesContinuation: AsyncStream<JsonRpcMessage>.Continuation
    private weak var peer: InMemoryPipeTransport?

    private init() {
        (state, stateContinuation) = AsyncStream.makeStream()
        (messages, messagesContinuation) = AsyncStream.makeStream()
        stateContinuation.yield(.created)
    }

    static func createPair() -> (client: InMemoryPipeTransport, agent: InMemoryPipeTransport) {
        let client = InMemoryPipeTransport()
        let agent = InMemoryPipeTransport()
        client.peer = agent
        agent.peer = client
        return (client, agent)
    }

    func start() async throws {
        stateContinuation.yield(.starting)
        stateContinuation.yield(.started)
    }

    func send(_ message: JsonRpcMessage) async throws {
        guard let peer else { fatalError("InMemoryPipeTransport: no peer connected") }
        peer.receive(message)
    }

    func close() async {
        stateContinuation.yield(.closing)
        stateContinuation.yield(.closed)
        stateContinuation.finish()
        messagesContinuation.finish()
    }

    fileprivate func receive(_ message: JsonRpcMessage) {
        messagesContinuation.yield(message)
    }
}

// MARK: - Simple V2 Agent Support

/// Holds per-session configuration for the demo agent.
final actor SimpleV2AgentState {
    private var responseModes: [SessionId: String] = [:]

    func createSession(_ sessionId: SessionId) {
        responseModes[sessionId] = "echo"
    }

    func setResponseMode(_ mode: String, for sessionId: SessionId) {
        responseModes[sessionId] = mode
    }

    func responseMode(for sessionId: SessionId) -> String {
        responseModes[sessionId] ?? "echo"
    }
}

// MARK: - V2 Agent Registration

/// Registers v2 protocol handlers on the given Protocol instance.
func registerV2AgentHandlers(proto: ACPProtocol, state: SimpleV2AgentState) async {
    let agentInfo = Implementation(name: "SimpleV2Agent", version: "1.0.0")

    await proto.onRequest(
        method: "initialize",
        requestType: V2InitializeRequest.self
    ) { _ in
        V2InitializeResponse(
            protocolVersion: .v2,
            info: agentInfo,
            capabilities: V2AgentCapabilities()
        )
    }

    await proto.onRequest(
        method: "session/new",
        requestType: V2NewSessionRequest.self
    ) { [state] (_: V2NewSessionRequest) in
        let sessionId = SessionId()
        await state.createSession(sessionId)
        print("🤖 Agent: Created session \(sessionId.value)")
        return V2NewSessionResponse(
            sessionId: sessionId,
            configOptions: [
                V2SessionConfigOption(
                    configId: SessionConfigId(value: "response_mode"),
                    name: "Response Mode",
                    kind: .select(
                        currentValue: SessionConfigValueId(value: "echo"),
                        options: .ungrouped([
                            SessionConfigSelectOption(value: SessionConfigValueId(value: "echo"), name: "Echo"),
                            SessionConfigSelectOption(value: SessionConfigValueId(value: "uppercase"), name: "Uppercase")
                        ])
                    )
                )
            ]
        )
    }

    await proto.onRequest(
        method: "session/set_config_option",
        requestType: V2SetSessionConfigOptionRequest.self
    ) { [state] (req: V2SetSessionConfigOptionRequest) in
        if req.configId.value == "response_mode",
           case .id(let mode) = req.value {
            await state.setResponseMode(mode.value, for: req.sessionId)
            print("🤖 Agent: Set response_mode=\(mode.value)")
        }
        return V2SetSessionConfigOptionResponse(configOptions: [])
    }

    await proto.onRequest(
        method: "session/prompt",
        requestType: V2PromptRequest.self
    ) { [proto, state] (req: V2PromptRequest) in
        let sessionId = req.sessionId
        let text = req.prompt.compactMap { block -> String? in
            if case .text(let t) = block { return t.text }
            return nil
        }.joined(separator: " ")

        print("🤖 Agent: Prompt for session \(sessionId.value): \"\(text)\"")

        let mode = await state.responseMode(for: sessionId)
        let responseText = mode == "uppercase" ? text.uppercased() : text

        // stateUpdate: running
        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: sessionId,
                update: .stateUpdate(.running(_meta: nil))
            )
        )

        // Echo the user message
        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: sessionId,
                update: .userMessage(V2UserMessage(
                    messageId: MessageId(rawValue: UUID().uuidString),
                    content: .value([.text(V2ContentBlock.Text(text: text))])
                ))
            )
        )

        // Agent response chunk
        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: sessionId,
                update: .agentMessageChunk(V2ContentChunk(
                    messageId: MessageId(rawValue: UUID().uuidString),
                    content: .text(V2ContentBlock.Text(text: responseText)),
                    _meta: nil
                ))
            )
        )

        // stateUpdate: idle
        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: sessionId,
                update: .stateUpdate(.idle(stopReason: .endTurn, usage: nil, _meta: nil))
            )
        )

        return V2PromptResponse()
    }
}

// MARK: - V2 Conversation

/// Runs a single V2 prompt turn and prints session updates as they arrive.
func runV2Conversation(proto: ACPProtocol, sessionId: SessionId, prompt: String) async throws {
    let (updateStream, updateCont) = AsyncStream<V2SessionUpdate>.makeStream()

    await proto.onNotification(method: "session/update") { notification in
        guard let params = notification.params,
              let data = try? JSONEncoder().encode(params),
              let notif = try? JSONDecoder().decode(V2UpdateSessionNotification.self, from: data) else { return }
        updateCont.yield(notif.update)
    }

    let collectTask = Task {
        for await update in updateStream {
            renderV2Update(update)
            if case .stateUpdate(.idle) = update {
                updateCont.finish()
                break
            }
        }
    }

    _ = try await proto.request(
        method: "session/prompt",
        params: V2PromptRequest(
            sessionId: sessionId,
            prompt: [.text(V2ContentBlock.Text(text: prompt))]
        ),
        responseType: V2PromptResponse.self
    )

    await collectTask.value
}

func renderV2Update(_ update: V2SessionUpdate) {
    switch update {
    case .stateUpdate(let s):
        switch s {
        case .running: print("  [running]")
        case .idle(let reason, _, _): print("  [idle: \(reason?.rawValue ?? "end_turn")]")
        default: break
        }
    case .userMessage(let msg):
        if case .value(let blocks) = msg.content {
            let text = blocks.compactMap { if case .text(let t) = $0 { return t.text } else { return nil } }.joined()
            print("  user: \(text)")
        }
    case .agentMessageChunk(let chunk):
        if case .text(let t) = chunk.content { print("  agent: \(t.text)") }
    default:
        break
    }
}

// MARK: - Main

@main
struct V2SimpleAgentAppMain {
    static func main() async {
        print()
        print("V2SimpleAgentApp - In-Process V2 Demo")
        print("======================================")
        print()

        let (clientTransport, agentTransport) = InMemoryPipeTransport.createPair()
        let agentProto = ACPProtocol(transport: agentTransport)
        let clientProto = ACPProtocol(transport: clientTransport)

        let agentState = SimpleV2AgentState()
        await registerV2AgentHandlers(proto: agentProto, state: agentState)

        do {
            try await agentProto.start()
            try await clientProto.start()

            // Initialize
            let initResp = try await clientProto.request(
                method: "initialize",
                params: V2InitializeRequest(
                    protocolVersion: .v2,
                    info: Implementation(name: "V2Client", version: "1.0.0")
                ),
                responseType: V2InitializeResponse.self
            )
            print("Connected to: \(initResp.info.name) v\(initResp.info.version) (protocol v\(initResp.protocolVersion))")

            // Create session
            let sessionResp = try await clientProto.request(
                method: "session/new",
                params: V2NewSessionRequest(cwd: FileManager.default.currentDirectoryPath),
                responseType: V2NewSessionResponse.self
            )
            let sessionId = sessionResp.sessionId
            print("Session: \(sessionId.value)")
            print()

            // Prompt 1: echo mode (default)
            print("--- Prompt 1 (echo mode): \"hello from swift\" ---")
            try await runV2Conversation(proto: clientProto, sessionId: sessionId, prompt: "hello from swift")
            print()

            // Set response_mode to uppercase
            _ = try await clientProto.request(
                method: "session/set_config_option",
                params: V2SetSessionConfigOptionRequest(
                    sessionId: sessionId,
                    configId: SessionConfigId(value: "response_mode"),
                    value: .id(SessionConfigValueId(value: "uppercase"))
                ),
                responseType: V2SetSessionConfigOptionResponse.self
            )
            print("Set response_mode = uppercase")
            print()

            // Prompt 2: uppercase mode
            print("--- Prompt 2 (uppercase mode): \"hello from swift\" ---")
            try await runV2Conversation(proto: clientProto, sessionId: sessionId, prompt: "hello from swift")

            await agentProto.close()
            await clientProto.close()

        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}
