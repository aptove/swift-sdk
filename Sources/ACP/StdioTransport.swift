import ACPModel
import Foundation
import Logging

/// STDIO transport implementation for ACP.
///
/// This transport communicates over standard input/output streams,
/// which is commonly used for command-line agents.
///
/// ## Message Framing
///
/// Messages are framed using newline-delimited JSON (ND-JSON):
/// - Each JSON-RPC message is serialized to a single line
/// - Lines are terminated with `\n`
/// - Malformed JSON is logged and skipped
///
/// ## Usage Example
///
/// ```swift
/// let transport = StdioTransport()
///
/// // Start the transport
/// try await transport.start()
///
/// // Send a message
/// let request = JsonRpcRequest(id: .int(1), method: "initialize", params: nil)
/// try await transport.send(.request(request))
///
/// // Receive messages
/// for await message in transport.messages {
///     print("Received: \(message)")
/// }
///
/// // Clean shutdown
/// await transport.close()
/// ```
public final class StdioTransport: Transport, @unchecked Sendable {
    private let logger = Logger(label: "StdioTransport")

    private let stateActor: StateActor
    private let input: FileHandle
    private let output: FileHandle

    // Task group for managing read/write tasks
    private var taskGroup: TaskGroup<Void>?

    /// Initialize a new STDIO transport.
    ///
    /// - Parameters:
    ///   - input: File handle for reading (defaults to standard input)
    ///   - output: File handle for writing (defaults to standard output)
    public init(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) {
        self.input = input
        self.output = output
        self.stateActor = StateActor()
    }

    public var state: AsyncStream<TransportState> {
        stateActor.stateStream
    }

    public func start() async throws {
        logger.trace("Starting transport")

        // Ensure we're in created state
        try await stateActor.transitionTo(.starting)

        // Start read and write tasks
        await withTaskGroup(of: Void.self) { group in
            // Read task
            group.addTask {
                await self.readLoop()
            }

            // Write task
            group.addTask {
                await self.writeLoop()
            }

            // Transition to started
            try? await self.stateActor.transitionTo(.started)

            // Wait for both tasks to complete
            await group.waitForAll()
        }

        logger.trace("Transport stopped")
    }

    public func send(_ message: JsonRpcMessage) async throws {
        logger.trace("Enqueueing message: \(message)")
        try await stateActor.enqueue(message)
    }

    public var messages: AsyncStream<JsonRpcMessage> {
        stateActor.messageStream
    }

    public func close() async {
        logger.trace("Closing transport")
        await stateActor.close()
    }

    // MARK: - Private Methods

    private func readLoop() async {
        logger.trace("Read loop started")

        defer {
            logger.trace("Read loop exiting")
            Task { await self.close() }
        }

        do {
            while !Task.isCancelled {
                // Read a line from stdin
                guard let line = try await readLine() else {
                    logger.trace("End of stream")
                    break
                }

                // Parse JSON-RPC message
                guard let message = try? parseMessage(line) else {
                    logger.warning("Failed to parse message, skipping: \(line)")
                    continue
                }

                logger.trace("Received message: \(message)")
                await stateActor.deliver(message)
            }
        } catch {
            logger.error("Read loop error: \(error)")
            await stateActor.reportError(error)
        }
    }

    private func writeLoop() async {
        logger.trace("Write loop started")

        defer {
            logger.trace("Write loop exiting")
            Task { await self.close() }
        }

        do {
            for await message in stateActor.sendQueue {
                // Serialize to JSON
                let encoder = JSONEncoder()
                let data = try encoder.encode(message)

                guard let json = String(data: data, encoding: .utf8) else {
                    logger.error("Failed to encode message as UTF-8")
                    continue
                }

                // Write line to stdout
                try await writeLine(json)
                logger.trace("Sent message: \(message)")
            }
        } catch {
            logger.error("Write loop error: \(error)")
            await stateActor.reportError(error)
        }
    }

    private func readLine() async throws -> String? {
        // TODO: Implement proper async line reading
        // For now, using synchronous FileHandle reading wrapped in Task
        try await Task {
            guard let data = try self.input.readLine() else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }.value
    }

    private func writeLine(_ line: String) async throws {
        try await Task {
            guard let data = (line + "\n").data(using: .utf8) else {
                throw TransportError.encodingFailed
            }
            try self.output.write(contentsOf: data)
        }.value
    }

    private func parseMessage(_ line: String) throws -> JsonRpcMessage {
        let decoder = JSONDecoder()
        guard let data = line.data(using: .utf8) else {
            throw TransportError.decodingFailed
        }
        return try decoder.decode(JsonRpcMessage.self, from: data)
    }
}

// MARK: - State Actor

private actor StateActor {
    private var currentState: TransportState = .created
    private let stateContinuation: AsyncStream<TransportState>.Continuation
    private let messageContinuation: AsyncStream<JsonRpcMessage>.Continuation
    private let sendContinuation: AsyncStream<JsonRpcMessage>.Continuation

    let stateStream: AsyncStream<TransportState>
    let messageStream: AsyncStream<JsonRpcMessage>
    let sendQueue: AsyncStream<JsonRpcMessage>

    init() {
        (stateStream, stateContinuation) = AsyncStream.makeStream()
        (messageStream, messageContinuation) = AsyncStream.makeStream()
        (sendQueue, sendContinuation) = AsyncStream.makeStream()

        // Yield initial state
        stateContinuation.yield(.created)
    }

    func transitionTo(_ newState: TransportState) throws {
        // Validate state transition
        switch (currentState, newState) {
        case (.created, .starting),
             (.starting, .started),
             (.started, .closing),
             (.starting, .closing),
             (.closing, .closed):
            currentState = newState
            stateContinuation.yield(newState)

            if newState == .closed {
                stateContinuation.finish()
                messageContinuation.finish()
                sendContinuation.finish()
            }
        default:
            throw TransportError.invalidStateTransition(from: currentState, to: newState)
        }
    }

    func enqueue(_ message: JsonRpcMessage) throws {
        guard currentState == .started else {
            throw TransportError.notStarted
        }
        sendContinuation.yield(message)
    }

    func deliver(_ message: JsonRpcMessage) {
        messageContinuation.yield(message)
    }

    func reportError(_ error: Error) {
        // TODO: Implement error reporting
    }

    func close() {
        if currentState != .closed && currentState != .closing {
            try? transitionTo(.closing)
            sendContinuation.finish()

            // Transition to closed after cleanup
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms grace period
                try? self.transitionTo(.closed)
            }
        }
    }
}

// MARK: - Errors

public enum TransportError: Error {
    case invalidStateTransition(from: TransportState, to: TransportState)
    case notStarted
    case encodingFailed
    case decodingFailed
}

// MARK: - FileHandle Extension

private extension FileHandle {
    func readLine() throws -> Data? {
        var data = Data()

        while true {
            let byte = try read(upToCount: 1)

            guard let byte = byte, !byte.isEmpty else {
                return data.isEmpty ? nil : data
            }

            if byte[0] == UInt8(ascii: "\n") {
                return data
            }

            data.append(byte)
        }
    }
}
