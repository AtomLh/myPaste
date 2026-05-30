// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "myPaste",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "myPaste", targets: ["myPasteApp"]),
        .library(name: "myPasteCore", targets: ["myPasteCore"]),
        .library(name: "myPasteUI", targets: ["myPasteUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "myPasteApp",
            dependencies: [
                "myPasteCore",
                "myPasteUI",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/myPasteApp"
        ),
        .target(
            name: "myPasteCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/myPasteCore"
        ),
        .target(
            name: "myPasteUI",
            dependencies: ["myPasteCore"],
            path: "Sources/myPasteUI"
        ),
        .testTarget(
            name: "myPasteCoreTests",
            dependencies: ["myPasteCore"],
            path: "Tests/myPasteCoreTests"
        ),
    ]
)
