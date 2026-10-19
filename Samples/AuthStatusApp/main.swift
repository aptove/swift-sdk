// AuthStatusApp - Auth Status for V1 and V2 Agents
//
// Spawns an external ACP agent process and queries auth/status using
// both the v1 and v2 protocols, showing the results side by side.
//
// Mirrors the Kotlin SDK's AuthStatusApp.
//
// Usage:
//   swift run AuthStatusApp <command> [args...]
//
// Examples:
//   swift run AuthStatusApp gemini --experimental-acp

import ACP
import ACPModel
import Foundation

// MARK: - Process Transport

func makeProcessTransport(command: String, arguments: [String]) throws -> (StdioTransport, Process) {
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

// MARK: - Auth Status Queries

/// Queries auth/status using the v1 protocol.
func v1AuthStatus(command: String, arguments: [String]) async throws -> AuthStatusResponse {
    let (transport, process) = try makeProcessTransport(command: command, arguments: arguments)
    defer { process.terminate() }

    let proto = Protocol(transport: transport)
    try await proto.start()

    _ = try await proto.request(
        method: "initialize",
        params: InitializeRequest(
            protocolVersion: .current,
            clientCapabilities: ClientCapabilities(),
            clientInfo: Implementation(name: "AuthStatusApp", version: "1.0.0")
        ),
        responseType: InitializeResponse.self
    )

    let response = try await proto.request(
        method: "auth/status",
        params: AuthStatusRequest(),
        responseType: AuthStatusResponse.self
    )

    await proto.close()
    return response
}

/// Queries auth/status using the v2 protocol.
func v2AuthStatus(command: String, arguments: [String]) async throws -> AuthStatusResponse {
    let (transport, process) = try makeProcessTransport(command: command, arguments: arguments)
    defer { process.terminate() }

    let proto = Protocol(transport: transport)
    try await proto.start()

    _ = try await proto.request(
        method: "initialize",
        params: V2InitializeRequest(
            protocolVersion: .v2,
            info: Implementation(name: "AuthStatusApp", version: "1.0.0")
        ),
        responseType: V2InitializeResponse.self
    )

    let response = try await proto.request(
        method: "auth/status",
        params: AuthStatusRequest(),
        responseType: AuthStatusResponse.self
    )

    await proto.close()
    return response
}

// MARK: - Main

@main
struct AuthStatusAppMain {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        guard !args.isEmpty, !args.contains("--help") else {
            print("""
            AuthStatusApp - ACP Auth Status Checker

            Usage:
              swift run AuthStatusApp <command> [args...]

            Examples:
              swift run AuthStatusApp gemini --experimental-acp
            """)
            return
        }

        let command = args[0]
        let commandArgs = Array(args.dropFirst())

        print("Auth Status for: \(([command] + commandArgs).joined(separator: " "))")
        print()

        // V1 auth status
        print("V1 auth/status:")
        do {
            let status = try await v1AuthStatus(command: command, arguments: commandArgs)
            let icon = status.authenticated ? "✓" : "✗"
            print("  \(icon) authenticated=\(status.authenticated)")
            if let message = status.message {
                print("  message: \(message)")
            }
        } catch {
            print("  Error: \(error.localizedDescription)")
        }

        print()

        // V2 auth status
        print("V2 auth/status:")
        do {
            let status = try await v2AuthStatus(command: command, arguments: commandArgs)
            let icon = status.authenticated ? "✓" : "✗"
            print("  \(icon) authenticated=\(status.authenticated)")
            if let message = status.message {
                print("  message: \(message)")
            }
        } catch {
            print("  Error: \(error.localizedDescription)")
        }
    }
}
