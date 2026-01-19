import XCTest
@testable import ACPModel

internal final class ModelMessagesTests: XCTestCase {
    // MARK: - SetSessionModelRequest Tests

    func testSetSessionModelRequestEncode() throws {
        let request = SetSessionModelRequest(
            sessionId: SessionId(value: "session-123"),
            modelId: ModelId(value: "gpt-4"),
            _meta: nil
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-123")
        XCTAssertEqual(json?["modelId"] as? String, "gpt-4")
    }

    func testSetSessionModelRequestDecode() throws {
        let json = """
        {
            "sessionId": "session-456",
            "modelId": "claude-3"
        }
        """
        let data = json.data(using: .utf8)!
        let request = try JSONDecoder().decode(SetSessionModelRequest.self, from: data)

        XCTAssertEqual(request.sessionId.value, "session-456")
        XCTAssertEqual(request.modelId.value, "claude-3")
        XCTAssertNil(request._meta)
    }

    func testSetSessionModelRequestRoundTrip() throws {
        let original = SetSessionModelRequest(
            sessionId: SessionId(value: "test-session"),
            modelId: ModelId(value: "test-model"),
            _meta: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SetSessionModelRequest.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testSetSessionModelRequestConformsToProtocols() {
        let request = SetSessionModelRequest(
            sessionId: SessionId(value: "session"),
            modelId: ModelId(value: "model"),
            _meta: nil
        )

        // Verify AcpRequest conformance
        let _: (any AcpRequest) = request
        XCTAssertNil(request._meta)

        // Verify AcpWithSessionId conformance
        let _: (any AcpWithSessionId) = request
        XCTAssertEqual(request.sessionId.value, "session")
    }

    // MARK: - SetSessionModelResponse Tests

    func testSetSessionModelResponseEncode() throws {
        let response = SetSessionModelResponse(_meta: nil)

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
    }

    func testSetSessionModelResponseDecode() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SetSessionModelResponse.self, from: data)

        XCTAssertNil(response._meta)
    }

    func testSetSessionModelResponseRoundTrip() throws {
        let original = SetSessionModelResponse(_meta: nil)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SetSessionModelResponse.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testSetSessionModelResponseConformsToAcpResponse() {
        let response = SetSessionModelResponse(_meta: nil)

        // Verify AcpResponse conformance
        let _: (any AcpResponse) = response
        XCTAssertNil(response._meta)
    }

    // MARK: - SetSessionConfigOptionRequest Tests

    func testSetSessionConfigOptionRequestEncode() throws {
        let request = SetSessionConfigOptionRequest(
            sessionId: SessionId(value: "session-789"),
            configId: SessionConfigId(value: "theme"),
            value: SessionConfigValueId(value: "dark"),
            _meta: nil
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["sessionId"] as? String, "session-789")
        XCTAssertEqual(json?["configId"] as? String, "theme")
        XCTAssertEqual(json?["value"] as? String, "dark")
    }

    func testSetSessionConfigOptionRequestDecode() throws {
        let json = """
        {
            "sessionId": "session-abc",
            "configId": "language",
            "value": "en"
        }
        """
        let data = json.data(using: .utf8)!
        let request = try JSONDecoder().decode(SetSessionConfigOptionRequest.self, from: data)

        XCTAssertEqual(request.sessionId.value, "session-abc")
        XCTAssertEqual(request.configId.value, "language")
        XCTAssertEqual(request.value.value, "en")
    }

    func testSetSessionConfigOptionRequestRoundTrip() throws {
        let original = SetSessionConfigOptionRequest(
            sessionId: SessionId(value: "test"),
            configId: SessionConfigId(value: "config"),
            value: SessionConfigValueId(value: "val"),
            _meta: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SetSessionConfigOptionRequest.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - SetSessionConfigOptionResponse Tests

    func testSetSessionConfigOptionResponseEncode() throws {
        let response = SetSessionConfigOptionResponse(
            configOptions: nil,
            _meta: nil
        )

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
    }

    func testSetSessionConfigOptionResponseDecode() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SetSessionConfigOptionResponse.self, from: data)

        XCTAssertNil(response.configOptions)
        XCTAssertNil(response._meta)
    }

    func testSetSessionConfigOptionResponseWithOptions() throws {
        let response = SetSessionConfigOptionResponse(
            configOptions: [
                .select(SessionConfigOptionSelect(
                    id: SessionConfigId(value: "theme"),
                    name: "Theme",
                    currentValue: SessionConfigValueId(value: "dark"),
                    options: .flat([])
                ))
            ],
            _meta: nil
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(SetSessionConfigOptionResponse.self, from: data)

        XCTAssertEqual(decoded.configOptions?.count, 1)
    }

    func testSetSessionConfigOptionResponseRoundTrip() throws {
        let original = SetSessionConfigOptionResponse(
            configOptions: [
                .select(SessionConfigOptionSelect(
                    id: SessionConfigId(value: "test"),
                    name: "Test",
                    currentValue: SessionConfigValueId(value: "value"),
                    options: .flat([
                        SessionConfigSelectOption(
                            value: SessionConfigValueId(value: "value"),
                            name: "Value"
                        )
                    ])
                ))
            ],
            _meta: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SetSessionConfigOptionResponse.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Hashable Tests

    func testSetSessionModelRequestHashable() {
        let request1 = SetSessionModelRequest(
            sessionId: SessionId(value: "s"),
            modelId: ModelId(value: "m"),
            _meta: nil
        )
        let request2 = SetSessionModelRequest(
            sessionId: SessionId(value: "s"),
            modelId: ModelId(value: "m"),
            _meta: nil
        )

        XCTAssertEqual(request1, request2)

        var set = Set<SetSessionModelRequest>()
        set.insert(request1)
        set.insert(request2)
        XCTAssertEqual(set.count, 1)
    }

    func testSetSessionModelResponseHashable() {
        let response1 = SetSessionModelResponse(_meta: nil)
        let response2 = SetSessionModelResponse(_meta: nil)

        XCTAssertEqual(response1, response2)

        var set = Set<SetSessionModelResponse>()
        set.insert(response1)
        set.insert(response2)
        XCTAssertEqual(set.count, 1)
    }
}
