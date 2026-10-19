import XCTest
@testable import ACPModel

internal final class V2SessionUpdateTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - user_message_chunk

    func testDecodeUserMessageChunk() throws {
        let json = """
        {
            "sessionUpdate": "user_message_chunk",
            "messageId": "msg-1",
            "content": {"type": "text", "text": "hello"}
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .userMessageChunk(let chunk) = update {
            XCTAssertEqual(chunk.messageId.rawValue, "msg-1")
            if case .text(let t) = chunk.content {
                XCTAssertEqual(t.text, "hello")
            } else {
                XCTFail("Expected .text content")
            }
        } else {
            XCTFail("Expected .userMessageChunk, got \(update)")
        }
    }

    // MARK: - user_message

    func testDecodeUserMessage() throws {
        let json = """
        {
            "sessionUpdate": "user_message",
            "messageId": "msg-2",
            "content": [{"type": "text", "text": "complete message"}]
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .userMessage(let msg) = update {
            XCTAssertEqual(msg.messageId.rawValue, "msg-2")
            if case .value(let blocks) = msg.content {
                XCTAssertEqual(blocks.count, 1)
            } else {
                XCTFail("Expected .value for content")
            }
        } else {
            XCTFail("Expected .userMessage, got \(update)")
        }
    }

    // MARK: - agent_message_chunk

    func testDecodeAgentMessageChunk() throws {
        let json = """
        {
            "sessionUpdate": "agent_message_chunk",
            "messageId": "msg-3",
            "content": {"type": "text", "text": "partial"}
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .agentMessageChunk(let chunk) = update {
            XCTAssertEqual(chunk.messageId.rawValue, "msg-3")
        } else {
            XCTFail("Expected .agentMessageChunk, got \(update)")
        }
    }

    // MARK: - agent_message

    func testDecodeAgentMessage() throws {
        let json = """
        {
            "sessionUpdate": "agent_message",
            "messageId": "msg-4",
            "content": [{"type": "text", "text": "full response"}]
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .agentMessage(let msg) = update {
            XCTAssertEqual(msg.messageId.rawValue, "msg-4")
            if case .value(let blocks) = msg.content {
                XCTAssertFalse(blocks.isEmpty)
            } else {
                XCTFail("Expected .value for content")
            }
        } else {
            XCTFail("Expected .agentMessage, got \(update)")
        }
    }

    // MARK: - agent_thought_chunk

    func testDecodeAgentThoughtChunk() throws {
        let json = """
        {
            "sessionUpdate": "agent_thought_chunk",
            "messageId": "msg-5",
            "content": {"type": "text", "text": "thinking..."}
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .agentThoughtChunk(let chunk) = update {
            XCTAssertEqual(chunk.messageId.rawValue, "msg-5")
        } else {
            XCTFail("Expected .agentThoughtChunk, got \(update)")
        }
    }

    // MARK: - agent_thought

    func testDecodeAgentThought() throws {
        let json = """
        {
            "sessionUpdate": "agent_thought",
            "messageId": "msg-6",
            "content": [{"type": "text", "text": "complete thought"}]
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .agentThought(let msg) = update {
            XCTAssertEqual(msg.messageId.rawValue, "msg-6")
        } else {
            XCTFail("Expected .agentThought, got \(update)")
        }
    }

    // MARK: - state_update

    func testDecodeStateUpdateRunning() throws {
        let json = """
        {"sessionUpdate": "state_update", "state": "running"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .stateUpdate(let stateUpdate) = update,
           case .running = stateUpdate {
            // Expected
        } else {
            XCTFail("Expected .stateUpdate(.running), got \(update)")
        }
    }

    func testDecodeStateUpdateIdle() throws {
        let json = """
        {"sessionUpdate": "state_update", "state": "idle", "stopReason": "end_turn"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .stateUpdate(let stateUpdate) = update,
           case .idle(let stopReason, _, _) = stateUpdate {
            XCTAssertEqual(stopReason, .endTurn)
        } else {
            XCTFail("Expected .stateUpdate(.idle), got \(update)")
        }
    }

    func testDecodeStateUpdateIdleWithNoStopReason() throws {
        let json = """
        {"sessionUpdate": "state_update", "state": "idle"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .stateUpdate(let stateUpdate) = update,
           case .idle(let stopReason, _, _) = stateUpdate {
            XCTAssertNil(stopReason)
        } else {
            XCTFail("Expected .stateUpdate(.idle), got \(update)")
        }
    }

    func testDecodeStateUpdateRequiresAction() throws {
        let json = """
        {"sessionUpdate": "state_update", "state": "requires_action"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .stateUpdate(let stateUpdate) = update,
           case .requiresAction = stateUpdate {
            // Expected
        } else {
            XCTFail("Expected .stateUpdate(.requiresAction), got \(update)")
        }
    }

    func testDecodeStateUpdateUnknownState() throws {
        let json = """
        {"sessionUpdate": "state_update", "state": "future_state"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .stateUpdate(let stateUpdate) = update,
           case .unknown(let state, _) = stateUpdate {
            XCTAssertEqual(state, "future_state")
        } else {
            XCTFail("Expected .stateUpdate(.unknown), got \(update)")
        }
    }

    // MARK: - tool_call_content_chunk

    func testDecodeToolCallContentChunk() throws {
        let json = """
        {
            "sessionUpdate": "tool_call_content_chunk",
            "toolCallId": "tc-1",
            "content": {"type": "content", "content": {"type": "text", "text": "partial output"}}
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .toolCallContentChunk(let chunk) = update {
            XCTAssertEqual(chunk.toolCallId.value, "tc-1")
        } else {
            XCTFail("Expected .toolCallContentChunk, got \(update)")
        }
    }

    // MARK: - tool_call_update

    func testDecodeToolCallUpdate() throws {
        let json = """
        {
            "sessionUpdate": "tool_call_update",
            "toolCallId": "tc-2",
            "title": "Reading file",
            "kind": "read",
            "status": "in_progress"
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .toolCallUpdate(let toolUpdate) = update {
            XCTAssertEqual(toolUpdate.toolCallId.value, "tc-2")
            if case .value(let title) = toolUpdate.title {
                XCTAssertEqual(title, "Reading file")
            } else {
                XCTFail("Expected .value for title")
            }
        } else {
            XCTFail("Expected .toolCallUpdate, got \(update)")
        }
    }

    // MARK: - plan_update

    func testDecodePlanUpdate() throws {
        let json = """
        {
            "sessionUpdate": "plan_update",
            "plan": {
                "type": "items",
                "planId": "plan-1",
                "entries": [
                    {"content": "Task 1", "priority": "high", "status": "pending"}
                ]
            }
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .planUpdate(let planUpdate) = update {
            if case .items(let items) = planUpdate.plan {
                XCTAssertEqual(items.planId.rawValue, "plan-1")
                XCTAssertEqual(items.entries.count, 1)
            } else {
                XCTFail("Expected .items in plan update")
            }
        } else {
            XCTFail("Expected .planUpdate, got \(update)")
        }
    }

    // MARK: - plan_removed

    func testDecodePlanRemoved() throws {
        let json = """
        {"sessionUpdate": "plan_removed", "planId": "plan-old"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .planRemoved(let removed) = update {
            XCTAssertEqual(removed.planId.rawValue, "plan-old")
        } else {
            XCTFail("Expected .planRemoved, got \(update)")
        }
    }

    // MARK: - available_commands_update

    func testDecodeAvailableCommandsUpdate() throws {
        let json = """
        {
            "sessionUpdate": "available_commands_update",
            "availableCommands": [
                {"name": "search", "description": "Search files"}
            ]
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .availableCommandsUpdate(let commandsUpdate) = update {
            XCTAssertEqual(commandsUpdate.availableCommands.count, 1)
            XCTAssertEqual(commandsUpdate.availableCommands[0].name, "search")
        } else {
            XCTFail("Expected .availableCommandsUpdate, got \(update)")
        }
    }

    // MARK: - config_option_update

    func testDecodeConfigOptionUpdate() throws {
        // V2SessionConfigOption requires type, configId, name, currentValue, options
        let json = """
        {
            "sessionUpdate": "config_option_update",
            "configOptions": [
                {
                    "type": "select",
                    "configId": "theme",
                    "name": "Theme",
                    "currentValue": "dark",
                    "options": []
                }
            ]
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .configOptionUpdate(let configUpdate) = update {
            XCTAssertEqual(configUpdate.configOptions.count, 1)
        } else {
            XCTFail("Expected .configOptionUpdate, got \(update)")
        }
    }

    // MARK: - session_info_update

    func testDecodeSessionInfoUpdate() throws {
        let json = """
        {
            "sessionUpdate": "session_info_update",
            "title": "My Session",
            "updatedAt": "2024-01-01T00:00:00Z"
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .sessionInfoUpdate(let infoUpdate) = update {
            if case .value(let title) = infoUpdate.title {
                XCTAssertEqual(title, "My Session")
            } else {
                XCTFail("Expected .value for title")
            }
        } else {
            XCTFail("Expected .sessionInfoUpdate, got \(update)")
        }
    }

    func testDecodeSessionInfoUpdateWithNullTitle() throws {
        let json = """
        {"sessionUpdate": "session_info_update", "title": null}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .sessionInfoUpdate(let infoUpdate) = update {
            XCTAssertEqual(infoUpdate.title, .null)
        } else {
            XCTFail("Expected .sessionInfoUpdate, got \(update)")
        }
    }

    // MARK: - usage_update

    func testDecodeUsageUpdate() throws {
        let json = """
        {
            "sessionUpdate": "usage_update",
            "used": 1000,
            "size": 50000
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .usageUpdate(let usageUpdate) = update {
            XCTAssertEqual(usageUpdate.used, 1000)
            XCTAssertEqual(usageUpdate.size, 50000)
            XCTAssertNil(usageUpdate.cost)
        } else {
            XCTFail("Expected .usageUpdate, got \(update)")
        }
    }

    func testDecodeUsageUpdateWithCost() throws {
        let json = """
        {
            "sessionUpdate": "usage_update",
            "used": 500,
            "size": 25000,
            "cost": {"amount": 0.05, "currency": "USD"}
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .usageUpdate(let usageUpdate) = update {
            XCTAssertNotNil(usageUpdate.cost)
            XCTAssertEqual(usageUpdate.cost?.currency, "USD")
        } else {
            XCTFail("Expected .usageUpdate, got \(update)")
        }
    }

    // MARK: - notice

    func testDecodeNoticeInfo() throws {
        let json = """
        {"sessionUpdate": "notice", "severity": "info", "title": "Hello"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .notice(let notice) = update {
            XCTAssertEqual(notice.severity, .info)
            XCTAssertEqual(notice.title, "Hello")
        } else {
            XCTFail("Expected .notice, got \(update)")
        }
    }

    func testDecodeNoticeWarning() throws {
        let json = """
        {"sessionUpdate": "notice", "severity": "warning", "title": "Careful"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .notice(let notice) = update {
            XCTAssertEqual(notice.severity, .warning)
        } else {
            XCTFail("Expected .notice, got \(update)")
        }
    }

    func testDecodeNoticeError() throws {
        let json = """
        {"sessionUpdate": "notice", "severity": "error", "title": "Problem"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .notice(let notice) = update {
            XCTAssertEqual(notice.severity, .error)
        } else {
            XCTFail("Expected .notice, got \(update)")
        }
    }

    func testDecodeNoticeUnknownSeverity() throws {
        let json = """
        {"sessionUpdate": "notice", "severity": "critical", "title": "Alert"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .notice(let notice) = update {
            XCTAssertEqual(notice.severity.rawValue, "critical")
        } else {
            XCTFail("Expected .notice, got \(update)")
        }
    }

    // MARK: - compaction_update

    func testDecodeCompactionUpdateInProgress() throws {
        let json = """
        {
            "sessionUpdate": "compaction_update",
            "compactionId": "cmp-1",
            "status": "in_progress"
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .compactionUpdate(let compactionUpdate) = update {
            XCTAssertEqual(compactionUpdate.compactionId, "cmp-1")
            XCTAssertEqual(compactionUpdate.status, .inProgress)
        } else {
            XCTFail("Expected .compactionUpdate, got \(update)")
        }
    }

    func testDecodeCompactionUpdateCompleted() throws {
        let json = """
        {
            "sessionUpdate": "compaction_update",
            "compactionId": "cmp-2",
            "status": "completed"
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .compactionUpdate(let compactionUpdate) = update {
            XCTAssertEqual(compactionUpdate.status, .completed)
        } else {
            XCTFail("Expected .compactionUpdate, got \(update)")
        }
    }

    func testDecodeCompactionUpdateUnknownStatus() throws {
        let json = """
        {
            "sessionUpdate": "compaction_update",
            "compactionId": "cmp-3",
            "status": "future_status"
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .compactionUpdate(let compactionUpdate) = update {
            XCTAssertEqual(compactionUpdate.status.rawValue, "future_status")
        } else {
            XCTFail("Expected .compactionUpdate, got \(update)")
        }
    }

    // MARK: - compaction_summary_chunk

    func testDecodeCompactionSummaryChunk() throws {
        let json = """
        {
            "sessionUpdate": "compaction_summary_chunk",
            "compactionId": "cmp-1",
            "content": {"type": "text", "text": "summary part"}
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .compactionSummaryChunk(let chunk) = update {
            XCTAssertEqual(chunk.compactionId, "cmp-1")
        } else {
            XCTFail("Expected .compactionSummaryChunk, got \(update)")
        }
    }

    // MARK: - terminal_update

    func testDecodeTerminalUpdate() throws {
        let json = """
        {
            "sessionUpdate": "terminal_update",
            "terminalId": "term-1",
            "command": "bash",
            "cwd": "/home/user"
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .terminalUpdate(let terminalUpdate) = update {
            XCTAssertEqual(terminalUpdate.terminalId.value, "term-1")
            if case .value(let command) = terminalUpdate.command {
                XCTAssertEqual(command, "bash")
            } else {
                XCTFail("Expected .value for command")
            }
        } else {
            XCTFail("Expected .terminalUpdate, got \(update)")
        }
    }

    func testDecodeTerminalUpdateMinimal() throws {
        let json = """
        {"sessionUpdate": "terminal_update", "terminalId": "term-2"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .terminalUpdate(let terminalUpdate) = update {
            XCTAssertEqual(terminalUpdate.terminalId.value, "term-2")
            XCTAssertEqual(terminalUpdate.command, .undefined)
        } else {
            XCTFail("Expected .terminalUpdate, got \(update)")
        }
    }

    // MARK: - terminal_output_chunk

    func testDecodeTerminalOutputChunk() throws {
        let json = """
        {
            "sessionUpdate": "terminal_output_chunk",
            "terminalId": "term-1",
            "data": "aGVsbG8="
        }
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .terminalOutputChunk(let chunk) = update {
            XCTAssertEqual(chunk.terminalId.value, "term-1")
            XCTAssertEqual(chunk.data, "aGVsbG8=")
        } else {
            XCTFail("Expected .terminalOutputChunk, got \(update)")
        }
    }

    // MARK: - unknown variant

    func testDecodeUnknownVariant() throws {
        let json = """
        {"sessionUpdate": "future_update", "extra": "payload"}
        """
        let update = try decoder.decode(V2SessionUpdate.self, from: json.data(using: .utf8)!)

        if case .unknown = update {
            // Expected
        } else {
            XCTFail("Expected .unknown session update, got \(update)")
        }
    }
}
