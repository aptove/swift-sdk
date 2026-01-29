import ACPModel
import Foundation

/// Implementation of AgentContext that makes remote calls to the client.
///
/// This class is used internally by AgentConnection to provide client operations
/// to agents during prompt handling.
internal final class RemoteClientOperations: AgentContext, @unchecked Sendable {
    public let sessionId: SessionId
    public let clientCapabilities: ClientCapabilities
    private let protocolLayer: Protocol

    init(
        sessionId: SessionId,
        clientCapabilities: ClientCapabilities,
        protocolLayer: Protocol
    ) {
        self.sessionId = sessionId
        self.clientCapabilities = clientCapabilities
        self.protocolLayer = protocolLayer
    }

    // MARK: - Permission Operations

    public func requestPermissions(
        toolCall: ToolCallUpdateData,
        permissions: [PermissionOption],
        meta: MetaField?
    ) async throws -> RequestPermissionResponse {
        let request = RequestPermissionRequest(
            sessionId: sessionId,
            toolCall: toolCall,
            options: permissions,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "session/request_permission",
            params: request
        )
        return try decodeResult(response.result, as: RequestPermissionResponse.self)
    }

    public func notify(notification: SessionUpdate, meta: MetaField?) async throws {
        let request = SessionNotification(
            sessionId: sessionId,
            update: notification,
            meta: meta
        )
        try await protocolLayer.sendNotification(
            method: "session/update",
            params: request
        )
    }

    // MARK: - File System Operations

    public func readTextFile(
        path: String,
        line: UInt32?,
        limit: UInt32?,
        meta: MetaField?
    ) async throws -> ReadTextFileResponse {
        guard clientCapabilities.fs?.readTextFile == true else {
            throw AgentContextError.capabilityNotSupported("fs.readTextFile")
        }

        let request = ReadTextFileRequest(
            sessionId: sessionId,
            path: path,
            line: line,
            limit: limit,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "fs/readTextFile",
            params: request
        )
        return try decodeResult(response.result, as: ReadTextFileResponse.self)
    }

    public func writeTextFile(
        path: String,
        content: String,
        meta: MetaField?
    ) async throws -> WriteTextFileResponse {
        guard clientCapabilities.fs?.writeTextFile == true else {
            throw AgentContextError.capabilityNotSupported("fs.writeTextFile")
        }

        let request = WriteTextFileRequest(
            sessionId: sessionId,
            path: path,
            content: content,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "fs/writeTextFile",
            params: request
        )
        return try decodeResult(response.result, as: WriteTextFileResponse.self)
    }

    // MARK: - Terminal Operations

    public func terminalCreate(
        command: String,
        args: [String],
        cwd: String?,
        env: [EnvVariable],
        outputByteLimit: UInt64?,
        meta: MetaField?
    ) async throws -> CreateTerminalResponse {
        guard clientCapabilities.terminal else {
            throw AgentContextError.capabilityNotSupported("terminal")
        }

        let request = CreateTerminalRequest(
            sessionId: sessionId,
            command: command,
            args: args,
            cwd: cwd,
            env: env,
            outputByteLimit: outputByteLimit,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "terminal/create",
            params: request
        )
        return try decodeResult(response.result, as: CreateTerminalResponse.self)
    }

    public func terminalOutput(
        terminalId: String,
        meta: MetaField?
    ) async throws -> TerminalOutputResponse {
        guard clientCapabilities.terminal else {
            throw AgentContextError.capabilityNotSupported("terminal")
        }

        let request = TerminalOutputRequest(
            sessionId: sessionId,
            terminalId: terminalId,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "terminal/output",
            params: request
        )
        return try decodeResult(response.result, as: TerminalOutputResponse.self)
    }

    public func terminalWaitForExit(
        terminalId: String,
        meta: MetaField?
    ) async throws -> WaitForTerminalExitResponse {
        guard clientCapabilities.terminal else {
            throw AgentContextError.capabilityNotSupported("terminal")
        }

        let request = WaitForTerminalExitRequest(
            sessionId: sessionId,
            terminalId: terminalId,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "terminal/waitForExit",
            params: request
        )
        return try decodeResult(response.result, as: WaitForTerminalExitResponse.self)
    }

    public func terminalKill(
        terminalId: String,
        meta: MetaField?
    ) async throws -> KillTerminalCommandResponse {
        guard clientCapabilities.terminal else {
            throw AgentContextError.capabilityNotSupported("terminal")
        }

        let request = KillTerminalCommandRequest(
            sessionId: sessionId,
            terminalId: terminalId,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "terminal/kill",
            params: request
        )
        return try decodeResult(response.result, as: KillTerminalCommandResponse.self)
    }

    public func terminalRelease(
        terminalId: String,
        meta: MetaField?
    ) async throws -> ReleaseTerminalResponse {
        guard clientCapabilities.terminal else {
            throw AgentContextError.capabilityNotSupported("terminal")
        }

        let request = ReleaseTerminalRequest(
            sessionId: sessionId,
            terminalId: terminalId,
            meta: meta
        )
        let response = try await protocolLayer.sendRequest(
            method: "terminal/release",
            params: request
        )
        return try decodeResult(response.result, as: ReleaseTerminalResponse.self)
    }

    // MARK: - Helper Methods

    private func decodeResult<T: Decodable>(_ result: JsonValue?, as type: T.Type) throws -> T {
        guard let result = result else {
            throw AgentContextError.operationFailed("Missing response result")
        }
        let data = try JSONEncoder().encode(result)
        return try JSONDecoder().decode(type, from: data)
    }
}
