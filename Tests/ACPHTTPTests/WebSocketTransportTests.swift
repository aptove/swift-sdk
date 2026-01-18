import XCTest
@testable import ACPHTTP
@testable import ACP
@testable import ACPModel
import Foundation

/// Tests for WebSocketTransport.
internal final class WebSocketTransportTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() {
        // Given/When
        let url = URL(string: "wss://example.com/acp")!
        let transport = WebSocketTransport(url: url)

        // Then
        XCTAssertNotNil(transport)
    }

    func testInitializationWithCustomSession() {
        // Given
        let url = URL(string: "wss://example.com/acp")!
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)

        // When
        let transport = WebSocketTransport(url: url, session: session)

        // Then
        XCTAssertNotNil(transport)
    }

    // MARK: - State Tests

    func testInitialState() async {
        // Given
        let url = URL(string: "wss://example.com/acp")!
        let transport = WebSocketTransport(url: url)

        // When - read initial state
        var states: [TransportState] = []
        for await state in transport.state {
            states.append(state)
            break // Just get first state
        }

        // Then
        XCTAssertEqual(states, [.created])
    }

    // MARK: - Protocol Conformance Tests

    func testTransportProtocolConformance() {
        // Given
        let url = URL(string: "wss://example.com/acp")!
        let transport = WebSocketTransport(url: url)

        // Then - should conform to Transport protocol
        let _: Transport = transport

        // Has required properties
        _ = transport.state
        _ = transport.messages
    }

    // MARK: - Error Tests

    func testSendBeforeStartThrows() async {
        // Given
        let url = URL(string: "wss://example.com/acp")!
        let transport = WebSocketTransport(url: url)
        let request = JsonRpcRequest(id: .int(1), method: "test", params: nil)

        // When/Then
        do {
            try await transport.send(.request(request))
            XCTFail("Expected error to be thrown")
        } catch let error as WebSocketTransportError {
            XCTAssertEqual(error.errorDescription, "Not connected to WebSocket server")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testCloseBeforeStart() async {
        // Given
        let url = URL(string: "wss://example.com/acp")!
        let transport = WebSocketTransport(url: url)

        // When - should not crash
        await transport.close()

        // Then - transport is closed
        // This should complete without error
    }

    // MARK: - State Transition Tests

    func testInvalidStateTransitionError() {
        let error = WebSocketTransportError.invalidStateTransition(from: .created, to: .closed)
        XCTAssertEqual(error.errorDescription, "Invalid state transition from created to closed")
    }

    func testNotConnectedError() {
        let error = WebSocketTransportError.notConnected
        XCTAssertEqual(error.errorDescription, "Not connected to WebSocket server")
    }

    func testEncodingFailedError() {
        let error = WebSocketTransportError.encodingFailed
        XCTAssertEqual(error.errorDescription, "Failed to encode message")
    }

    func testConnectionFailedError() {
        let error = WebSocketTransportError.connectionFailed("Connection refused")
        XCTAssertEqual(error.errorDescription, "WebSocket connection failed: Connection refused")
    }
}

// MARK: - Integration Tests (require network)

/// These tests require an actual WebSocket server and are disabled by default.
/// Enable them by removing the skip or using a local mock server.
internal final class WebSocketTransportIntegrationTests: XCTestCase {

    /// Test connecting to a real WebSocket echo server.
    /// Disabled by default - enable for manual testing.
    func testRealWebSocketConnection() async throws {
        // Skip in CI - this requires network
        throw XCTSkip("Integration test requires network access")

        // Using a public WebSocket echo server
        // let url = URL(string: "wss://echo.websocket.org")!
        // let transport = WebSocketTransport(url: url)
        //
        // try await transport.start()
        //
        // let request = JsonRpcRequest(id: .int(1), method: "test", params: nil)
        // try await transport.send(.request(request))
        //
        // await transport.close()
    }
}
