import XCTest
@testable import ACPModel

final class RequestIdTests: XCTestCase {
    func testIntRequestId() {
        let requestId = RequestId.int(42)
        
        if case .int(let value) = requestId {
            XCTAssertEqual(value, 42)
        } else {
            XCTFail("Expected int case")
        }
    }
    
    func testStringRequestId() {
        let requestId = RequestId.string("request-123")
        
        if case .string(let value) = requestId {
            XCTAssertEqual(value, "request-123")
        } else {
            XCTFail("Expected string case")
        }
    }
    
    func testIntCodableRoundTrip() throws {
        let original = RequestId.int(99)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RequestId.self, from: encoded)
        
        XCTAssertEqual(original, decoded)
    }
    
    func testStringCodableRoundTrip() throws {
        let original = RequestId.string("abc-def")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RequestId.self, from: encoded)
        
        XCTAssertEqual(original, decoded)
    }
    
    func testIntEncodesAsNumber() throws {
        let requestId = RequestId.int(42)
        let encoded = try JSONEncoder().encode(requestId)
        let jsonString = String(data: encoded, encoding: .utf8)
        
        XCTAssertEqual(jsonString, "42")
    }
    
    func testStringEncodesAsString() throws {
        let requestId = RequestId.string("my-request")
        let encoded = try JSONEncoder().encode(requestId)
        let jsonString = String(data: encoded, encoding: .utf8)
        
        XCTAssertEqual(jsonString, "\"my-request\"")
    }
    
    func testIntLiteralInit() {
        let requestId: RequestId = 123
        XCTAssertEqual(requestId, .int(123))
    }
    
    func testStringLiteralInit() {
        let requestId: RequestId = "test-id"
        XCTAssertEqual(requestId, .string("test-id"))
    }
    
    func testHashable() {
        let id1 = RequestId.int(1)
        let id2 = RequestId.int(1)
        let id3 = RequestId.int(2)
        let id4 = RequestId.string("1")
        
        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)
        XCTAssertNotEqual(id1, id4) // Different types
        
        let set: Set<RequestId> = [id1, id2, id3, id4]
        XCTAssertEqual(set.count, 3)
    }
    
    func testDescription() {
        XCTAssertEqual(RequestId.int(42).description, "42")
        XCTAssertEqual(RequestId.string("abc").description, "abc")
    }
}
