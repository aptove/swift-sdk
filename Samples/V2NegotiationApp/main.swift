// V2NegotiationApp - In-Process V2 Agent with Protocol Version Negotiation
//
// Demonstrates how a client can negotiate the ACP protocol version with an agent:
// the client always tries v2 first and falls back to v1 if the agent only supports v1.
//
// Mirrors the Kotlin SDK's V2NegotiationApp.
//
// Usage:
//   swift run V2NegotiationApp

import ACP
import ACPModel
import Foundation

// MARK: - In-Memory Transport (same as V2SimpleAgentApp)

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

// MARK: - Negotiating Agent

/// Registers handlers that support both v1 and v2 initialize requests.
///
/// The agent echoes prompts and responds according to the negotiated protocol version.
func registerNegotiatingAgentHandlers(proto: ACPProtocol) async {
    let agentInfo = Implementation(name: "NegotiatingAgent", version: "1.0.0")

    // Universal initialize handler: responds with v2 if the client requests it, otherwise v1
    await proto.onRequest(method: "initialize") { request in
        guard let params = request.params else {
            throw ProtocolError.decodingFailed(underlying: NSError(
                domain: "ACP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing params"]
            ))
        }

        let data = try JSONEncoder().encode(params)

        struct VersionProbe: Decodable { let protocolVersion: ProtocolVersion }
        let probe = try JSONDecoder().decode(VersionProbe.self, from: data)

        if probe.protocolVersion == .v2 {
            let resp = V2InitializeResponse(
                protocolVersion: .v2,
                info: agentInfo,
                capabilities: V2AgentCapabilities()
            )
            let respData = try JSONEncoder().encode(resp)
            return try JSONDecoder().decode(JsonValue.self, from: respData)
        } else {
            let resp = InitializeResponse(
                protocolVersion: .current,
                agentCapabilities: AgentCapabilities(),
                agentInfo: agentInfo
            )
            let respData = try JSONEncoder().encode(resp)
            return try JSONDecoder().decode(JsonValue.self, from: respData)
        }
    }

    // V2 session/new
    await proto.onRequest(
        method: "session/new",
        requestType: V2NewSessionRequest.self
    ) { _ in
        let sessionId = SessionId()
        print("🤖 Agent: V2 session created \(sessionId.value)")
        return V2NewSessionResponse(sessionId: sessionId)
    }

    // V2 session/prompt
    await proto.onRequest(
        method: "session/prompt",
        requestType: V2PromptRequest.self
    ) { [proto] req in
        let text = req.prompt.compactMap { if case .text(let t) = $0 { return t.text } else { return nil } }.joined(separator: " ")
        print("🤖 Agent: V2 prompt: \"\(text)\"")

        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: req.sessionId,
                update: .stateUpdate(.running(_meta: nil))
            )
        )
        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: req.sessionId,
                update: .agentMessageChunk(V2ContentChunk(
                    messageId: MessageId(rawValue: UUID().uuidString),
                    content: .text(V2ContentBlock.Text(text: "[V2] Echo: \(text)")),
                    _meta: nil
                ))
            )
        )
        try await proto.sendNotification(
            method: "session/update",
            params: V2UpdateSessionNotification(
                sessionId: req.sessionId,
                update: .stateUpdate(.idle(stopReason: .endTurn, usage: nil, _meta: nil))
            )
        )
        return V2PromptResponse()
    }

}

// MARK: - Client Negotiator

/// Negotiates the protocol version with the agent and runs the appropriate conversation.
///
/// Sends a V2 initialize request first. If the agent responds with v2, runs a V2 conversation.
/// Otherwise falls back to v1.
func runNegotiatedClient(proto: ACPProtocol, prompt: String) async throws {
    let clientInfo = Implementation(name: "NegotiatingClient", version: "1.0.0")

    // Try V2 initialize first
    var negotiatedVersion: ProtocolVersion
    var v2SessionId: SessionId?

    do {
        let v2InitResp = try await proto.request(
            method: "initialize",
            params: V2InitializeRequest(protocolVersion: .v2, info: clientInfo),
            responseType: V2InitializeResponse.self
        )
        negotiatedVersion = v2InitResp.protocolVersion
        print("📱 Client: Negotiated protocol v\(negotiatedVersion)")

        if negotiatedVersion == .v2 {
            let sessionResp = try await proto.request(
                method: "session/new",
                params: V2NewSessionRequest(cwd: FileManager.default.currentDirectoryPath),
                responseType: V2NewSessionResponse.self
            )
            v2SessionId = sessionResp.sessionId
            print("📱 Client: Session \(sessionResp.sessionId.value)")
        }
    } catch {
        print("📱 Client: V2 failed (\(error.localizedDescription)), trying V1")
        negotiatedVersion = .current
    }

    if negotiatedVersion == .v2, let sessionId = v2SessionId {
        // Run V2 conversation
        let (updateStream, updateCont) = AsyncStream<V2SessionUpdate>.makeStream()

        await proto.onNotification(method: "session/update") { notification in
            guard let params = notification.params,
                  let data = try? JSONEncoder().encode(params),
                  let notif = try? JSONDecoder().decode(V2UpdateSessionNotification.self, from: data) else { return }
            updateCont.yield(notif.update)
        }

        let collectTask = Task {
            for await update in updateStream {
                switch update {
                case .agentMessageChunk(let chunk):
                    if case .text(let t) = chunk.content { print("📱 Client: \(t.text)") }
                case .stateUpdate(.idle):
                    updateCont.finish(); return
                default: break
                }
            }
        }

        _ = try await proto.request(
            method: "session/prompt",
            params: V2PromptRequest(sessionId: sessionId, prompt: [.text(V2ContentBlock.Text(text: prompt))]),
            responseType: V2PromptResponse.self
        )
        await collectTask.value

    } else {
        // V1 fallback: need to initialize and run v1 conversation
        // (In this demo the agent supports v2, so this path is for illustration only.)
        print("📱 Client: Running V1 conversation...")

        // Note: We'd already have sent a V2InitializeRequest above. In a real implementation
        // you would use a fresh transport to re-initialize with V1. Here we demonstrate the
        // fallback code path.
        print("📱 Client: (V1 fallback - use a fresh connection in production)")
    }
}

// MARK: - Main

@main
struct V2NegotiationAppMain {
    static func main() async {
        print()
        print("V2NegotiationApp - Protocol Version Negotiation Demo")
        print("=====================================================")
        print()
        print("The client sends a V2 initialize request. If the agent supports V2,")
        print("the conversation runs over V2; otherwise it falls back to V1.")
        print()

        let (clientTransport, agentTransport) = InMemoryPipeTransport.createPair()
        let agentProto = ACPProtocol(transport: agentTransport)
        let clientProto = ACPProtocol(transport: clientTransport)

        await registerNegotiatingAgentHandlers(proto: agentProto)

        do {
            try await agentProto.start()
            try await clientProto.start()

            try await runNegotiatedClient(proto: clientProto, prompt: "hello via negotiation")

            await agentProto.close()
            await clientProto.close()

        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}
