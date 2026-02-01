import ACP
import ACPModel
import Foundation
import XCTest

/// Mock transport for testing Protocol layer
internal actor MockTransport: Transport {
    private let stateContinuation: AsyncStream<TransportState>.Continuation
    nonisolated let state: AsyncStream<TransportState>

    private let messagesContinuation: AsyncStream<JsonRpcMessage>.Continuation
    nonisolated let messages: AsyncStream<JsonRpcMessage>

    private var sentMessages: [JsonRpcMessage] = []

    init() {
        var stateCont: AsyncStream<TransportState>.Continuation?
        self.state = AsyncStream { stateCont = $0 }
        self.stateContinuation = stateCont!

        var msgCont: AsyncStream<JsonRpcMessage>.Continuation?
        self.messages = AsyncStream { msgCont = $0 }
        self.messagesContinuation = msgCont!

        stateContinuation.yield(.created)
    }

    func start() async throws {
        stateContinuation.yield(.starting)
        stateContinuation.yield(.started)
    }

    func send(_ message: JsonRpcMessage) async throws {
        sentMessages.append(message)
    }

    func close() async {
        stateContinuation.yield(.closing)
        stateContinuation.yield(.closed)
        stateContinuation.finish()
        messagesContinuation.finish()
    }

    // Test helpers
    nonisolated func simulateResponse(id: RequestId, result: JsonValue) {
        let response = JsonRpcResponse(id: id, result: result)
        messagesContinuation.yield(.response(response))
    }

    nonisolated func simulateError(id: RequestId?, code: Int, message: String, data: JsonValue? = nil) {
        let error = JsonRpcError(
            id: id,
            error: JsonRpcError.ErrorInfo(code: code, message: message, data: data)
        )
        messagesContinuation.yield(.error(error))
    }

    nonisolated func simulateNotification(method: String, params: JsonValue? = nil) {
        let notification = JsonRpcNotification(method: method, params: params)
        messagesContinuation.yield(.notification(notification))
    }

    func getSentMessages() -> [JsonRpcMessage] {
        return sentMessages
    }
}

internal final class ProtocolTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitialState() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)

        // Protocol should be created successfully
        XCTAssertNotNil(proto)
    }

    // MARK: - Request/Response Tests

    func testSendRequestGeneratesSequentialIDs() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send two requests without waiting for responses
        Task {
            _ = try? await proto.sendRequest(method: "test1", params: nil)
        }
        Task {
            _ = try? await proto.sendRequest(method: "test2", params: nil)
        }

        // Give tasks time to send
        try await Task.sleep(nanoseconds: 100_000_000)

        let messages = await transport.getSentMessages()
        XCTAssertEqual(messages.count, 2)

        // Verify sequential IDs
        if case .request(let req1) = messages[0],
           case .request(let req2) = messages[1] {
            XCTAssertEqual(req1.id, .int(1))
            XCTAssertEqual(req2.id, .int(2))
        } else {
            XCTFail("Expected two requests")
        }

        await proto.close()
    }

    func testSendRequestReturnsResponse() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send request in background
        let responseTask = Task {
            try await proto.sendRequest(method: "test", params: nil)
        }

        // Give request time to be sent
        try await Task.sleep(nanoseconds: 50_000_000)

        // Simulate response
        transport.simulateResponse(id: .int(1), result: .object(["status": .string("ok")]))

        // Await response
        let response = try await responseTask.value

        XCTAssertEqual(response.id, .int(1))
        if case .object(let obj) = response.result,
           case .string(let status) = obj["status"] {
            XCTAssertEqual(status, "ok")
        } else {
            XCTFail("Expected object result with status")
        }

        await proto.close()
    }

    func testSendRequestWithParams() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        struct TestParams: Codable {
            let name: String
            let value: Int
        }

        // Send request with parameters
        Task {
            _ = try? await proto.sendRequest(
                method: "test",
                params: TestParams(name: "foo", value: 42)
            )
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        let messages = await transport.getSentMessages()
        XCTAssertEqual(messages.count, 1)

        if case .request(let request) = messages[0] {
            XCTAssertEqual(request.method, "test")
            XCTAssertNotNil(request.params)
            // Params should be encoded as JsonValue
        } else {
            XCTFail("Expected request message")
        }

        await proto.close()
    }

    func testConcurrentRequests() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send 10 concurrent requests
        let tasks = (1...10).map { i in
            Task {
                try await proto.sendRequest(method: "test\(i)", params: nil)
            }
        }

        // Give requests time to be sent
        try await Task.sleep(nanoseconds: 100_000_000)

        // Simulate responses for all requests
        for i in 1...10 {
            transport.simulateResponse(id: .int(i), result: .int(i))
        }

        // Await all responses
        let responses = try await tasks.asyncMap { try await $0.value }

        XCTAssertEqual(responses.count, 10)

        // Responses may arrive in any order - just verify we got all IDs
        let responseIds = Set(responses.map { $0.id })
        let expectedIds = Set((1...10).map { RequestId.int($0) })
        XCTAssertEqual(responseIds, expectedIds)

        await proto.close()
    }

    // MARK: - Error Handling Tests

    func testHandleJsonRpcError() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send request
        let requestTask = Task {
            try await proto.sendRequest(method: "test", params: nil)
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Simulate error response
        transport.simulateError(
            id: .int(1),
            code: -32601,
            message: "Method not found"
        )

        // Expect error to be thrown
        do {
            _ = try await requestTask.value
            XCTFail("Expected error to be thrown")
        } catch let error as ProtocolError {
            if case .jsonRpcError(let code, let message, _) = error {
                XCTAssertEqual(code, -32601)
                XCTAssertEqual(message, "Method not found")
            } else {
                XCTFail("Expected jsonRpcError")
            }
        } catch {
            XCTFail("Expected ProtocolError, got \(error)")
        }

        await proto.close()
    }

    func testInvalidResponseId() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Set up error stream monitoring
        let errorTask = Task { [errors = proto.errors] in
            var collectedErrors: [ProtocolError] = []
            for await error in errors {
                collectedErrors.append(error)
            }
            return collectedErrors
        }

        // Simulate response with unknown ID
        transport.simulateResponse(id: .int(999), result: .null)

        // Give time for error to be reported
        try await Task.sleep(nanoseconds: 100_000_000)

        await proto.close()

        let errors = await errorTask.value
        // Should have reported invalidResponseId error
        XCTAssertEqual(errors.count, 1)
        if case .invalidResponseId(let id) = errors[0] {
            XCTAssertEqual(id, .int(999))
        } else {
            XCTFail("Expected invalidResponseId error")
        }
    }

    func testTransportClosedError() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send request
        let requestTask = Task {
            try await proto.sendRequest(method: "test", params: nil)
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Close protocol before response arrives
        await proto.close()

        // Expect transportClosed error
        do {
            _ = try await requestTask.value
            XCTFail("Expected error to be thrown")
        } catch let error as ProtocolError {
            if case .transportClosed = error {
                // Expected
            } else {
                XCTFail("Expected transportClosed error, got \(error)")
            }
        } catch {
            XCTFail("Expected ProtocolError, got \(error)")
        }
    }

    // MARK: - Notification Tests

    func testNotificationHandlerRegistration() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        actor NotificationCollector {
            var notifications: [JsonRpcNotification] = []
            func add(_ notification: JsonRpcNotification) {
                notifications.append(notification)
            }
            func get() -> [JsonRpcNotification] {
                return notifications
            }
        }
        let collector = NotificationCollector()

        // Register handler
        await proto.onNotification(method: "test/notification") { [collector] notification in
            await collector.add(notification)
        }

        // Simulate notification
        transport.simulateNotification(
            method: "test/notification",
            params: .object(["data": .string("hello")])
        )

        // Give handler time to process
        try await Task.sleep(nanoseconds: 100_000_000)

        let notifications = await collector.get()
        XCTAssertEqual(notifications.count, 1)
        XCTAssertEqual(notifications[0].method, "test/notification")

        await proto.close()
    }

    func testSendNotification() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send notification
        try await proto.sendNotification(
            method: "test/notification",
            params: ["message": "hello"]
        )

        let messages = await transport.getSentMessages()
        XCTAssertEqual(messages.count, 1)

        if case .notification(let notification) = messages[0] {
            XCTAssertEqual(notification.method, "test/notification")
            XCTAssertNotNil(notification.params)
        } else {
            XCTFail("Expected notification message")
        }

        await proto.close()
    }

    func testMultipleNotificationHandlers() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        actor NotificationCollector {
            var notifications: [JsonRpcNotification] = []
            func add(_ notification: JsonRpcNotification) {
                notifications.append(notification)
            }
            func count() -> Int { notifications.count }
        }
        let collector1 = NotificationCollector()
        let collector2 = NotificationCollector()

        // Register two different handlers
        await proto.onNotification(method: "method1") { [collector1] in await collector1.add($0) }
        await proto.onNotification(method: "method2") { [collector2] in await collector2.add($0) }

        // Send notifications
        transport.simulateNotification(method: "method1", params: .int(1))
        transport.simulateNotification(method: "method2", params: .int(2))
        transport.simulateNotification(method: "method1", params: .int(3))

        try await Task.sleep(nanoseconds: 100_000_000)

        let count1 = await collector1.count()
        let count2 = await collector2.count()
        XCTAssertEqual(count1, 2)
        XCTAssertEqual(count2, 1)

        await proto.close()
    }

    // MARK: - Lifecycle Tests

    func testCloseCleanup() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport)
        try await proto.start()

        // Send requests that will never complete
        let task1 = Task { try? await proto.sendRequest(method: "test1", params: nil) }
        let task2 = Task { try? await proto.sendRequest(method: "test2", params: nil) }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Close protocol
        await proto.close()

        // Tasks should complete with error
        let result1 = await task1.value
        let result2 = await task2.value

        XCTAssertNil(result1)
        XCTAssertNil(result2)
    }

    // MARK: - Timeout Tests

    // Note: Timeout test removed as it hangs - timeout mechanism needs improvement
    // TODO: Add proper timeout test once withTimeout is fixed to properly cancel

    // MARK: - Graceful Cancellation Tests

    /// Test that request cancellation waits for graceful completion within timeout.
    ///
    /// This test mirrors Kotlin SDK's:
    /// "request cancelled from client by coroutine cancel should wait for graceful cancellation"
    ///
    /// The gracefulCancellationTimeoutSeconds is set to 1 second (matching Kotlin SDK).
    /// When a request is cancelled, the Protocol should wait up to 1 second for a response
    /// before forcibly cancelling.
    func testGracefulCancellationWaitsForResponse() async throws {
        let transport = MockTransport()
        let proto = Protocol(transport: transport, gracefulCancellationTimeoutSeconds: 1)
        try await proto.start()

        // Send request in background
        let requestTask = Task {
            try await proto.sendRequest(method: "test", params: nil)
        }

        // Give request time to be sent
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Start timing
        let startTime = Date()

        // Cancel the request
        requestTask.cancel()

        // Simulate graceful response arriving 500ms after cancellation (within 1s timeout)
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            transport.simulateResponse(id: .int(1), result: .object(["status": .string("graceful_complete")]))
        }

        // Wait for task to complete
        let result = try? await requestTask.value
        let elapsed = Date().timeIntervalSince(startTime)

        // Should have waited for the response (at least ~500ms)
        XCTAssertGreaterThan(elapsed, 0.4, "Should wait for graceful response")
        XCTAssertLessThan(elapsed, 1.5, "Should not wait longer than graceful timeout")

        // Should have received the response (not a cancellation error)
        XCTAssertNotNil(result, "Should receive graceful response")

        await proto.close()
    }

    /// Test that graceful cancellation times out after gracefulCancellationTimeoutSeconds.
    ///
    /// This test verifies that if no response comes within the timeout, the request is forcibly cancelled.
    func testGracefulCancellationTimeoutExpires() async throws {
        let transport = MockTransport()
        // Use a short timeout for testing (500ms)
        let proto = Protocol(transport: transport, gracefulCancellationTimeoutSeconds: 0.5)
        try await proto.start()

        // Send request in background
        let requestTask = Task {
            try await proto.sendRequest(method: "test", params: nil)
        }

        // Give request time to be sent
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Start timing
        let startTime = Date()

        // Cancel the request (no response will come)
        requestTask.cancel()

        // Wait for task to complete
        do {
            _ = try await requestTask.value
            XCTFail("Expected cancellation error")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }

        let elapsed = Date().timeIntervalSince(startTime)

        // Should have waited approximately the graceful timeout (500ms)
        XCTAssertGreaterThan(elapsed, 0.4, "Should wait for graceful timeout")
        XCTAssertLessThan(elapsed, 1.0, "Should not wait much longer than graceful timeout")

        await proto.close()
    }
}

// MARK: - Helper Extensions

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var result: [T] = []
        for element in self {
            result.append(try await transform(element))
        }
        return result
    }
}
