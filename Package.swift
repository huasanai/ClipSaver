// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClipSaver",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipSaverApp", targets: ["ClipSaverApp"]),
        .library(name: "ClipSaverCore", targets: ["ClipSaverCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.9.4")
    ],
    targets: [
        .target(
            name: "ClipSaverCore"
        ),
        .executableTarget(
            name: "ClipSaverApp",
            dependencies: [
                "ClipSaverCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ]
        ),
        .testTarget(
            name: "ClipSaverCoreTests",
            dependencies: ["ClipSaverCore"]
        )
    ]
)
