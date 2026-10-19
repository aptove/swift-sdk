import XCTest
@testable import ACPModel

internal final class V2ToolCallTests: XCTestCase {

    // MARK: - V2ToolKind Tests

    func testV2ToolKindKnownValues() {
        XCTAssertEqual(V2ToolKind.read.rawValue, "read")
        XCTAssertEqual(V2ToolKind.edit.rawValue, "edit")
        XCTAssertEqual(V2ToolKind.delete.rawValue, "delete")
        XCTAssertEqual(V2ToolKind.move.rawValue, "move")
        XCTAssertEqual(V2ToolKind.search.rawValue, "search")
        XCTAssertEqual(V2ToolKind.execute.rawValue, "execute")
        XCTAssertEqual(V2ToolKind.think.rawValue, "think")
        XCTAssertEqual(V2ToolKind.fetch.rawValue, "fetch")
        XCTAssertEqual(V2ToolKind.switchMode.rawValue, "switch_mode")
        XCTAssertEqual(V2ToolKind.other.rawValue, "other")
    }

    func testV2ToolKindEncoding() throws {
        let data = try JSONEncoder().encode(V2ToolKind.read)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"read\"")
    }

    func testV2ToolKindDecoding() throws {
        let data = Data("\"execute\"".utf8)
        let kind = try JSONDecoder().decode(V2ToolKind.self, from: data)
        XCTAssertEqual(kind, .execute)
    }

    func testV2ToolKindUnknownValue() throws {
        let data = Data("\"future_tool\"".utf8)
        let kind = try JSONDecoder().decode(V2ToolKind.self, from: data)
        XCTAssertEqual(kind.rawValue, "future_tool")
        XCTAssertNotEqual(kind, .read)
    }

    // MARK: - V2ToolCallStatus Tests

    func testV2ToolCallStatusKnownValues() {
        XCTAssertEqual(V2ToolCallStatus.pending.rawValue, "pending")
        XCTAssertEqual(V2ToolCallStatus.inProgress.rawValue, "in_progress")
        XCTAssertEqual(V2ToolCallStatus.completed.rawValue, "completed")
        XCTAssertEqual(V2ToolCallStatus.failed.rawValue, "failed")
        XCTAssertEqual(V2ToolCallStatus.cancelled.rawValue, "cancelled")
    }

    func testV2ToolCallStatusDecoding() throws {
        let data = Data("\"in_progress\"".utf8)
        let status = try JSONDecoder().decode(V2ToolCallStatus.self, from: data)
        XCTAssertEqual(status, .inProgress)
    }

    func testV2ToolCallStatusUnknownValue() throws {
        let data = Data("\"future_status\"".utf8)
        let status = try JSONDecoder().decode(V2ToolCallStatus.self, from: data)
        XCTAssertEqual(status.rawValue, "future_status")
    }

    // MARK: - ToolCallId Tests

    func testToolCallIdEncoding() throws {
        let id = ToolCallId(value: "tc-1")
        let data = try JSONEncoder().encode(id)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"tc-1\"")
    }

    func testToolCallIdDecoding() throws {
        let data = Data("\"tc-2\"".utf8)
        let id = try JSONDecoder().decode(ToolCallId.self, from: data)
        XCTAssertEqual(id.value, "tc-2")
    }

    func testToolCallIdHashable() {
        let id1 = ToolCallId(value: "same")
        let id2 = ToolCallId(value: "same")
        let id3 = ToolCallId(value: "different")

        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)

        var set = Set<ToolCallId>()
        set.insert(id1)
        set.insert(id2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - V2ToolCallContentChunk Tests

    func testV2ToolCallContentChunkDecoding() throws {
        // V2ToolCallContent type "content" wraps a V2ContentBlock
        let json = """
        {
            "toolCallId": "tc-1",
            "content": {"type": "content", "content": {"type": "text", "text": "output chunk"}}
        }
        """
        let chunk = try JSONDecoder().decode(V2ToolCallContentChunk.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(chunk.toolCallId.value, "tc-1")
        if case .content(let c) = chunk.content,
           case .text(let t) = c.content {
            XCTAssertEqual(t.text, "output chunk")
        } else {
            XCTFail("Expected .content(.text) in tool call content chunk")
        }
    }

    func testV2ToolCallContentChunkUnknownType() throws {
        let json = """
        {
            "toolCallId": "tc-2",
            "content": {"type": "future_type", "data": "something"}
        }
        """
        let chunk = try JSONDecoder().decode(V2ToolCallContentChunk.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(chunk.toolCallId.value, "tc-2")
        if case .unknown = chunk.content {
            // Expected
        } else {
            XCTFail("Expected .unknown for future content type")
        }
    }

    // MARK: - V2ToolCallUpdate Tests

    func testV2ToolCallUpdateMinimalDecoding() throws {
        let json = """
        {"toolCallId":"tc-1"}
        """
        let update = try JSONDecoder().decode(V2ToolCallUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.toolCallId.value, "tc-1")
        XCTAssertEqual(update.title, .undefined)
        XCTAssertEqual(update.kind, .undefined)
        XCTAssertEqual(update.status, .undefined)
        XCTAssertEqual(update.content, .undefined)
    }

    func testV2ToolCallUpdateWithNullFields() throws {
        let json = """
        {"toolCallId":"tc-1","title":null,"kind":null}
        """
        let update = try JSONDecoder().decode(V2ToolCallUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.toolCallId.value, "tc-1")
        XCTAssertEqual(update.title, .null)
        XCTAssertEqual(update.kind, .null)
    }

    func testV2ToolCallUpdateWithValues() throws {
        let json = """
        {
            "toolCallId": "tc-2",
            "title": "Reading file",
            "kind": "read",
            "status": "in_progress"
        }
        """
        let update = try JSONDecoder().decode(V2ToolCallUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.toolCallId.value, "tc-2")
        if case .value(let title) = update.title {
            XCTAssertEqual(title, "Reading file")
        } else {
            XCTFail("Expected .value for title")
        }
        if case .value(let kind) = update.kind {
            XCTAssertEqual(kind, .read)
        } else {
            XCTFail("Expected .value for kind")
        }
        if case .value(let status) = update.status {
            XCTAssertEqual(status, .inProgress)
        } else {
            XCTFail("Expected .value for status")
        }
    }

    func testV2ToolCallUpdateApplyUpdateUndefinedKeepsPriorValue() throws {
        // applyUpdate returns a new value — fields are immutable
        let base = V2ToolCallUpdate(
            toolCallId: ToolCallId(value: "tc-1"),
            title: .value("Original Title"),
            kind: .value(.read),
            status: .value(.pending)
        )

        // patch has all undefined — should not overwrite prior values
        let patch = V2ToolCallUpdate(toolCallId: ToolCallId(value: "tc-1"))
        let result = base.applyUpdate(patch)

        if case .value(let t) = result.title {
            XCTAssertEqual(t, "Original Title")
        } else {
            XCTFail("Expected title to remain 'Original Title' after .undefined patch")
        }
        if case .value(let k) = result.kind {
            XCTAssertEqual(k, .read)
        } else {
            XCTFail("Expected kind to remain .read after .undefined patch")
        }
        if case .value(let s) = result.status {
            XCTAssertEqual(s, .pending)
        } else {
            XCTFail("Expected status to remain .pending after .undefined patch")
        }
    }

    func testV2ToolCallUpdateApplyUpdateNullClearsValue() throws {
        let base = V2ToolCallUpdate(
            toolCallId: ToolCallId(value: "tc-1"),
            title: .value("Some Title")
        )
        let patch = V2ToolCallUpdate(toolCallId: ToolCallId(value: "tc-1"), title: .null)

        let result = base.applyUpdate(patch)
        XCTAssertEqual(result.title, .null)
    }

    func testV2ToolCallUpdateApplyUpdateValueOverwrites() throws {
        let base = V2ToolCallUpdate(
            toolCallId: ToolCallId(value: "tc-1"),
            status: .value(.pending)
        )
        let patch = V2ToolCallUpdate(
            toolCallId: ToolCallId(value: "tc-1"),
            status: .value(.completed)
        )

        let result = base.applyUpdate(patch)
        if case .value(let s) = result.status {
            XCTAssertEqual(s, .completed)
        } else {
            XCTFail("Expected status to be .completed after patch")
        }
    }
}
