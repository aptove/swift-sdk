import XCTest
@testable import ACPModel

internal final class V2TerminalModelTests: XCTestCase {

    // MARK: - TerminalId Tests

    func testTerminalIdEncoding() throws {
        let id = TerminalId(value: "term-1")
        let data = try JSONEncoder().encode(id)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"term-1\"")
    }

    func testTerminalIdDecoding() throws {
        let data = Data("\"term-2\"".utf8)
        let id = try JSONDecoder().decode(TerminalId.self, from: data)
        XCTAssertEqual(id.value, "term-2")
    }

    func testTerminalIdStringLiteral() {
        let id: TerminalId = "term-lit"
        XCTAssertEqual(id.value, "term-lit")
    }

    func testTerminalIdHashable() {
        let id1 = TerminalId(value: "same")
        let id2 = TerminalId(value: "same")
        let id3 = TerminalId(value: "different")

        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)

        var set = Set<TerminalId>()
        set.insert(id1)
        set.insert(id2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - V2TerminalOutput Tests

    func testV2TerminalOutputDecoding() throws {
        let json = """
        {"data": "SGVsbG8gV29ybGQ="}
        """
        let output = try JSONDecoder().decode(V2TerminalOutput.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(output.data, "SGVsbG8gV29ybGQ=")
    }

    func testV2TerminalOutputEncoding() throws {
        let output = V2TerminalOutput(data: "dGVzdA==", _meta: nil)
        let data = try JSONEncoder().encode(output)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["data"] as? String, "dGVzdA==")
    }

    // MARK: - V2TerminalExitStatus Tests

    func testV2TerminalExitStatusWithExitCode() throws {
        let json = """
        {"exitCode": 0}
        """
        let status = try JSONDecoder().decode(V2TerminalExitStatus.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(status.exitCode, 0)
        XCTAssertNil(status.signal)
    }

    func testV2TerminalExitStatusWithSignal() throws {
        let json = """
        {"signal": "SIGTERM"}
        """
        let status = try JSONDecoder().decode(V2TerminalExitStatus.self, from: json.data(using: .utf8)!)
        XCTAssertNil(status.exitCode)
        XCTAssertEqual(status.signal, "SIGTERM")
    }

    func testV2TerminalExitStatusNonZeroExitCode() throws {
        let json = """
        {"exitCode": 1}
        """
        let status = try JSONDecoder().decode(V2TerminalExitStatus.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(status.exitCode, 1)
    }

    // MARK: - V2TerminalUpdate Tests

    func testV2TerminalUpdateMinimalDecoding() throws {
        let json = """
        {"terminalId": "term-1"}
        """
        let update = try JSONDecoder().decode(V2TerminalUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.terminalId.value, "term-1")
        XCTAssertEqual(update.command, .undefined)
        XCTAssertEqual(update.cwd, .undefined)
        XCTAssertEqual(update.exitStatus, .undefined)
    }

    func testV2TerminalUpdateWithNullFields() throws {
        let json = """
        {"terminalId": "term-1", "command": null, "cwd": null}
        """
        let update = try JSONDecoder().decode(V2TerminalUpdate.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(update.command, .null)
        XCTAssertEqual(update.cwd, .null)
    }

    func testV2TerminalUpdateWithValues() throws {
        let json = """
        {
            "terminalId": "term-1",
            "command": "bash",
            "cwd": "/home/user"
        }
        """
        let update = try JSONDecoder().decode(V2TerminalUpdate.self, from: json.data(using: .utf8)!)

        if case .value(let command) = update.command {
            XCTAssertEqual(command, "bash")
        } else {
            XCTFail("Expected .value for command")
        }
        if case .value(let cwd) = update.cwd {
            XCTAssertEqual(cwd, "/home/user")
        } else {
            XCTFail("Expected .value for cwd")
        }
    }

    func testV2TerminalUpdateApplyUpdateUndefinedKeepsPriorValue() throws {
        // applyUpdate returns a new value — fields are immutable
        let base = V2TerminalUpdate(
            terminalId: TerminalId(value: "term-1"),
            command: .value("bash"),
            cwd: .value("/original/path")
        )

        // patch has all undefined — should not overwrite prior values
        let patch = V2TerminalUpdate(terminalId: TerminalId(value: "term-1"))
        let result = base.applyUpdate(patch)

        if case .value(let c) = result.command {
            XCTAssertEqual(c, "bash")
        } else {
            XCTFail("Expected command to remain 'bash' after .undefined patch")
        }
        if case .value(let cwd) = result.cwd {
            XCTAssertEqual(cwd, "/original/path")
        } else {
            XCTFail("Expected cwd to remain '/original/path' after .undefined patch")
        }
    }

    func testV2TerminalUpdateApplyUpdateNullClearsValue() throws {
        let base = V2TerminalUpdate(
            terminalId: TerminalId(value: "term-1"),
            command: .value("bash")
        )
        let patch = V2TerminalUpdate(terminalId: TerminalId(value: "term-1"), command: .null)

        let result = base.applyUpdate(patch)
        XCTAssertEqual(result.command, .null)
    }

    func testV2TerminalUpdateApplyUpdateValueOverwrites() throws {
        let base = V2TerminalUpdate(
            terminalId: TerminalId(value: "term-1"),
            cwd: .value("/old/path")
        )
        let patch = V2TerminalUpdate(
            terminalId: TerminalId(value: "term-1"),
            cwd: .value("/new/path")
        )

        let result = base.applyUpdate(patch)
        if case .value(let c) = result.cwd {
            XCTAssertEqual(c, "/new/path")
        } else {
            XCTFail("Expected cwd to be '/new/path' after patch")
        }
    }

    // MARK: - V2TerminalOutputChunk Tests

    func testV2TerminalOutputChunkDecoding() throws {
        let json = """
        {
            "terminalId": "term-1",
            "data": "aGVsbG8="
        }
        """
        let chunk = try JSONDecoder().decode(V2TerminalOutputChunk.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(chunk.terminalId.value, "term-1")
        XCTAssertEqual(chunk.data, "aGVsbG8=")
    }

    func testV2TerminalOutputChunkEncoding() throws {
        let chunk = V2TerminalOutputChunk(
            terminalId: TerminalId(value: "term-2"),
            data: "d29ybGQ=",
            _meta: nil
        )

        let data = try JSONEncoder().encode(chunk)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["terminalId"] as? String, "term-2")
        XCTAssertEqual(json?["data"] as? String, "d29ybGQ=")
    }
}
