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
        // Note: sample executables (SimpleAgentApp, V2SimpleAgentApp, etc.) are kept as
        // targets for local `swift run` use but are not listed as products so that package
        // index build systems don't attempt to compile them on unsupported platforms.
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
