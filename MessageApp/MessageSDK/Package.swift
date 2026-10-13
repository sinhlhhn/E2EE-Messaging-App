// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MessageSDK",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MessageSDK",
            targets: ["MessageSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MessageSDK",
            dependencies: [
                .product(name: "SocketIO", package: "socket.io-client-swift"),
            ],
            swiftSettings: [
                .defaultIsolation(nil)   // nil = nonisolated, explicit opt-out of MainActor
            ]
        ),
        .testTarget(
            name: "MessageSDKTests",
            dependencies: ["MessageSDK"]
        ),
    ]
)
