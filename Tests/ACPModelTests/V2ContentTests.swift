import XCTest
@testable import ACPModel

internal final class V2ContentTests: XCTestCase {

    // MARK: - V2ContentBlock Tests

    func testV2ContentBlockTextDecoding() throws {
        let json = """
        {"type":"text","text":"Hello, world!"}
        """
        let block = try JSONDecoder().decode(V2ContentBlock.self, from: json.data(using: .utf8)!)

        if case .text(let t) = block {
            XCTAssertEqual(t.text, "Hello, world!")
        } else {
            XCTFail("Expected .text block, got \(block)")
        }
    }

    func testV2ContentBlockTextEncoding() throws {
        let block = V2ContentBlock.text(V2ContentBlock.Text(text: "test"))
        let data = try JSONEncoder().encode(block)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["type"] as? String, "text")
        XCTAssertEqual(json?["text"] as? String, "test")
    }

    func testV2ContentBlockImageDecoding() throws {
        let json = """
        {"type":"image","mimeType":"image/png","data":"iVBORw0KGgo="}
        """
        let block = try JSONDecoder().decode(V2ContentBlock.self, from: json.data(using: .utf8)!)

        if case .image(let img) = block {
            XCTAssertEqual(img.mimeType, "image/png")
            XCTAssertEqual(img.data, "iVBORw0KGgo=")
        } else {
            XCTFail("Expected .image block, got \(block)")
        }
    }

    func testV2ContentBlockResourceLinkDecoding() throws {
        let json = """
        {"type":"resource_link","name":"file.txt","uri":"file:///path/to/file.txt","mimeType":"text/plain"}
        """
        let block = try JSONDecoder().decode(V2ContentBlock.self, from: json.data(using: .utf8)!)

        if case .resourceLink(let link) = block {
            XCTAssertEqual(link.name, "file.txt")
            XCTAssertEqual(link.uri, "file:///path/to/file.txt")
            XCTAssertEqual(link.mimeType, "text/plain")
        } else {
            XCTFail("Expected .resourceLink block, got \(block)")
        }
    }

    func testV2ContentBlockUnknownType() throws {
        let json = """
        {"type":"future_block","custom":"data"}
        """
        let block = try JSONDecoder().decode(V2ContentBlock.self, from: json.data(using: .utf8)!)

        if case .unknown = block {
            // Expected
        } else {
            XCTFail("Expected .unknown block, got \(block)")
        }
    }

    func testV2ContentBlockRoundTrip() throws {
        let original = V2ContentBlock.text(V2ContentBlock.Text(text: "round trip"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(V2ContentBlock.self, from: data)

        if case .text(let t) = decoded {
            XCTAssertEqual(t.text, "round trip")
        } else {
            XCTFail("Expected .text block after round trip")
        }
    }

    // MARK: - V2ContentChunk Tests

    func testV2ContentChunkDecoding() throws {
        let json = """
        {
            "messageId": "msg-1",
            "content": {"type": "text", "text": "chunk text"}
        }
        """
        let chunk = try JSONDecoder().decode(V2ContentChunk.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(chunk.messageId.rawValue, "msg-1")
        if case .text(let t) = chunk.content {
            XCTAssertEqual(t.text, "chunk text")
        } else {
            XCTFail("Expected .text content in chunk")
        }
    }

    func testV2ContentChunkEncoding() throws {
        let chunk = V2ContentChunk(
            messageId: MessageId(rawValue: "msg-abc"),
            content: .text(V2ContentBlock.Text(text: "hello")),
            _meta: nil
        )

        let data = try JSONEncoder().encode(chunk)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["messageId"] as? String, "msg-abc")
        let content = json?["content"] as? [String: Any]
        XCTAssertEqual(content?["type"] as? String, "text")
        XCTAssertEqual(content?["text"] as? String, "hello")
    }

    // MARK: - V2AvailableCommandsUpdate Tests

    func testV2AvailableCommandsUpdateDecoding() throws {
        // V2AvailableCommand.input is a single optional V2AvailableCommandInput
        let json = """
        {
            "availableCommands": [
                {
                    "name": "search",
                    "description": "Search files",
                    "input": {"type": "text", "hint": "Enter query"}
                }
            ]
        }
        """
        let update = try JSONDecoder().decode(V2AvailableCommandsUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.availableCommands.count, 1)
        XCTAssertEqual(update.availableCommands[0].name, "search")
        XCTAssertEqual(update.availableCommands[0].description, "Search files")

        if case .text(let input) = update.availableCommands[0].input {
            XCTAssertEqual(input.hint, "Enter query")
        } else {
            XCTFail("Expected .text input")
        }
    }

    func testV2AvailableCommandsUpdateWithNoInput() throws {
        let json = """
        {
            "availableCommands": [
                {"name": "help", "description": "Show help"}
            ]
        }
        """
        let update = try JSONDecoder().decode(V2AvailableCommandsUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.availableCommands.count, 1)
        XCTAssertNil(update.availableCommands[0].input)
    }

    func testV2ConfigOptionUpdateDecoding() throws {
        // V2SessionConfigOption requires type, configId, name, currentValue, options
        let json = """
        {
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
        let update = try JSONDecoder().decode(V2ConfigOptionUpdate.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(update.configOptions.count, 1)
    }
}
