import XCTest
@testable import ACPModel

internal final class V2TypesTests: XCTestCase {

    // MARK: - V2Role Tests

    func testV2RoleKnownValues() {
        XCTAssertEqual(V2Role.assistant.rawValue, "assistant")
        XCTAssertEqual(V2Role.user.rawValue, "user")
    }

    func testV2RoleEncoding() throws {
        let data = try JSONEncoder().encode(V2Role.assistant)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"assistant\"")
    }

    func testV2RoleDecoding() throws {
        let data = "\"user\"".data(using: .utf8)!
        let role = try JSONDecoder().decode(V2Role.self, from: data)
        XCTAssertEqual(role, .user)
    }

    func testV2RoleUnknownValue() throws {
        let data = "\"moderator\"".data(using: .utf8)!
        let role = try JSONDecoder().decode(V2Role.self, from: data)
        XCTAssertEqual(role.rawValue, "moderator")
        XCTAssertNotEqual(role, .assistant)
        XCTAssertNotEqual(role, .user)
    }

    func testV2RoleRoundTrip() throws {
        let original = V2Role.assistant
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(V2Role.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testV2RoleHashable() {
        var set = Set<V2Role>()
        set.insert(.assistant)
        set.insert(.assistant)
        set.insert(.user)
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - V2StopReason Tests

    func testV2StopReasonKnownValues() {
        XCTAssertEqual(V2StopReason.endTurn.rawValue, "end_turn")
        XCTAssertEqual(V2StopReason.maxTokens.rawValue, "max_tokens")
        XCTAssertEqual(V2StopReason.maxTurnRequests.rawValue, "max_turn_requests")
        XCTAssertEqual(V2StopReason.refusal.rawValue, "refusal")
        XCTAssertEqual(V2StopReason.cancelled.rawValue, "cancelled")
    }

    func testV2StopReasonEncoding() throws {
        let data = try JSONEncoder().encode(V2StopReason.endTurn)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"end_turn\"")
    }

    func testV2StopReasonDecoding() throws {
        let data = "\"max_tokens\"".data(using: .utf8)!
        let reason = try JSONDecoder().decode(V2StopReason.self, from: data)
        XCTAssertEqual(reason, .maxTokens)
    }

    func testV2StopReasonUnknownValue() throws {
        let data = "\"future_reason\"".data(using: .utf8)!
        let reason = try JSONDecoder().decode(V2StopReason.self, from: data)
        XCTAssertEqual(reason.rawValue, "future_reason")
        XCTAssertNotEqual(reason, .endTurn)
    }

    func testV2StopReasonRoundTrip() throws {
        let original = V2StopReason.cancelled
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(V2StopReason.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testV2StopReasonHashable() {
        var set = Set<V2StopReason>()
        set.insert(.endTurn)
        set.insert(.endTurn)
        set.insert(.maxTokens)
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - MessageId Tests

    func testMessageIdEncoding() throws {
        let id = MessageId(rawValue: "msg-123")
        let data = try JSONEncoder().encode(id)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"msg-123\"")
    }

    func testMessageIdDecoding() throws {
        let data = "\"msg-456\"".data(using: .utf8)!
        let id = try JSONDecoder().decode(MessageId.self, from: data)
        XCTAssertEqual(id.rawValue, "msg-456")
    }

    func testMessageIdHashable() {
        let id1 = MessageId(rawValue: "same")
        let id2 = MessageId(rawValue: "same")
        let id3 = MessageId(rawValue: "different")

        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)

        var set = Set<MessageId>()
        set.insert(id1)
        set.insert(id2)
        XCTAssertEqual(set.count, 1)
    }
}
