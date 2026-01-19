import XCTest
@testable import ACPModel

internal final class AuthMessagesTests: XCTestCase {
    // MARK: - AuthMethodId Tests

    func testAuthMethodIdEncoding() throws {
        let id = AuthMethodId(value: "oauth2")
        let data = try JSONEncoder().encode(id)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"oauth2\"")
    }

    func testAuthMethodIdDecoding() throws {
        let json = "\"api-key\""
        let data = json.data(using: .utf8)!
        let id = try JSONDecoder().decode(AuthMethodId.self, from: data)
        XCTAssertEqual(id.value, "api-key")
    }

    func testAuthMethodIdStringLiteral() {
        let id: AuthMethodId = "bearer-token"
        XCTAssertEqual(id.value, "bearer-token")
    }

    func testAuthMethodIdHashable() {
        let id1 = AuthMethodId(value: "same")
        let id2 = AuthMethodId(value: "same")
        let id3 = AuthMethodId(value: "different")

        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)

        var set = Set<AuthMethodId>()
        set.insert(id1)
        set.insert(id2)
        XCTAssertEqual(set.count, 1)
    }

    func testAuthMethodIdDescription() {
        let id = AuthMethodId(value: "my-auth")
        XCTAssertEqual(id.description, "my-auth")
    }

    // MARK: - AuthenticateRequest Tests

    func testAuthenticateRequestEncode() throws {
        let request = AuthenticateRequest(
            methodId: AuthMethodId(value: "oauth2"),
            _meta: nil
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["methodId"] as? String, "oauth2")
    }

    func testAuthenticateRequestDecode() throws {
        let json = """
        {
            "methodId": "api-key"
        }
        """
        let data = json.data(using: .utf8)!
        let request = try JSONDecoder().decode(AuthenticateRequest.self, from: data)

        XCTAssertEqual(request.methodId.value, "api-key")
        XCTAssertNil(request._meta)
    }

    func testAuthenticateRequestRoundTrip() throws {
        let original = AuthenticateRequest(
            methodId: AuthMethodId(value: "bearer"),
            _meta: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AuthenticateRequest.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testAuthenticateRequestConformsToAcpRequest() {
        let request = AuthenticateRequest(
            methodId: AuthMethodId(value: "test"),
            _meta: nil
        )

        // Verify AcpRequest conformance
        let _: (any AcpRequest) = request
        XCTAssertNil(request._meta)
    }

    // MARK: - AuthenticateResponse Tests

    func testAuthenticateResponseEncode() throws {
        let response = AuthenticateResponse(_meta: nil)

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Empty response should still be valid
        XCTAssertNotNil(json)
    }

    func testAuthenticateResponseDecode() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AuthenticateResponse.self, from: data)

        XCTAssertNil(response._meta)
    }

    func testAuthenticateResponseRoundTrip() throws {
        let original = AuthenticateResponse(_meta: nil)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AuthenticateResponse.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testAuthenticateResponseConformsToAcpResponse() {
        let response = AuthenticateResponse(_meta: nil)

        // Verify AcpResponse conformance
        let _: (any AcpResponse) = response
        XCTAssertNil(response._meta)
    }

    // MARK: - Hashable Tests

    func testAuthenticateRequestHashable() {
        let request1 = AuthenticateRequest(
            methodId: AuthMethodId(value: "same"),
            _meta: nil
        )
        let request2 = AuthenticateRequest(
            methodId: AuthMethodId(value: "same"),
            _meta: nil
        )

        XCTAssertEqual(request1, request2)

        var set = Set<AuthenticateRequest>()
        set.insert(request1)
        set.insert(request2)
        XCTAssertEqual(set.count, 1)
    }

    func testAuthenticateResponseHashable() {
        let response1 = AuthenticateResponse(_meta: nil)
        let response2 = AuthenticateResponse(_meta: nil)

        XCTAssertEqual(response1, response2)

        var set = Set<AuthenticateResponse>()
        set.insert(response1)
        set.insert(response2)
        XCTAssertEqual(set.count, 1)
    }
}
