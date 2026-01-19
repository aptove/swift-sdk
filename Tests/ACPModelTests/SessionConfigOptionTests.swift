import XCTest
@testable import ACPModel

internal final class SessionConfigOptionTests: XCTestCase {
    // MARK: - SessionConfigId Tests

    func testSessionConfigIdEncoding() throws {
        let id = SessionConfigId(value: "theme")
        let data = try JSONEncoder().encode(id)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"theme\"")
    }

    func testSessionConfigIdDecoding() throws {
        let json = "\"language\""
        let data = json.data(using: .utf8)!
        let id = try JSONDecoder().decode(SessionConfigId.self, from: data)
        XCTAssertEqual(id.value, "language")
    }

    func testSessionConfigIdStringLiteral() {
        let id: SessionConfigId = "my-config"
        XCTAssertEqual(id.value, "my-config")
    }

    // MARK: - SessionConfigSelectOption Tests

    func testSelectOptionEncodeDecode() throws {
        let option = SessionConfigSelectOption(
            value: SessionConfigValueId(value: "dark"),
            name: "Dark Theme",
            description: "A dark color scheme",
            _meta: nil
        )

        let data = try JSONEncoder().encode(option)
        let decoded = try JSONDecoder().decode(SessionConfigSelectOption.self, from: data)

        XCTAssertEqual(decoded.value.value, "dark")
        XCTAssertEqual(decoded.name, "Dark Theme")
        XCTAssertEqual(decoded.description, "A dark color scheme")
    }

    func testSelectOptionMinimal() throws {
        let json = """
        {
            "value": "light",
            "name": "Light Theme"
        }
        """
        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(SessionConfigSelectOption.self, from: data)

        XCTAssertEqual(option.value.value, "light")
        XCTAssertEqual(option.name, "Light Theme")
        XCTAssertNil(option.description)
    }

    // MARK: - SessionConfigSelectGroup Tests

    func testSelectGroupEncodeDecode() throws {
        let group = SessionConfigSelectGroup(
            group: SessionConfigGroupId(value: "themes"),
            name: "Themes",
            options: [
                SessionConfigSelectOption(
                    value: SessionConfigValueId(value: "dark"),
                    name: "Dark"
                ),
                SessionConfigSelectOption(
                    value: SessionConfigValueId(value: "light"),
                    name: "Light"
                )
            ],
            _meta: nil
        )

        let data = try JSONEncoder().encode(group)
        let decoded = try JSONDecoder().decode(SessionConfigSelectGroup.self, from: data)

        XCTAssertEqual(decoded.group.value, "themes")
        XCTAssertEqual(decoded.name, "Themes")
        XCTAssertEqual(decoded.options.count, 2)
    }

    // MARK: - SessionConfigSelectOptions Tests

    func testSelectOptionsFlatEncodeDecode() throws {
        let options = SessionConfigSelectOptions.flat([
            SessionConfigSelectOption(
                value: SessionConfigValueId(value: "en"),
                name: "English"
            ),
            SessionConfigSelectOption(
                value: SessionConfigValueId(value: "es"),
                name: "Spanish"
            )
        ])

        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(SessionConfigSelectOptions.self, from: data)

        if case .flat(let decodedOptions) = decoded {
            XCTAssertEqual(decodedOptions.count, 2)
            XCTAssertEqual(decodedOptions[0].value.value, "en")
        } else {
            XCTFail("Expected flat options")
        }
    }

    func testSelectOptionsGroupedEncodeDecode() throws {
        let options = SessionConfigSelectOptions.grouped([
            SessionConfigSelectGroup(
                group: SessionConfigGroupId(value: "european"),
                name: "European",
                options: [
                    SessionConfigSelectOption(
                        value: SessionConfigValueId(value: "en"),
                        name: "English"
                    ),
                    SessionConfigSelectOption(
                        value: SessionConfigValueId(value: "de"),
                        name: "German"
                    )
                ]
            )
        ])

        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(SessionConfigSelectOptions.self, from: data)

        if case .grouped(let groups) = decoded {
            XCTAssertEqual(groups.count, 1)
            XCTAssertEqual(groups[0].group.value, "european")
            XCTAssertEqual(groups[0].options.count, 2)
        } else {
            XCTFail("Expected grouped options")
        }
    }

    func testSelectOptionsEmptyFlat() throws {
        let options = SessionConfigSelectOptions.flat([])
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(SessionConfigSelectOptions.self, from: data)

        if case .flat(let decodedOptions) = decoded {
            XCTAssertTrue(decodedOptions.isEmpty)
        } else {
            XCTFail("Expected empty flat options")
        }
    }

    // MARK: - SessionConfigOption (enum) Tests

    func testSessionConfigOptionSelectEncode() throws {
        let option = SessionConfigOption.select(SessionConfigOptionSelect(
            id: SessionConfigId(value: "theme"),
            name: "Theme",
            description: "Choose a theme",
            currentValue: SessionConfigValueId(value: "dark"),
            options: .flat([
                SessionConfigSelectOption(
                    value: SessionConfigValueId(value: "dark"),
                    name: "Dark"
                ),
                SessionConfigSelectOption(
                    value: SessionConfigValueId(value: "light"),
                    name: "Light"
                )
            ]),
            _meta: nil
        ))

        let data = try JSONEncoder().encode(option)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["type"] as? String, "select")
        XCTAssertEqual(json?["id"] as? String, "theme")
        XCTAssertEqual(json?["name"] as? String, "Theme")
    }

    func testSessionConfigOptionSelectDecode() throws {
        let json = """
        {
            "type": "select",
            "id": "language",
            "name": "Language",
            "currentValue": "en",
            "options": [
                {"value": "en", "name": "English"},
                {"value": "es", "name": "Spanish"}
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(SessionConfigOption.self, from: data)

        if case .select(let selectOption) = option {
            XCTAssertEqual(selectOption.id.value, "language")
            XCTAssertEqual(selectOption.name, "Language")
            XCTAssertEqual(selectOption.currentValue.value, "en")
            if case .flat(let options) = selectOption.options {
                XCTAssertEqual(options.count, 2)
            } else {
                XCTFail("Expected flat options")
            }
        } else {
            XCTFail("Expected select option")
        }
    }

    func testSessionConfigOptionRoundTrip() throws {
        let original = SessionConfigOption.select(SessionConfigOptionSelect(
            id: SessionConfigId(value: "model"),
            name: "Model",
            description: "Select the AI model",
            currentValue: SessionConfigValueId(value: "gpt-4"),
            options: .grouped([
                SessionConfigSelectGroup(
                    group: SessionConfigGroupId(value: "openai"),
                    name: "OpenAI",
                    options: [
                        SessionConfigSelectOption(
                            value: SessionConfigValueId(value: "gpt-4"),
                            name: "GPT-4"
                        ),
                        SessionConfigSelectOption(
                            value: SessionConfigValueId(value: "gpt-3.5"),
                            name: "GPT-3.5"
                        )
                    ]
                )
            ]),
            _meta: nil
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SessionConfigOption.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Hashable Tests

    func testSessionConfigOptionHashable() {
        let option1 = SessionConfigOption.select(SessionConfigOptionSelect(
            id: SessionConfigId(value: "test"),
            name: "Test",
            currentValue: SessionConfigValueId(value: "a"),
            options: .flat([])
        ))

        let option2 = SessionConfigOption.select(SessionConfigOptionSelect(
            id: SessionConfigId(value: "test"),
            name: "Test",
            currentValue: SessionConfigValueId(value: "a"),
            options: .flat([])
        ))

        XCTAssertEqual(option1, option2)

        var set = Set<SessionConfigOption>()
        set.insert(option1)
        set.insert(option2)
        XCTAssertEqual(set.count, 1)
    }
}
