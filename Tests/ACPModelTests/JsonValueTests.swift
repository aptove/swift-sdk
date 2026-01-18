import XCTest
@testable import ACPModel

internal final class JsonValueTests: XCTestCase {
    // MARK: - Basic Type Tests

    func testNullValue() {
        let value = JsonValue.null
        XCTAssertTrue(value.isNull)
        XCTAssertNil(value.boolValue)
        XCTAssertNil(value.intValue)
        XCTAssertNil(value.stringValue)
    }

    func testBoolValue() {
        let value = JsonValue.bool(true)
        XCTAssertEqual(value.boolValue, true)
        XCTAssertFalse(value.isNull)
    }

    func testIntValue() {
        let value = JsonValue.int(42)
        XCTAssertEqual(value.intValue, 42)
        XCTAssertEqual(value.doubleValue, 42.0)
    }

    func testDoubleValue() {
        let value = JsonValue.double(3.14)
        XCTAssertEqual(value.doubleValue, 3.14)
        XCTAssertNil(value.intValue)
    }

    func testStringValue() {
        let value = JsonValue.string("hello")
        XCTAssertEqual(value.stringValue, "hello")
    }

    func testArrayValue() {
        let value = JsonValue.array([.int(1), .int(2), .int(3)])
        XCTAssertEqual(value.arrayValue?.count, 3)
    }

    func testObjectValue() {
        let value = JsonValue.object(["key": .string("value")])
        XCTAssertEqual(value.objectValue?.keys.count, 1)
        XCTAssertEqual(value.objectValue?["key"]?.stringValue, "value")
    }

    // MARK: - Codable Tests

    func testNullCodable() throws {
        let original = JsonValue.null
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertTrue(decoded.isNull)
    }

    func testBoolCodable() throws {
        let original = JsonValue.bool(true)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.boolValue, true)
    }

    func testIntCodable() throws {
        let original = JsonValue.int(123)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.intValue, 123)
    }

    func testDoubleCodable() throws {
        let original = JsonValue.double(45.67)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.doubleValue, 45.67)
    }

    func testStringCodable() throws {
        let original = JsonValue.string("test")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.stringValue, "test")
    }

    func testArrayCodable() throws {
        let original = JsonValue.array([.int(1), .string("two"), .bool(true)])
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.arrayValue?.count, 3)
    }

    func testObjectCodable() throws {
        let original = JsonValue.object([
            "name": .string("Alice"),
            "age": .int(30),
            "active": .bool(true)
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.objectValue?["name"]?.stringValue, "Alice")
        XCTAssertEqual(decoded.objectValue?["age"]?.intValue, 30)
        XCTAssertEqual(decoded.objectValue?["active"]?.boolValue, true)
    }

    func testNestedStructure() throws {
        let original = JsonValue.object([
            "users": .array([
                .object(["name": .string("Alice"), "id": .int(1)]),
                .object(["name": .string("Bob"), "id": .int(2)])
            ]),
            "count": .int(2)
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonValue.self, from: encoded)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Literal Tests

    func testNilLiteral() {
        let value: JsonValue = nil
        XCTAssertTrue(value.isNull)
    }

    func testBoolLiteral() {
        let value: JsonValue = true
        XCTAssertEqual(value.boolValue, true)
    }

    func testIntLiteral() {
        let value: JsonValue = 42
        XCTAssertEqual(value.intValue, 42)
    }

    func testDoubleLiteral() {
        let value: JsonValue = 3.14
        XCTAssertEqual(value.doubleValue, 3.14)
    }

    func testStringLiteral() {
        let value: JsonValue = "hello"
        XCTAssertEqual(value.stringValue, "hello")
    }

    func testArrayLiteral() {
        let value: JsonValue = [1, 2, 3]
        XCTAssertEqual(value.arrayValue?.count, 3)
    }

    func testDictionaryLiteral() {
        let value: JsonValue = ["key": "value"]
        XCTAssertEqual(value.objectValue?["key"]?.stringValue, "value")
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let value1 = JsonValue.int(42)
        let value2 = JsonValue.int(42)
        let value3 = JsonValue.int(43)

        XCTAssertEqual(value1, value2)
        XCTAssertNotEqual(value1, value3)

        let set: Set<JsonValue> = [value1, value2, value3]
        XCTAssertEqual(set.count, 2)
    }
}
