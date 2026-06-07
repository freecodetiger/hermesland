// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HermesIslandMacOS",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "hermes-island-companion", targets: ["HermesIslandCompanion"]),
    ],
    dependencies: [
        .package(path: "../../packages/hermes-swift-sdk"),
    ],
    targets: [
        .target(
            name: "AppShell",
            path: "Sources/AppShell"
        ),
        .target(
            name: "UIState",
            path: "Sources/UIState",
            exclude: ["UIStateREADME.md"]
        ),
        .target(
            name: "HermesIslandCompanionCore",
            dependencies: [
                "AppShell",
                "UIState",
                .product(name: "HermesSwiftSDK", package: "hermes-swift-sdk"),
            ],
            path: "Sources/HermesIslandCompanionCore"
        ),
        .executableTarget(
            name: "HermesIslandCompanion",
            dependencies: ["HermesIslandCompanionCore"],
            path: "Sources/HermesIslandCompanion"
        ),
        .testTarget(
            name: "HermesIslandCompanionTests",
            dependencies: ["AppShell", "HermesIslandCompanionCore"],
            path: "Tests/HermesIslandCompanionTests"
        ),
    ]
)
