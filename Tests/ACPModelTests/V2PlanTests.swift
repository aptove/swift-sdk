import XCTest
@testable import ACPModel

internal final class V2PlanTests: XCTestCase {

    // MARK: - V2PlanEntryPriority Tests

    func testV2PlanEntryPriorityKnownValues() {
        XCTAssertEqual(V2PlanEntryPriority.high.rawValue, "high")
        XCTAssertEqual(V2PlanEntryPriority.medium.rawValue, "medium")
        XCTAssertEqual(V2PlanEntryPriority.low.rawValue, "low")
    }

    func testV2PlanEntryPriorityEncoding() throws {
        let data = try JSONEncoder().encode(V2PlanEntryPriority.high)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"high\"")
    }

    func testV2PlanEntryPriorityDecoding() throws {
        let data = "\"medium\"".data(using: .utf8)!
        let priority = try JSONDecoder().decode(V2PlanEntryPriority.self, from: data)
        XCTAssertEqual(priority, .medium)
    }

    func testV2PlanEntryPriorityUnknownValue() throws {
        let data = "\"critical\"".data(using: .utf8)!
        let priority = try JSONDecoder().decode(V2PlanEntryPriority.self, from: data)
        XCTAssertEqual(priority.rawValue, "critical")
        XCTAssertNotEqual(priority, .high)
    }

    // MARK: - V2PlanEntryStatus Tests

    func testV2PlanEntryStatusKnownValues() {
        XCTAssertEqual(V2PlanEntryStatus.pending.rawValue, "pending")
        XCTAssertEqual(V2PlanEntryStatus.inProgress.rawValue, "in_progress")
        XCTAssertEqual(V2PlanEntryStatus.completed.rawValue, "completed")
    }

    func testV2PlanEntryStatusDecoding() throws {
        let data = "\"in_progress\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(V2PlanEntryStatus.self, from: data)
        XCTAssertEqual(status, .inProgress)
    }

    func testV2PlanEntryStatusUnknownValue() throws {
        let data = "\"archived\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(V2PlanEntryStatus.self, from: data)
        XCTAssertEqual(status.rawValue, "archived")
    }

    // MARK: - V2PlanEntry Tests

    func testV2PlanEntryDecoding() throws {
        let json = """
        {
            "content": "Implement feature X",
            "priority": "high",
            "status": "pending"
        }
        """
        let entry = try JSONDecoder().decode(V2PlanEntry.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(entry.content, "Implement feature X")
        XCTAssertEqual(entry.priority, .high)
        XCTAssertEqual(entry.status, .pending)
    }

    func testV2PlanEntryEncoding() throws {
        let entry = V2PlanEntry(
            content: "Write tests",
            priority: .medium,
            status: .inProgress
        )

        let data = try JSONEncoder().encode(entry)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["content"] as? String, "Write tests")
        XCTAssertEqual(json?["priority"] as? String, "medium")
        XCTAssertEqual(json?["status"] as? String, "in_progress")
    }

    func testV2PlanEntryRoundTrip() throws {
        let original = V2PlanEntry(
            content: "Deploy to production",
            priority: .low,
            status: .completed
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(V2PlanEntry.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - V2PlanId Tests

    func testV2PlanIdEncoding() throws {
        let id = V2PlanId(rawValue: "plan-123")
        let data = try JSONEncoder().encode(id)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"plan-123\"")
    }

    func testV2PlanIdDecoding() throws {
        let data = "\"plan-456\"".data(using: .utf8)!
        let id = try JSONDecoder().decode(V2PlanId.self, from: data)
        XCTAssertEqual(id.rawValue, "plan-456")
    }

    func testV2PlanIdStringLiteral() {
        let id: V2PlanId = "plan-lit"
        XCTAssertEqual(id.rawValue, "plan-lit")
    }

    func testV2PlanIdHashable() {
        let id1 = V2PlanId(rawValue: "same")
        let id2 = V2PlanId(rawValue: "same")
        let id3 = V2PlanId(rawValue: "different")

        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)

        var set = Set<V2PlanId>()
        set.insert(id1)
        set.insert(id2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - V2PlanUpdateContent Tests

    func testV2PlanUpdateContentItemsDecoding() throws {
        let json = """
        {
            "type": "items",
            "planId": "plan-1",
            "entries": [
                {"content": "Step 1", "priority": "high", "status": "pending"},
                {"content": "Step 2", "priority": "low", "status": "completed"}
            ]
        }
        """
        let content = try JSONDecoder().decode(V2PlanUpdateContent.self, from: json.data(using: .utf8)!)

        if case .items(let items) = content {
            XCTAssertEqual(items.planId.rawValue, "plan-1")
            XCTAssertEqual(items.entries.count, 2)
            XCTAssertEqual(items.entries[0].content, "Step 1")
            XCTAssertEqual(items.entries[1].status, .completed)
        } else {
            XCTFail("Expected .items plan update content, got \(content)")
        }
    }

    func testV2PlanUpdateContentMarkdownDecoding() throws {
        let json = """
        {
            "type": "markdown",
            "planId": "plan-2",
            "content": "# Plan\\n- Step 1\\n- Step 2"
        }
        """
        let content = try JSONDecoder().decode(V2PlanUpdateContent.self, from: json.data(using: .utf8)!)

        if case .markdown(let md) = content {
            XCTAssertEqual(md.planId.rawValue, "plan-2")
            XCTAssertEqual(md.content, "# Plan\n- Step 1\n- Step 2")
        } else {
            XCTFail("Expected .markdown plan update content, got \(content)")
        }
    }

    func testV2PlanUpdateContentFileDecoding() throws {
        let json = """
        {
            "type": "file",
            "planId": "plan-3",
            "uri": "file:///project/PLAN.md"
        }
        """
        let content = try JSONDecoder().decode(V2PlanUpdateContent.self, from: json.data(using: .utf8)!)

        if case .file(let file) = content {
            XCTAssertEqual(file.planId.rawValue, "plan-3")
            XCTAssertEqual(file.uri, "file:///project/PLAN.md")
        } else {
            XCTFail("Expected .file plan update content, got \(content)")
        }
    }

    func testV2PlanUpdateContentUnknownType() throws {
        let json = """
        {"type": "future_type", "planId": "plan-x"}
        """
        let content = try JSONDecoder().decode(V2PlanUpdateContent.self, from: json.data(using: .utf8)!)

        if case .unknown(let type, let planId, _) = content {
            XCTAssertEqual(type, "future_type")
            XCTAssertEqual(planId.rawValue, "plan-x")
        } else {
            XCTFail("Expected .unknown plan update content, got \(content)")
        }
    }

    // MARK: - V2PlanUpdate Tests

    func testV2PlanUpdateDecoding() throws {
        let json = """
        {
            "plan": {
                "type": "items",
                "planId": "plan-3",
                "entries": []
            }
        }
        """
        let update = try JSONDecoder().decode(V2PlanUpdate.self, from: json.data(using: .utf8)!)

        if case .items(let items) = update.plan {
            XCTAssertEqual(items.planId.rawValue, "plan-3")
            XCTAssertTrue(items.entries.isEmpty)
        } else {
            XCTFail("Expected .items in plan update")
        }
    }

    // MARK: - V2PlanRemoved Tests

    func testV2PlanRemovedDecoding() throws {
        let json = """
        {"planId": "plan-to-remove"}
        """
        let removed = try JSONDecoder().decode(V2PlanRemoved.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(removed.planId.rawValue, "plan-to-remove")
    }

    func testV2PlanRemovedEncoding() throws {
        let removed = V2PlanRemoved(planId: V2PlanId(rawValue: "plan-99"))

        let data = try JSONEncoder().encode(removed)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["planId"] as? String, "plan-99")
    }
}
