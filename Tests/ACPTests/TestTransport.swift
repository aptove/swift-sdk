import ACP
import ACPModel
import Foundation

/// A bidirectional pipe transport for integration testing.
///
/// Creates two connected transports where messages sent on one
/// side are received on the other. Used for testing full
/// agent-client communication flows.
public final class PipeTransport: Transport, @unchecked Sendable {
    public let state: AsyncStream<TransportState>
    public let messages: AsyncStream<JsonRpcMessage>

    private let stateContinuation: AsyncStream<TransportState>.Continuation
    private let messagesContinuation: AsyncStream<JsonRpcMessage>.Continuation
    private weak var peer: PipeTransport?

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
    ///
    /// - Returns: A tuple of two connected transports (client, agent)
    public static func createPair() -> (client: PipeTransport, agent: PipeTransport) {
        let clientTransport = PipeTransport()
        let agentTransport = PipeTransport()
        clientTransport.peer = agentTransport
        agentTransport.peer = clientTransport
        return (clientTransport, agentTransport)
    }

    public func start() async throws {
        stateContinuation.yield(.starting)
        stateContinuation.yield(.started)
    }

    public func send(_ message: JsonRpcMessage) async throws {
        guard let peer = peer else {
            throw TransportError.notConnected
        }
        // Deliver to the peer's message stream
        peer.receive(message)
    }

    public func close() async {
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

/// Errors that can occur during transport operations.
public enum TransportError: Error, Sendable {
    case notConnected
    case alreadyClosed
}
