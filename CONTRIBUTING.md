# Contributing to ACP Swift SDK

Thank you for your interest in contributing to the ACP Swift SDK! This document provides guidelines and information for contributors.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Swift version and platform (iOS, macOS, etc.)
- Any relevant code samples or error messages

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- A clear and descriptive title
- Detailed description of the proposed functionality
- Explain why this enhancement would be useful
- List any alternative solutions you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Add tests for your changes
5. Ensure all tests pass (`swift test`)
6. Run linting (`swiftlint lint`)
7. Format your code (`swift-format format -i -r Sources Tests`)
8. Commit your changes (`git commit -am 'Add some feature'`)
9. Push to the branch (`git push origin feature/my-feature`)
10. Open a Pull Request

## Development Process

### Setting Up Development Environment

1. **Clone the repository:**
```bash
git clone https://github.com/agentclientprotocol/acp-swift-sdk.git
cd acp-swift-sdk
```

2. **Install development tools:**
```bash
# Install SwiftLint
brew install swiftlint

# Install swift-format
brew install swift-format
```

3. **Build the project:**
```bash
swift build
```

4. **Run tests:**
```bash
swift test
```

### Code Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and enforce style with SwiftLint and swift-format.

**Key conventions:**
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use clear, descriptive names
- Prefer protocol-oriented design
- Use async/await for asynchronous operations
- Add documentation comments for all public APIs

**Example:**
```swift
/// Sends a prompt to the agent and returns streaming updates.
///
/// - Parameters:
///   - sessionId: The session identifier
///   - request: The prompt request
/// - Returns: An async stream of session updates
/// - Throws: `AcpError` if the request fails
public func sendPrompt(
    sessionId: SessionId,
    request: PromptRequest
) async throws -> AsyncStream<SessionUpdate> {
    // Implementation
}
```

### Testing

- Write tests for all new functionality
- Maintain test coverage above 80%
- Use descriptive test names
- Follow the Arrange-Act-Assert pattern

**Example:**
```swift
func testSessionIdEncodesAsString() throws {
    // Arrange
    let sessionId = SessionId()
    
    // Act
    let encoded = try JSONEncoder().encode(sessionId)
    let decoded = try JSONDecoder().decode(SessionId.self, from: encoded)
    
    // Assert
    XCTAssertEqual(sessionId, decoded)
}
```

### Documentation

- Document all public APIs with DocC-style comments
- Include code examples where helpful
- Document error conditions
- Keep documentation up to date with code changes

### Branching Strategy

- `main` - Stable releases only
- `develop` - Integration branch for ongoing development
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches
- `docs/*` - Documentation updates

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or changes
- `refactor:` Code refactoring
- `perf:` Performance improvements
- `chore:` Build process or auxiliary tool changes

**Examples:**
```
feat: add WebSocket transport implementation
fix: handle null response in JSON-RPC decoding
docs: update README with installation instructions
test: add tests for SessionId encoding
```

## Project Structure

```
acp-swift-sdk/
├── Sources/
│   ├── ACPModel/       # Pure data models
│   ├── ACP/            # Core runtime
│   └── ACPHTTP/        # HTTP/WebSocket transports
├── Tests/
│   ├── ACPModelTests/  # Model tests
│   ├── ACPTests/       # Runtime tests
│   └── ACPHTTPTests/   # Transport tests
├── .github/
│   └── workflows/      # CI/CD configuration
├── Package.swift       # Swift Package Manager manifest
├── .swiftlint.yml     # SwiftLint configuration
└── .swift-format      # swift-format configuration
```

## Review Process

1. All PRs require at least one approval
2. CI checks must pass (build, tests, linting)
3. Code coverage should not decrease
4. Documentation must be updated if needed
5. CHANGELOG.md should be updated for user-facing changes

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion in GitHub Discussions
- Contact the maintainers

Thank you for contributing! 🎉
