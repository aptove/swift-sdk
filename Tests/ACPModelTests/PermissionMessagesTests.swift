import XCTest
@testable import ACPModel

/// Tests for Permission request/response types.
internal final class PermissionMessagesTests: XCTestCase {

    // MARK: - PermissionOptionKind Tests

    func testPermissionOptionKindEncoding() throws {
        let encoder = JSONEncoder()

        let allowOnce = try encoder.encode(PermissionOptionKind.allowOnce)
        XCTAssertEqual(String(data: allowOnce, encoding: .utf8), "\"allow_once\"")

        let allowAlways = try encoder.encode(PermissionOptionKind.allowAlways)
        XCTAssertEqual(String(data: allowAlways, encoding: .utf8), "\"allow_always\"")

        let rejectOnce = try encoder.encode(PermissionOptionKind.rejectOnce)
        XCTAssertEqual(String(data: rejectOnce, encoding: .utf8), "\"reject_once\"")

        let rejectAlways = try encoder.encode(PermissionOptionKind.rejectAlways)
        XCTAssertEqual(String(data: rejectAlways, encoding: .utf8), "\"reject_always\"")
    }

    func testPermissionOptionKindDecoding() throws {
        let decoder = JSONDecoder()

        let allowOnce = try decoder.decode(PermissionOptionKind.self, from: Data("\"allow_once\"".utf8))
        XCTAssertEqual(allowOnce, .allowOnce)

        let rejectAlways = try decoder.decode(PermissionOptionKind.self, from: Data("\"reject_always\"".utf8))
        XCTAssertEqual(rejectAlways, .rejectAlways)
    }

    // MARK: - PermissionOption Tests

    func testPermissionOptionEncoding() throws {
        let option = PermissionOption(
            optionId: PermissionOptionId("opt-1"),
            name: "Allow Once",
            kind: .allowOnce
        )

        let data = try JSONEncoder().encode(option)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["optionId"] as? String, "opt-1")
        XCTAssertEqual(json?["name"] as? String, "Allow Once")
        XCTAssertEqual(json?["kind"] as? String, "allow_once")
    }

    func testPermissionOptionDecoding() throws {
        let json = """
        {
            "optionId": "opt-2",
            "name": "Reject Always",
            "kind": "reject_always"
        }
        """

        let option = try JSONDecoder().decode(PermissionOption.self, from: Data(json.utf8))

        XCTAssertEqual(option.optionId.value, "opt-2")
        XCTAssertEqual(option.name, "Reject Always")
        XCTAssertEqual(option.kind, .rejectAlways)
    }

    func testPermissionOptionRoundTrip() throws {
        let option = PermissionOption(
            optionId: PermissionOptionId("opt-3"),
            name: "Allow Always",
            kind: .allowAlways
        )

        let data = try JSONEncoder().encode(option)
        let decoded = try JSONDecoder().decode(PermissionOption.self, from: data)

        XCTAssertEqual(decoded.optionId.value, option.optionId.value)
        XCTAssertEqual(decoded.name, option.name)
        XCTAssertEqual(decoded.kind, option.kind)
    }

    // MARK: - RequestPermissionOutcome Tests

    func testRequestPermissionOutcomeCancelledEncoding() throws {
        let outcome = RequestPermissionOutcome.cancelled

        let data = try JSONEncoder().encode(outcome)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["outcome"] as? String, "cancelled")
        XCTAssertNil(json?["optionId"])
    }

    func testRequestPermissionOutcomeSelectedEncoding() throws {
        let outcome = RequestPermissionOutcome.selected(PermissionOptionId("opt-1"))

        let data = try JSONEncoder().encode(outcome)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["outcome"] as? String, "selected")
        XCTAssertEqual(json?["optionId"] as? String, "opt-1")
    }

    func testRequestPermissionOutcomeCancelledDecoding() throws {
        let json = """
        {"outcome": "cancelled"}
        """

        let outcome = try JSONDecoder().decode(RequestPermissionOutcome.self, from: Data(json.utf8))

        if case .cancelled = outcome {
            // Success
        } else {
            XCTFail("Expected cancelled outcome")
        }
    }

    func testRequestPermissionOutcomeSelectedDecoding() throws {
        let json = """
        {"outcome": "selected", "optionId": "opt-2"}
        """

        let outcome = try JSONDecoder().decode(RequestPermissionOutcome.self, from: Data(json.utf8))

        if case .selected(let optionId) = outcome {
            XCTAssertEqual(optionId.value, "opt-2")
        } else {
            XCTFail("Expected selected outcome")
        }
    }

    func testRequestPermissionOutcomeRoundTrip() throws {
        let outcomes: [RequestPermissionOutcome] = [
            .cancelled,
            .selected(PermissionOptionId("opt-1"))
        ]

        for outcome in outcomes {
            let data = try JSONEncoder().encode(outcome)
            let decoded = try JSONDecoder().decode(RequestPermissionOutcome.self, from: data)
            XCTAssertEqual(decoded, outcome)
        }
    }

    // MARK: - RequestPermissionRequest Tests

    func testRequestPermissionRequestEncoding() throws {
        let toolCall = ToolCallUpdateData(
            toolCallId: ToolCallId("tc-1"),
            title: "file_write",
            status: .inProgress
        )
        let request = RequestPermissionRequest(
            sessionId: SessionId("session-1"),
            toolCall: toolCall,
            options: [
                PermissionOption(
                    optionId: PermissionOptionId("opt-1"),
                    name: "Allow",
                    kind: .allowOnce
                )
            ]
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["toolCall"])
        XCTAssertNotNil(json?["options"])
    }

    func testRequestPermissionRequestDecoding() throws {
        let json = """
        {
            "sessionId": "session-1",
            "toolCall": {
                "toolCallId": "tc-1",
                "title": "exec",
                "status": "in_progress"
            },
            "options": [
                {"optionId": "opt-1", "name": "Allow", "kind": "allow_once"}
            ]
        }
        """

        let request = try JSONDecoder().decode(RequestPermissionRequest.self, from: Data(json.utf8))

        XCTAssertEqual(request.sessionId.value, "session-1")
        XCTAssertEqual(request.toolCall.title, "exec")
        XCTAssertEqual(request.options.count, 1)
    }

    // MARK: - RequestPermissionResponse Tests

    func testRequestPermissionResponseEncoding() throws {
        let response = RequestPermissionResponse(
            outcome: .selected(PermissionOptionId("opt-1"))
        )

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["outcome"])
    }

    func testRequestPermissionResponseDecoding() throws {
        let json = """
        {"outcome": {"outcome": "cancelled"}}
        """

        let response = try JSONDecoder().decode(RequestPermissionResponse.self, from: Data(json.utf8))

        if case .cancelled = response.outcome {
            // Success
        } else {
            XCTFail("Expected cancelled outcome")
        }
    }

    func testRequestPermissionResponseRoundTrip() throws {
        let response = RequestPermissionResponse(
            outcome: .selected(PermissionOptionId("opt-2"))
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(RequestPermissionResponse.self, from: data)

        XCTAssertEqual(decoded.outcome, response.outcome)
    }

    // MARK: - Hashable Tests

    func testPermissionOptionHashable() {
        let opt1 = PermissionOption(
            optionId: PermissionOptionId("opt-1"),
            name: "Allow",
            kind: .allowOnce
        )
        let opt2 = PermissionOption(
            optionId: PermissionOptionId("opt-1"),
            name: "Allow",
            kind: .allowOnce
        )
        let opt3 = PermissionOption(
            optionId: PermissionOptionId("opt-2"),
            name: "Reject",
            kind: .rejectOnce
        )

        XCTAssertEqual(opt1, opt2)
        XCTAssertNotEqual(opt1, opt3)

        let set: Set<PermissionOption> = [opt1, opt2, opt3]
        XCTAssertEqual(set.count, 2)
    }

    func testRequestPermissionOutcomeHashable() {
        let outcome1 = RequestPermissionOutcome.cancelled
        let outcome2 = RequestPermissionOutcome.cancelled
        let outcome3 = RequestPermissionOutcome.selected(PermissionOptionId("opt-1"))

        XCTAssertEqual(outcome1, outcome2)
        XCTAssertNotEqual(outcome1, outcome3)
    }
}
