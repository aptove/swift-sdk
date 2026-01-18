/// ACPHTTP module
///
/// Optional HTTP and WebSocket transport implementations for ACP.
/// Enables agents and clients to communicate over HTTP, WebSocket, and Server-Sent Events.
///
/// Key components:
/// - WebSocketTransport: WebSocket-based transport
/// - HTTPClient: HTTP request/response support
/// - SSEClient: Server-Sent Events streaming
/// - Authentication helpers

import ACP
import ACPModel
import Logging
import Foundation

public struct ACPHTTP {
    /// The version of this SDK
    public static let version = "1.0.0"
}
