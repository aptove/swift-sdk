import XCTest
@testable import ACP
@testable import ACPModel

public final class StdioTransportTests: XCTestCase {
    // Test that initial state is .created
    func testInitialState() async {
        let transport = createTestTransport()
        var receivedStates: [TransportState] = []

        let task = Task {
            for await state in transport.state {
                receivedStates.append(state)
                if state == .created {
                    break
                }
            }
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        task.cancel()

        XCTAssertTrue(receivedStates.contains(.created), "Initial state should be .created")
    }

    // Test basic message send/receive cycle
    func testMessageSendReceive() async throws {
        let readPipe = Pipe()
        let writePipe = Pipe()
        let transport = StdioTransport(input: readPipe.fileHandleForReading, output: writePipe.fileHandleForWriting)

        // Start transport in background
        Task {
            try? await transport.start()
        }

        // Wait for started state
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Send a message
        let request = JsonRpcRequest(id: .int(1), method: "test", params: nil)
        try await transport.send(JsonRpcMessage.request(request))

        // Read from the write pipe to verify message was written
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        let data = writePipe.fileHandleForReading.availableData
        let output = String(data: data, encoding: .utf8) ?? ""

        XCTAssertTrue(output.contains("\"id\":1"), "Output should contain request ID")
        XCTAssertTrue(output.contains("\"method\":\"test\""), "Output should contain method")
        XCTAssertTrue(output.hasSuffix("\n"), "Output should end with newline")

        await transport.close()
    }

    // Test receiving messages
    func testMessageReceive() async throws {
        let readPipe = Pipe()
        let writePipe = Pipe()
        let transport = StdioTransport(input: readPipe.fileHandleForReading, output: writePipe.fileHandleForWriting)

        var receivedMessages: [JsonRpcMessage] = []
        let messageTask = Task {
            for await message in transport.messages {
                receivedMessages.append(message)
                break // Get first message then exit
            }
        }

        // Start transport
        Task {
            try? await transport.start()
        }

        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Write a JSON-RPC message to the read pipe
        let json = #"{"jsonrpc":"2.0","id":1,"method":"test"}"# + "\n"
        if let data = json.data(using: .utf8) {
            readPipe.fileHandleForWriting.write(data)
        }

        // Wait for message to be received
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        messageTask.cancel()
        await transport.close()

        XCTAssertEqual(receivedMessages.count, 1, "Should receive one message")
        if case .request(let req) = receivedMessages.first {
            XCTAssertEqual(req.method, "test")
            XCTAssertEqual(req.id, .int(1))
        } else {
            XCTFail("Message should be a request")
        }
    }

    // Test close is idempotent
    func testCloseIdempotent() async {
        let transport = createTestTransport()

        await transport.close()
        await transport.close() // Should not crash or error

        // No assertions needed - just verify it doesn't crash
    }

    // Test state transitions
    func testStateTransitions() async throws {
        let transport = createTestTransport()
        var states: [TransportState] = []

        let stateTask = Task {
            for await state in transport.state {
                states.append(state)
                if states.count >= 3 { break }
            }
        }

        // Start transport
        Task {
            try? await transport.start()
        }

        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        await transport.close()

        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        stateTask.cancel()

        // Should have at least: created, starting, started
        XCTAssertTrue(states.contains(.created), "Should transition through .created")
        XCTAssertTrue(states.contains(.starting) || states.contains(.started),
                      "Should transition through .starting or .started")
    }

    // Test malformed JSON is skipped
    func testMalformedJSONSkipped() async throws {
        let readPipe = Pipe()
        let writePipe = Pipe()
        let transport = StdioTransport(input: readPipe.fileHandleForReading, output: writePipe.fileHandleForWriting)

        var receivedMessages: [JsonRpcMessage] = []
        let messageTask = Task {
            for await message in transport.messages {
                receivedMessages.append(message)
                if receivedMessages.count >= 1 { break }
            }
        }

        // Start transport
        Task {
            try? await transport.start()
        }

        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Write malformed JSON, then valid JSON
        let malformed = "this is not json\n"
        let valid = #"{"jsonrpc":"2.0","id":2,"method":"valid"}"# + "\n"

        if let data1 = malformed.data(using: .utf8) {
            readPipe.fileHandleForWriting.write(data1)
        }
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        if let data2 = valid.data(using: .utf8) {
            readPipe.fileHandleForWriting.write(data2)
        }

        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        messageTask.cancel()
        await transport.close()

        // Should only receive the valid message
        XCTAssertEqual(receivedMessages.count, 1, "Should receive one valid message")
        if case .request(let req) = receivedMessages.first {
            XCTAssertEqual(req.method, "valid")
        } else {
            XCTFail("Message should be a request")
        }
    }

    // Test EOF handling
    func testEOFHandling() async throws {
        let readPipe = Pipe()
        let writePipe = Pipe()
        let transport = StdioTransport(input: readPipe.fileHandleForReading, output: writePipe.fileHandleForWriting)

        var states: [TransportState] = []
        let stateTask = Task {
            for await state in transport.state {
                states.append(state)
                if state == .closed { break }
            }
        }

        // Start transport
        Task {
            try? await transport.start()
        }

        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Close the write end to simulate EOF
        try? readPipe.fileHandleForWriting.close()

        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        stateTask.cancel()

        // Should eventually reach closed state
        XCTAssertTrue(states.contains(.closing) || states.contains(.closed),
                      "Should close on EOF")
    }

    // MARK: - Helper Methods

    private func createTestTransport() -> StdioTransport {
        let readPipe = Pipe()
        let writePipe = Pipe()
        return StdioTransport(
            input: readPipe.fileHandleForReading,
            output: writePipe.fileHandleForWriting
        )
    }
}
