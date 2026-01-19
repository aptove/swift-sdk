import XCTest
@testable import ACPModel

internal final class PaginationTests: XCTestCase {
    // MARK: - Cursor Tests

    func testCursorEncoding() throws {
        let cursor = Cursor(value: "abc123")
        let data = try JSONEncoder().encode(cursor)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"abc123\"")
    }

    func testCursorDecoding() throws {
        let json = "\"xyz789\""
        let data = json.data(using: .utf8)!
        let cursor = try JSONDecoder().decode(Cursor.self, from: data)
        XCTAssertEqual(cursor.value, "xyz789")
    }

    func testCursorStringLiteral() {
        let cursor: Cursor = "test-cursor"
        XCTAssertEqual(cursor.value, "test-cursor")
    }

    func testCursorHashable() {
        let cursor1 = Cursor(value: "same")
        let cursor2 = Cursor(value: "same")
        let cursor3 = Cursor(value: "different")

        XCTAssertEqual(cursor1, cursor2)
        XCTAssertNotEqual(cursor1, cursor3)

        var set = Set<Cursor>()
        set.insert(cursor1)
        set.insert(cursor2)
        XCTAssertEqual(set.count, 1)
    }

    func testCursorDescription() {
        let cursor = Cursor(value: "my-cursor")
        XCTAssertEqual(cursor.description, "my-cursor")
    }

    // MARK: - Protocol Conformance Tests

    func testPaginatedRequestProtocol() {
        // Test that a request can conform to AcpPaginatedRequest
        struct TestRequest: AcpPaginatedRequest, Codable {
            let cursor: Cursor?
            let _meta: MetaField? // swiftlint:disable:this identifier_name
        }

        let request = TestRequest(cursor: "page2", _meta: nil)
        XCTAssertEqual(request.cursor?.value, "page2")
    }

    func testPaginatedResponseProtocol() {
        // Test that a response can conform to AcpPaginatedResponse
        struct TestResponse: AcpPaginatedResponse, Codable {
            typealias Item = String
            let items: [String]
            let nextCursor: Cursor?
            let _meta: MetaField? // swiftlint:disable:this identifier_name

            func getItemsBatch() -> [String] {
                items
            }
        }

        let response = TestResponse(items: ["a", "b"], nextCursor: "page3", _meta: nil)
        XCTAssertEqual(response.getItemsBatch(), ["a", "b"])
        XCTAssertEqual(response.nextCursor?.value, "page3")
    }

    func testPaginatedResponseLastPage() {
        struct TestResponse: AcpPaginatedResponse, Codable {
            typealias Item = Int
            let items: [Int]
            let nextCursor: Cursor?
            let _meta: MetaField? // swiftlint:disable:this identifier_name

            func getItemsBatch() -> [Int] {
                items
            }
        }

        let lastPage = TestResponse(items: [1, 2, 3], nextCursor: nil, _meta: nil)
        XCTAssertNil(lastPage.nextCursor)
        XCTAssertEqual(lastPage.getItemsBatch().count, 3)
    }
}
