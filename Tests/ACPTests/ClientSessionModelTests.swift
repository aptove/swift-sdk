import XCTest
@testable import ACP
@testable import ACPModel
import Foundation

/// Tests for ClientSession model and config option APIs.
internal final class ClientSessionModelTests: XCTestCase {

    // MARK: - Mock Session Implementation

    /// A mock implementation of ClientSession for testing the new APIs
    private final class MockSession: ClientSession, @unchecked Sendable {
        let sessionId: SessionId
        let parameters: SessionCreationParameters

        // Mode support
        var modesSupported = false
        var availableModes: [SessionMode] = []
        private var _currentModeId = SessionModeId(value: "default")

        // Model support (unstable)
        var modelsSupported = false
        var availableModels: [ModelInfo] = []
        private var _currentModelId = ModelId(value: "default-model")

        // Config options support (unstable)
        var configOptionsSupported = false
        private var _configOptions: [SessionConfigOption] = []

        // Track method calls for verification
        struct SetConfigOptionCall {
            let configId: SessionConfigId
            let value: SessionConfigValueId
            let meta: MetaField?
        }
        var setModeCalls: [(SessionModeId, MetaField?)] = []
        var setModelCalls: [(ModelId, MetaField?)] = []
        var setConfigOptionCalls: [SetConfigOptionCall] = []

        init(sessionId: String = "test-session", cwd: String = "/test") {
            self.sessionId = SessionId(value: sessionId)
            self.parameters = SessionCreationParameters(cwd: cwd)
        }

        var currentModeId: SessionModeId {
            get async throws {
                guard modesSupported else {
                    throw ClientError.notImplemented("Modes not supported")
                }
                return _currentModeId
            }
        }

        var currentModelId: ModelId {
            get async throws {
                guard modelsSupported else {
                    throw ClientError.notImplemented("Models not supported")
                }
                return _currentModelId
            }
        }

        var configOptions: [SessionConfigOption] {
            get async throws {
                guard configOptionsSupported else {
                    throw ClientError.notImplemented("Config options not supported")
                }
                return _configOptions
            }
        }

        func prompt(content: [ContentBlock], meta: MetaField?) -> AsyncStream<Event> {
            AsyncStream { _ in }
        }

        func cancel() async throws {
            // No-op for tests
        }

        func setMode(_ modeId: SessionModeId, meta: MetaField?) async throws -> SetSessionModeResponse {
            setModeCalls.append((modeId, meta))
            _currentModeId = modeId
            return SetSessionModeResponse()
        }

        func setModel(_ modelId: ModelId, meta: MetaField?) async throws -> SetSessionModelResponse {
            guard modelsSupported else {
                throw ClientError.notImplemented("Models not supported")
            }
            setModelCalls.append((modelId, meta))
            _currentModelId = modelId
            return SetSessionModelResponse()
        }

        func setConfigOption(
            _ configId: SessionConfigId,
            value: SessionConfigValueId,
            meta: MetaField?
        ) async throws -> SetSessionConfigOptionResponse {
            guard configOptionsSupported else {
                throw ClientError.notImplemented("Config options not supported")
            }
            setConfigOptionCalls.append(SetConfigOptionCall(configId: configId, value: value, meta: meta))
            return SetSessionConfigOptionResponse(configOptions: _configOptions)
        }

        // Helper to configure mock
        func configureModels(supported: Bool, models: [ModelInfo], current: ModelId) {
            modelsSupported = supported
            availableModels = models
            _currentModelId = current
        }

        func configureConfigOptions(supported: Bool, options: [SessionConfigOption]) {
            configOptionsSupported = supported
            _configOptions = options
        }
    }

    // MARK: - Model Selection Tests

    func testModelsNotSupported() async throws {
        let session = MockSession()
        session.configureModels(supported: false, models: [], current: "none")

        XCTAssertFalse(session.modelsSupported)
        XCTAssertTrue(session.availableModels.isEmpty)

        // Accessing currentModelId should throw
        do {
            _ = try await session.currentModelId
            XCTFail("Expected error when models not supported")
        } catch {
            // Expected
        }
    }

    func testModelsSupported() async throws {
        let session = MockSession()
        let models = [
            ModelInfo(modelId: "gpt-4", name: "GPT-4", description: "OpenAI GPT-4"),
            ModelInfo(modelId: "claude-3", name: "Claude 3", description: "Anthropic Claude 3")
        ]
        session.configureModels(supported: true, models: models, current: "gpt-4")

        XCTAssertTrue(session.modelsSupported)
        XCTAssertEqual(session.availableModels.count, 2)

        let currentModel = try await session.currentModelId
        XCTAssertEqual(currentModel.value, "gpt-4")
    }

    func testSetModel() async throws {
        let session = MockSession()
        let models = [
            ModelInfo(modelId: "gpt-4", name: "GPT-4"),
            ModelInfo(modelId: "claude-3", name: "Claude 3")
        ]
        session.configureModels(supported: true, models: models, current: "gpt-4")

        // Set model with metadata
        let meta = MetaField(additionalData: ["key": .string("value")])
        _ = try await session.setModel(ModelId(value: "claude-3"), meta: meta)

        XCTAssertEqual(session.setModelCalls.count, 1)
        XCTAssertEqual(session.setModelCalls[0].0.value, "claude-3")
        XCTAssertNotNil(session.setModelCalls[0].1)

        // Verify current model changed
        let currentModel = try await session.currentModelId
        XCTAssertEqual(currentModel.value, "claude-3")
    }

    func testSetModelConvenienceMethod() async throws {
        let session = MockSession()
        session.configureModels(supported: true, models: [], current: "gpt-4")

        // Use convenience method without metadata
        _ = try await session.setModel(ModelId(value: "new-model"))

        XCTAssertEqual(session.setModelCalls.count, 1)
        XCTAssertEqual(session.setModelCalls[0].0.value, "new-model")
        XCTAssertNil(session.setModelCalls[0].1)
    }

    func testSetModelWhenNotSupported() async throws {
        let session = MockSession()
        session.configureModels(supported: false, models: [], current: "none")

        do {
            _ = try await session.setModel(ModelId(value: "any"))
            XCTFail("Expected error when models not supported")
        } catch {
            // Expected
        }
    }

    // MARK: - Configuration Options Tests

    func testConfigOptionsNotSupported() async throws {
        let session = MockSession()
        session.configureConfigOptions(supported: false, options: [])

        XCTAssertFalse(session.configOptionsSupported)

        // Accessing configOptions should throw
        do {
            _ = try await session.configOptions
            XCTFail("Expected error when config options not supported")
        } catch {
            // Expected
        }
    }

    func testConfigOptionsSupported() async throws {
        let session = MockSession()
        let option = SessionConfigOption.select(
            SessionConfigOptionSelect(
                id: SessionConfigId(value: "temperature"),
                name: "Temperature",
                description: "Controls randomness",
                currentValue: SessionConfigValueId(value: "medium"),
                options: .flat([
                    SessionConfigSelectOption(
                        value: SessionConfigValueId(value: "low"),
                        name: "Low"
                    ),
                    SessionConfigSelectOption(
                        value: SessionConfigValueId(value: "medium"),
                        name: "Medium"
                    ),
                    SessionConfigSelectOption(
                        value: SessionConfigValueId(value: "high"),
                        name: "High"
                    )
                ])
            )
        )
        session.configureConfigOptions(supported: true, options: [option])

        XCTAssertTrue(session.configOptionsSupported)

        let options = try await session.configOptions
        XCTAssertEqual(options.count, 1)
    }

    func testSetConfigOption() async throws {
        let session = MockSession()
        session.configureConfigOptions(supported: true, options: [])

        let configId = SessionConfigId(value: "temperature")
        let value = SessionConfigValueId(value: "high")
        let meta = MetaField(additionalData: ["reason": .string("user preference")])

        _ = try await session.setConfigOption(configId, value: value, meta: meta)

        XCTAssertEqual(session.setConfigOptionCalls.count, 1)
        XCTAssertEqual(session.setConfigOptionCalls[0].configId.value, "temperature")
        XCTAssertEqual(session.setConfigOptionCalls[0].value.value, "high")
        XCTAssertNotNil(session.setConfigOptionCalls[0].meta)
    }

    func testSetConfigOptionConvenienceMethod() async throws {
        let session = MockSession()
        session.configureConfigOptions(supported: true, options: [])

        let configId = SessionConfigId(value: "output-format")
        let value = SessionConfigValueId(value: "json")

        // Use convenience method without metadata
        _ = try await session.setConfigOption(configId, value: value)

        XCTAssertEqual(session.setConfigOptionCalls.count, 1)
        XCTAssertEqual(session.setConfigOptionCalls[0].configId.value, "output-format")
        XCTAssertEqual(session.setConfigOptionCalls[0].value.value, "json")
        XCTAssertNil(session.setConfigOptionCalls[0].meta)
    }

    func testSetConfigOptionWhenNotSupported() async throws {
        let session = MockSession()
        session.configureConfigOptions(supported: false, options: [])

        do {
            _ = try await session.setConfigOption(
                SessionConfigId(value: "any"),
                value: SessionConfigValueId(value: "any")
            )
            XCTFail("Expected error when config options not supported")
        } catch {
            // Expected
        }
    }

    // MARK: - Combined Feature Tests

    func testSessionWithAllFeaturesEnabled() async throws {
        let session = MockSession()

        // Configure modes
        session.modesSupported = true
        session.availableModes = [
            SessionMode(id: SessionModeId(value: "chat"), name: "Chat Mode"),
            SessionMode(id: SessionModeId(value: "code"), name: "Code Mode")
        ]

        // Configure models
        session.configureModels(
            supported: true,
            models: [ModelInfo(modelId: "gpt-4", name: "GPT-4")],
            current: "gpt-4"
        )

        // Configure config options
        session.configureConfigOptions(supported: true, options: [])

        // All features should be available
        XCTAssertTrue(session.modesSupported)
        XCTAssertTrue(session.modelsSupported)
        XCTAssertTrue(session.configOptionsSupported)

        XCTAssertEqual(session.availableModes.count, 2)
        XCTAssertEqual(session.availableModels.count, 1)

        _ = try await session.currentModeId
        _ = try await session.currentModelId
        _ = try await session.configOptions
    }
}
