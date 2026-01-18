import XCTest
@testable import ACPModel

final class JsonRpcTests: XCTestCase {
    // MARK: - JsonRpcRequest Tests
    
    func testRequestCreation() {
        let request = JsonRpcRequest(
            id: .int(1),
            method: "test_method",
            params: .object(["key": "value"])
        )
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, .int(1))
        XCTAssertEqual(request.method, "test_method")
        XCTAssertNotNil(request.params)
    }
    
    func testRequestCodableRoundTrip() throws {
        let original = JsonRpcRequest(
            id: .string("req-123"),
            method: "initialize",
            params: .object(["version": "1.0.0"])
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonRpcRequest.self, from: encoded)
        
        XCTAssertEqual(decoded.jsonrpc, "2.0")
        XCTAssertEqual(decoded.id, .string("req-123"))
        XCTAssertEqual(decoded.method, "initialize")
    }
    
    // MARK: - JsonRpcResponse Tests
    
    func testResponseCreation() {
        let response = JsonRpcResponse(
            id: .int(1),
            result: .object(["status": "ok"])
        )
        
        XCTAssertEqual(response.jsonrpc, "2.0")
        XCTAssertEqual(response.id, .int(1))
    }
    
    func testResponseCodableRoundTrip() throws {
        let original = JsonRpcResponse(
            id: .int(42),
            result: .array([.int(1), .int(2), .int(3)])
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonRpcResponse.self, from: encoded)
        
        XCTAssertEqual(decoded.jsonrpc, "2.0")
        XCTAssertEqual(decoded.id, .int(42))
    }
    
    // MARK: - JsonRpcError Tests
    
    func testErrorCreation() {
        let error = JsonRpcError(
            id: .int(1),
            error: JsonRpcError.ErrorInfo(
                code: -32600,
                message: "Invalid Request"
            )
        )
        
        XCTAssertEqual(error.jsonrpc, "2.0")
        XCTAssertEqual(error.id, .int(1))
        XCTAssertEqual(error.error.code, -32600)
        XCTAssertEqual(error.error.message, "Invalid Request")
    }
    
    func testErrorCodableRoundTrip() throws {
        let original = JsonRpcError(
            id: nil,
            error: JsonRpcError.ErrorInfo(
                code: JsonRpcErrorCode.parseError.rawValue,
                message: "Parse error",
                data: .string("Additional info")
            )
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonRpcError.self, from: encoded)
        
        XCTAssertEqual(decoded.jsonrpc, "2.0")
        XCTAssertNil(decoded.id)
        XCTAssertEqual(decoded.error.code, -32700)
        XCTAssertEqual(decoded.error.message, "Parse error")
    }
    
    // MARK: - JsonRpcNotification Tests
    
    func testNotificationCreation() {
        let notification = JsonRpcNotification(
            method: "session/update",
            params: .object(["sessionId": "abc"])
        )
        
        XCTAssertEqual(notification.jsonrpc, "2.0")
        XCTAssertEqual(notification.method, "session/update")
    }
    
    func testNotificationCodableRoundTrip() throws {
        let original = JsonRpcNotification(
            method: "$/cancelRequest",
            params: .object(["id": .int(5)])
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonRpcNotification.self, from: encoded)
        
        XCTAssertEqual(decoded.jsonrpc, "2.0")
        XCTAssertEqual(decoded.method, "$/cancelRequest")
    }
    
    // MARK: - JsonRpcMessage Tests
    
    func testMessageRequestEnvelope() throws {
        let request = JsonRpcRequest(id: .int(1), method: "test")
        let message = JsonRpcMessage.request(request)
        
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(JsonRpcMessage.self, from: encoded)
        
        if case .request(let decodedRequest) = decoded {
            XCTAssertEqual(decodedRequest.id, .int(1))
            XCTAssertEqual(decodedRequest.method, "test")
        } else {
            XCTFail("Expected request message")
        }
    }
    
    func testMessageResponseEnvelope() throws {
        let response = JsonRpcResponse(id: .int(1), result: .null)
        let message = JsonRpcMessage.response(response)
        
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(JsonRpcMessage.self, from: encoded)
        
        if case .response(let decodedResponse) = decoded {
            XCTAssertEqual(decodedResponse.id, .int(1))
        } else {
            XCTFail("Expected response message")
        }
    }
    
    func testMessageErrorEnvelope() throws {
        let error = JsonRpcError(
            id: .int(1),
            error: JsonRpcError.ErrorInfo(code: -32600, message: "Error")
        )
        let message = JsonRpcMessage.error(error)
        
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(JsonRpcMessage.self, from: encoded)
        
        if case .error(let decodedError) = decoded {
            XCTAssertEqual(decodedError.id, .int(1))
            XCTAssertEqual(decodedError.error.code, -32600)
        } else {
            XCTFail("Expected error message")
        }
    }
    
    func testMessageNotificationEnvelope() throws {
        let notification = JsonRpcNotification(method: "notify")
        let message = JsonRpcMessage.notification(notification)
        
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(JsonRpcMessage.self, from: encoded)
        
        if case .notification(let decodedNotification) = decoded {
            XCTAssertEqual(decodedNotification.method, "notify")
        } else {
            XCTFail("Expected notification message")
        }
    }
    
    // MARK: - Error Code Tests
    
    func testStandardErrorCodes() {
        XCTAssertEqual(JsonRpcErrorCode.parseError.rawValue, -32700)
        XCTAssertEqual(JsonRpcErrorCode.invalidRequest.rawValue, -32600)
        XCTAssertEqual(JsonRpcErrorCode.methodNotFound.rawValue, -32601)
        XCTAssertEqual(JsonRpcErrorCode.invalidParams.rawValue, -32602)
        XCTAssertEqual(JsonRpcErrorCode.internalError.rawValue, -32603)
    }
    
    func testCustomErrorCodes() {
        XCTAssertEqual(JsonRpcErrorCode.authRequired.rawValue, -32000)
        XCTAssertEqual(JsonRpcErrorCode.resourceNotFound.rawValue, -32001)
    }
}
