// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

public let package = Package(
    name: "ACP",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        // acp-model: Pure data models for ACP protocol
        .library(
            name: "ACPModel",
            targets: ["ACPModel"]
        ),
        // acp: Core agent/client runtime with STDIO transport
        .library(
            name: "ACP",
            targets: ["ACP"]
        ),
        // acp-http: Optional HTTP/WebSocket transports
        .library(
            name: "ACPHTTP",
            targets: ["ACPHTTP"]
        ),
        // Sample: SimpleAgentApp (v1 in-process agent + client demo)
        .executable(
            name: "SimpleAgentApp",
            targets: ["SimpleAgentApp"]
        ),
        // Sample: V2SimpleAgentApp (v2 in-process agent + client demo)
        .executable(
            name: "V2SimpleAgentApp",
            targets: ["V2SimpleAgentApp"]
        ),
        // Sample: V2NegotiationApp (v2 in-process with protocol negotiation)
        .executable(
            name: "V2NegotiationApp",
            targets: ["V2NegotiationApp"]
        ),
        // Sample: AuthStatusApp (auth/status for v1 and v2 agents)
        .executable(
            name: "AuthStatusApp",
            targets: ["AuthStatusApp"]
        ),
        // Sample: GeminiClientApp (interactive client connecting to external agent)
        .executable(
            name: "GeminiClientApp",
            targets: ["GeminiClientApp"]
        )
    ],
    dependencies: [
        // Logging framework
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        // Immutable collections
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0")
    ],
    targets: [
        // MARK: - acp-model Module
        .target(
            name: "ACPModel",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/ACPModel"
        ),
        .testTarget(
            name: "ACPModelTests",
            dependencies: ["ACPModel"],
            path: "Tests/ACPModelTests"
        ),

        // MARK: - acp Core Module
        .target(
            name: "ACP",
            dependencies: [
                "ACPModel",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/ACP"
        ),
        .testTarget(
            name: "ACPTests",
            dependencies: ["ACP"],
            path: "Tests/ACPTests"
        ),

        // MARK: - acp-http Module
        .target(
            name: "ACPHTTP",
            dependencies: [
                "ACP",
                "ACPModel",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/ACPHTTP"
        ),
        .testTarget(
            name: "ACPHTTPTests",
            dependencies: ["ACPHTTP"],
            path: "Tests/ACPHTTPTests"
        ),

        // MARK: - Sample Applications
        .executableTarget(
            name: "SimpleAgentApp",
            dependencies: [
                "ACP",
                "ACPModel"
            ],
            path: "Samples/SimpleAgentApp"
        ),
        .executableTarget(
            name: "V2SimpleAgentApp",
            dependencies: [
                "ACP",
                "ACPModel"
            ],
            path: "Samples/V2SimpleAgentApp"
        ),
        .executableTarget(
            name: "V2NegotiationApp",
            dependencies: [
                "ACP",
                "ACPModel"
            ],
            path: "Samples/V2NegotiationApp"
        ),
        .executableTarget(
            name: "AuthStatusApp",
            dependencies: [
                "ACP",
                "ACPModel"
            ],
            path: "Samples/AuthStatusApp"
        ),
        .executableTarget(
            name: "GeminiClientApp",
            dependencies: [
                "ACP",
                "ACPModel"
            ],
            path: "Samples/GeminiClientApp"
        )
    ]
)
