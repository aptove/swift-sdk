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

    // MARK: - AuthMethod Tests

    func testAuthMethodDecodeLegacyString() throws {
        // Test decoding legacy string format
        let json = "\"oauth2\""
        let data = json.data(using: .utf8)!
        let method = try JSONDecoder().decode(AuthMethod.self, from: data)

        if case .legacy(let value) = method {
            XCTAssertEqual(value, "oauth2")
        } else {
            XCTFail("Expected legacy auth method")
        }
    }

    func testAuthMethodDecodeAgentType() throws {
        // Test decoding agent auth method with explicit type
        let json = """
        {
            "type": "agent",
            "id": "agent-auth",
            "name": "Agent Authentication",
            "description": "Let the agent handle auth"
        }
        """
        let data = json.data(using: .utf8)!
        let method = try JSONDecoder().decode(AuthMethod.self, from: data)

        if case .agent(let agentMethod) = method {
            XCTAssertEqual(agentMethod.id.value, "agent-auth")
            XCTAssertEqual(agentMethod.name, "Agent Authentication")
            XCTAssertEqual(agentMethod.description, "Let the agent handle auth")
        } else {
            XCTFail("Expected agent auth method, got \(method)")
        }
    }

    func testAuthMethodDecodeAgentTypeWithoutExplicitType() throws {
        // Test decoding agent auth method without type field (default)
        let json = """
        {
            "id": "default-auth",
            "name": "Default Authentication"
        }
        """
        let data = json.data(using: .utf8)!
        let method = try JSONDecoder().decode(AuthMethod.self, from: data)

        if case .agent(let agentMethod) = method {
            XCTAssertEqual(agentMethod.id.value, "default-auth")
            XCTAssertEqual(agentMethod.name, "Default Authentication")
            XCTAssertNil(agentMethod.description)
        } else {
            XCTFail("Expected agent auth method (default), got \(method)")
        }
    }

    func testAuthMethodDecodeEnvVarType() throws {
        // Test decoding env_var auth method
        let json = """
        {
            "type": "env_var",
            "id": "api-key-auth",
            "name": "API Key",
            "description": "Enter your API key",
            "varName": "API_KEY",
            "link": "https://example.com/get-api-key"
        }
        """
        let data = json.data(using: .utf8)!
        let method = try JSONDecoder().decode(AuthMethod.self, from: data)

        if case .envVar(let envVarMethod) = method {
            XCTAssertEqual(envVarMethod.id.value, "api-key-auth")
            XCTAssertEqual(envVarMethod.name, "API Key")
            XCTAssertEqual(envVarMethod.description, "Enter your API key")
            XCTAssertEqual(envVarMethod.varName, "API_KEY")
            XCTAssertEqual(envVarMethod.link, "https://example.com/get-api-key")
        } else {
            XCTFail("Expected env_var auth method, got \(method)")
        }
    }

    func testAuthMethodDecodeTerminalType() throws {
        // Test decoding terminal auth method
        let json = """
        {
            "type": "terminal",
            "id": "terminal-auth",
            "name": "Terminal Login",
            "description": "Interactive terminal login",
            "args": ["--interactive", "--login"],
            "env": {"TERM": "xterm-256color"}
        }
        """
        let data = json.data(using: .utf8)!
        let method = try JSONDecoder().decode(AuthMethod.self, from: data)

        if case .terminal(let terminalMethod) = method {
            XCTAssertEqual(terminalMethod.id.value, "terminal-auth")
            XCTAssertEqual(terminalMethod.name, "Terminal Login")
            XCTAssertEqual(terminalMethod.description, "Interactive terminal login")
            XCTAssertEqual(terminalMethod.args, ["--interactive", "--login"])
            XCTAssertEqual(terminalMethod.env, ["TERM": "xterm-256color"])
        } else {
            XCTFail("Expected terminal auth method, got \(method)")
        }
    }

    func testAuthMethodDecodeArrayMixed() throws {
        // Test decoding array with mixed formats (like Copilot returns)
        let json = """
        [
            {
                "type": "agent",
                "id": "copilot-auth",
                "name": "GitHub Copilot"
            },
            {
                "type": "env_var",
                "id": "openai-key",
                "name": "OpenAI API Key",
                "varName": "OPENAI_API_KEY"
            }
        ]
        """
        let data = json.data(using: .utf8)!
        let methods = try JSONDecoder().decode([AuthMethod].self, from: data)

        XCTAssertEqual(methods.count, 2)

        if case .agent(let first) = methods[0] {
            XCTAssertEqual(first.id.value, "copilot-auth")
            XCTAssertEqual(first.name, "GitHub Copilot")
        } else {
            XCTFail("Expected first method to be agent type")
        }

        if case .envVar(let second) = methods[1] {
            XCTAssertEqual(second.id.value, "openai-key")
            XCTAssertEqual(second.varName, "OPENAI_API_KEY")
        } else {
            XCTFail("Expected second method to be env_var type")
        }
    }

    func testAuthMethodConvenienceProperties() throws {
        // Test legacy method
        let legacyMethod = AuthMethod.legacy("test-auth")
        XCTAssertEqual(legacyMethod.id?.value, "test-auth")
        XCTAssertEqual(legacyMethod.name, "test-auth")

        // Test agent method
        let agentMethod = AuthMethod.agent(AgentAuthMethod(
            id: AuthMethodId(value: "agent-id"),
            name: "Agent Name",
            description: "Agent Description"
        ))
        XCTAssertEqual(agentMethod.id?.value, "agent-id")
        XCTAssertEqual(agentMethod.name, "Agent Name")
    }

    func testAuthMethodEncodeAgentType() throws {
        let method = AuthMethod.agent(AgentAuthMethod(
            id: AuthMethodId(value: "test-agent"),
            name: "Test Agent Auth",
            description: "A test agent auth method"
        ))

        let data = try JSONEncoder().encode(method)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["id"] as? String, "test-agent")
        XCTAssertEqual(json?["name"] as? String, "Test Agent Auth")
        XCTAssertEqual(json?["description"] as? String, "A test agent auth method")
    }

    func testAuthMethodEncodeLegacy() throws {
        let method = AuthMethod.legacy("simple-auth")

        let data = try JSONEncoder().encode(method)
        let json = String(data: data, encoding: .utf8)

        XCTAssertEqual(json, "\"simple-auth\"")
    }

    func testAuthMethodHashable() {
        let method1 = AuthMethod.legacy("same")
        let method2 = AuthMethod.legacy("same")
        let method3 = AuthMethod.legacy("different")

        XCTAssertEqual(method1, method2)
        XCTAssertNotEqual(method1, method3)

        var set = Set<AuthMethod>()
        set.insert(method1)
        set.insert(method2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - InitializeResponse with AuthMethod Tests

    func testInitializeResponseWithDictionaryAuthMethods() throws {
        // Simulate what Copilot actually returns
        let json = """
        {
            "protocolVersion": 1,
            "agentCapabilities": {},
            "authMethods": [
                {
                    "type": "agent",
                    "id": "github-copilot",
                    "name": "GitHub Copilot Authentication"
                }
            ],
            "agentInfo": {
                "name": "copilot",
                "version": "1.0.0"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(InitializeResponse.self, from: data)

        XCTAssertEqual(response.protocolVersion.version, 1)
        XCTAssertEqual(response.authMethods?.count, 1)

        if let firstMethod = response.authMethods?.first,
           case .agent(let agentMethod) = firstMethod {
            XCTAssertEqual(agentMethod.id.value, "github-copilot")
            XCTAssertEqual(agentMethod.name, "GitHub Copilot Authentication")
        } else {
            XCTFail("Expected agent auth method")
        }
    }

    func testInitializeResponseWithEmptyAuthMethods() throws {
        let json = """
        {
            "protocolVersion": 1,
            "agentCapabilities": {},
            "authMethods": []
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(InitializeResponse.self, from: data)

        XCTAssertEqual(response.authMethods?.count, 0)
    }

    func testInitializeResponseWithNullAuthMethods() throws {
        let json = """
        {
            "protocolVersion": 1,
            "agentCapabilities": {}
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(InitializeResponse.self, from: data)

        XCTAssertNil(response.authMethods)
    }
}
