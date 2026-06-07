// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HermesSwiftSDK",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "HermesSwiftSDK",
            targets: ["HermesSwiftSDK"]
        ),
    ],
    targets: [
        .target(name: "HermesSwiftSDK"),
        .testTarget(
            name: "HermesSwiftSDKTests",
            dependencies: ["HermesSwiftSDK"]
        ),
    ]
)
